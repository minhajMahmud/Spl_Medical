import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'dart:async'; // added for fire-and-forget scheduling

//import 'auth_endpoint.dart';
import '../generated/protocol.dart';

/// AdminEndpoints: server-side methods used by the admin UI to manage users,
/// inventory, rosters, audit logs and notifications.
class AdminEndpoints extends Endpoint {
  /// Helper: map a DB row to a serializable map for the client.
  Map<String, dynamic> _rowToUserMap(Map<String, dynamic> row) {
    String decode(dynamic v) {
      if (v == null) return '';
      if (v is List<int>) return String.fromCharCodes(v);
      return v.toString();
    }

    return {
      'userId': decode(row['user_id']),
      'name': decode(row['name']),
      'email': decode(row['email']),
      'role': decode(row['role']).toUpperCase(),
      'phone': decode(row['phone']),
      // Normalize profile picture column (nullable)
      'profilePictureUrl': decode(row['profile_picture_url']),
      'active': row['is_active'] == true,
    };
  }

  /// List users filtered by role. Use role = 'ALL' to fetch all users.
  Future<List<UserListItem>> listUsersByRole(
      Session session, String role, int limit) async {
    try {
      final isAll = role.trim().toUpperCase() == 'ALL' || role.trim().isEmpty;
      final sql = isAll
          ? '''SELECT user_id, name, email, role::text, phone, profile_picture_url, is_active FROM users ORDER BY name LIMIT @lim'''
          : '''SELECT user_id, name, email, role::text, phone, profile_picture_url, is_active FROM users WHERE (lower(role::text) LIKE @role || '%' OR @role LIKE lower(role::text) || '%') ORDER BY name LIMIT @lim''';

      final params = isAll
          ? QueryParameters.named({'lim': limit})
          : QueryParameters.named({'role': role.toLowerCase(), 'lim': limit});

      final result = await session.db.unsafeQuery(sql, parameters: params);
      final list = <UserListItem>[];
      for (final r in result) {
        final row = r.toColumnMap();
        final decoded = _rowToUserMap(row);
        list.add(UserListItem(
          userId: decoded['userId'] ?? '',
          name: decoded['name'] ?? '',
          email: decoded['email'] ?? '',
          role: decoded['role'] ?? '',
          phone: decoded['phone'] ?? '',
          profilePictureUrl: decoded['profilePictureUrl'] ?? '',
          active: decoded['active'] == true,
        ));
      }
      return list;
    } catch (e, st) {
      session.log('listUsersByRole failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Toggle user's active flag. Returns true on success.
  Future<bool> toggleUserActive(Session session, String userId) async {
    try {
      await session.db.unsafeExecute(
        'UPDATE users SET is_active = NOT is_active WHERE user_id = @uid',
        parameters: QueryParameters.named({'uid': userId}),
      );
      return true;
    } catch (e, st) {
      session.log('UserActive failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// Create a new user record. Expects passwordHash to already be hashed by the caller.
  /// Returns 'OK' on success or an error message string.
  Future<String> createUser(Session session, String userId, String name,
      String email, String passwordHash, String role, String? phone) async {
    try {
      await session.db.unsafeExecute('BEGIN');

      await session.db.unsafeExecute(
        '''
        INSERT INTO users (user_id, name, email, password_hash, phone, role, is_active)
        VALUES (@id, @name, @email, @pass, @phone, @role::user_role, TRUE)
        ''',
        parameters: QueryParameters.named({
          'id': userId,
          'name': name,
          'email': email,
          'pass': passwordHash,
          'phone': phone,
          'role': role,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return 'OK';
    } on DatabaseQueryException catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('createUser DB error: $e', level: LogLevel.error);
      // Try to surface a helpful message if duplicate key
      final msg = e.message.toLowerCase();
      if (msg.contains('duplicate')) {
        return 'User already exists';
      }
      return 'Database error';
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('createUser failed: $e\n$st', level: LogLevel.error);
      return 'Internal error';
    }
  }

  /// Create user by hashing the provided raw password server-side.
  Future<String> createUserWithPassword(
      Session session,
      String userId,
      String name,
      String email,
      String password,
      String role,
      String? phone) async {
    try {
      final hashed = sha256.convert(utf8.encode(password)).toString();
      final res =
          await createUser(session, userId, name, email, hashed, role, phone);
      if (res == 'OK') {
        // Send welcome email for these roles when created via admin UI.
        try {
          final allowed = <String>{'ADMIN', 'DOCTOR', 'DISPENSER', 'LABSTAFF'};
          final r = role.toUpperCase();
          if (allowed.contains(r)) {
            // Fire-and-forget so user creation is not blocked by email sending.
            Future.microtask(() async {
              try {
                // final auth = AuthEndpoint();
                // await auth.sendWelcomeEmailViaResend(session, email, name);
              } catch (e, st) {
                session.log('Failed to send welcome email (async): $e\n$st',
                    level: LogLevel.warning);
              }
            });
          }
        } catch (e) {
          session.log('Failed to schedule welcome email: $e',
              level: LogLevel.warning);
        }
      }
      return res;
    } catch (e, st) {
      session.log('createUserWithPassword failed: $e\n$st',
          level: LogLevel.error);
      return 'Internal error';
    }
  }

  // ------------------ Inventory / Medicines ------------------
  /// Ensure medicines and medicine_batches tables exist.
  Future<bool> _initMedicineTables(Session session) async {
    try {
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS medicines (
          medicine_id SERIAL PRIMARY KEY,
          name VARCHAR(100) NOT NULL UNIQUE,
          minimum_stock INTEGER DEFAULT 10
        )
      ''');

      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS medicine_batches (
          batch_id TEXT PRIMARY KEY,
          medicine_id INTEGER REFERENCES medicines(medicine_id) ON DELETE CASCADE,
          stock INTEGER DEFAULT 0,
          expiry DATE
        )
      ''');

      return true;
    } catch (e, st) {
      session.log('initMedicineTables failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// List all medicines with aggregated stock and earliest expiry.
  Future<List<Map<String, dynamic>>> listMedicines(Session session) async {
    try {
      await _initMedicineTables(session);

      final result = await session.db.unsafeQuery('''
        SELECT m.medicine_id, m.name, m.minimum_stock,
               COALESCE(SUM(b.stock), 0) AS total_stock,
               MIN(b.expiry) AS earliest_expiry
        FROM medicines m
        LEFT JOIN medicine_batches b ON b.medicine_id = m.medicine_id
        GROUP BY m.medicine_id, m.name, m.minimum_stock
        ORDER BY m.name
      ''');

      final list = <Map<String, dynamic>>[];
      for (final r in result) {
        final row = r.toColumnMap();
        list.add({
          'medicineId': row['medicine_id'],
          'name': row['name'],
          'minimumStock': row['minimum_stock'],
          'totalStock': row['total_stock'],
          'earliestExpiry': row['earliest_expiry']?.toString(),
        });
      }
      return list;
    } catch (e, st) {
      session.log('listMedicines failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Add a medicine and return the inserted id or -1 on error.
  Future<int> addMedicine(
      Session session, String name, int minimumStock) async {
    try {
      await _initMedicineTables(session);
      final result = await session.db.unsafeQuery('''
        INSERT INTO medicines (name, minimum_stock)
        VALUES (@name, @min)
        RETURNING medicine_id
      ''',
          parameters:
              QueryParameters.named({'name': name, 'min': minimumStock}));

      if (result.isEmpty) return -1;
      final row = result.first.toColumnMap();
      return row['medicine_id'];
    } catch (e, st) {
      session.log('addMedicine failed: $e\n$st', level: LogLevel.error);
      return -1;
    }
  }

  /// Add a batch for a medicine.
  Future<bool> addMedicineBatch(Session session, int medicineId, String batchId,
      int stock, DateTime? expiry) async {
    try {
      await _initMedicineTables(session);
      await session.db.unsafeExecute('''
        INSERT INTO medicine_batches (batch_id, medicine_id, stock, expiry)
        VALUES (@bid, @mid, @stock, @exp)
        ON CONFLICT (batch_id) DO UPDATE SET stock = medicine_batches.stock + EXCLUDED.stock, expiry = EXCLUDED.expiry
      ''',
          parameters: QueryParameters.named({
            'bid': batchId,
            'mid': medicineId,
            'stock': stock,
            'exp': expiry
          }));
      return true;
    } catch (e, st) {
      session.log('addMedicineBatch failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// Get batches for a medicine.
  Future<List<Map<String, dynamic>>> getMedicineBatches(
      Session session, int medicineId) async {
    try {
      await _initMedicineTables(session);
      final result = await session.db.unsafeQuery('''
        SELECT batch_id, stock, expiry FROM medicine_batches WHERE medicine_id = @mid ORDER BY expiry
      ''', parameters: QueryParameters.named({'mid': medicineId}));

      final list = <Map<String, dynamic>>[];
      for (final r in result) {
        final row = r.toColumnMap();
        list.add({
          'batchId': row['batch_id'],
          'stock': row['stock'],
          'expiry': row['expiry']?.toString(),
        });
      }
      return list;
    } catch (e, st) {
      session.log('getMedicineBatches failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Get low stock medicines (where total stock < minimum_stock)
  Future<List<Map<String, dynamic>>> getLowStockItems(Session session) async {
    try {
      await _initMedicineTables(session);
      final result = await session.db.unsafeQuery('''
        SELECT m.medicine_id, m.name, m.minimum_stock, COALESCE(SUM(b.stock),0) AS total_stock
        FROM medicines m
        LEFT JOIN medicine_batches b ON b.medicine_id = m.medicine_id
        GROUP BY m.medicine_id, m.name, m.minimum_stock
        HAVING COALESCE(SUM(b.stock),0) < m.minimum_stock
        ORDER BY m.name
      ''');

      final list = <Map<String, dynamic>>[];
      for (final r in result) {
        final row = r.toColumnMap();
        list.add({
          'medicineId': row['medicine_id'],
          'name': row['name'],
          'minimumStock': row['minimum_stock'],
          'totalStock': row['total_stock'],
        });
      }
      return list;
    } catch (e, st) {
      session.log('getLowStockItems failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }
//rosters

  // ------------------ Init Rosters Table ------------------
  Future<bool> _initRostersTable(Session session) async {
    try {
      // 1️⃣ Create ENUMS safely
      // Postgres (pre-13) doesn’t support CREATE TYPE IF NOT EXISTS for enum, use DO block guard
      await session.db.unsafeExecute(r'''
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'roster_status') THEN
            CREATE TYPE roster_status AS ENUM ('SCHEDULED', 'CONFIRMED', 'CANCELLED');
          END IF;
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shift_type') THEN
            CREATE TYPE shift_type AS ENUM ('MORNING', 'AFTERNOON', 'NIGHT');
          END IF;
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_status') THEN
            CREATE TYPE request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
          END IF;
        END
        $$;
      ''');

      // 2️⃣ Create rosters table
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS rosters (
          roster_id VARCHAR(20) PRIMARY KEY,
          staff_id VARCHAR(20) REFERENCES staff_profiles(user_id),
          shift_type shift_type,
          shift_date DATE,
          shift_time_range VARCHAR(50),
          status roster_status DEFAULT 'SCHEDULED',
          approved_by VARCHAR(20) REFERENCES staff_profiles(user_id)
        );
      ''');

      // 3️⃣ Create shift change requests table
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS shift_change_requests (
          request_id SERIAL PRIMARY KEY,
          roster_id VARCHAR(20) REFERENCES rosters(roster_id),
          staff_id VARCHAR(20) REFERENCES staff_profiles(user_id),
          reason TEXT,
          request_date TIMESTAMP DEFAULT NOW(),
          status request_status DEFAULT 'PENDING'
        );
      ''');

      return true;
    } catch (e, st) {
      session.log(
        'initRostersTable failed: $e\n$st',
        level: LogLevel.error,
      );
      return false;
    }
  }

  // ------------------ Get Rosters ------------------
  Future<List<Map<String, dynamic>>> getRosters(
    Session session, {
    String? staffId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      await _initRostersTable(session);

      final buffer = StringBuffer('''
        SELECT
          roster_id,
          staff_id,
          shift_type::text AS shift_type,
          shift_date::text AS shift_date,
          shift_time_range,
          status::text AS status,
          approved_by
        FROM rosters
      ''');

      final where = <String>[];
      final params = <String, dynamic>{};

      if (staffId != null && staffId.isNotEmpty) {
        where.add('staff_id = @staff');
        params['staff'] = staffId;
      }
      if (fromDate != null) {
        where.add('shift_date >= @fromd');
        params['fromd'] = fromDate;
      }
      if (toDate != null) {
        where.add('shift_date <= @tod');
        params['tod'] = toDate;
      }

      if (where.isNotEmpty) {
        buffer.write(' WHERE ${where.join(' AND ')}');
      }

      buffer.write(' ORDER BY shift_date');

      final result = await session.db.unsafeQuery(
        buffer.toString(),
        parameters: QueryParameters.named(params),
      );

      return result.map((r) {
        final row = r.toColumnMap();
        return <String, dynamic>{
          'rosterId': row['roster_id']?.toString(),
          'staffId': row['staff_id']?.toString(),
          'shiftType': row['shift_type']?.toString(),
          'shiftDate': row['shift_date']?.toString(),
          'timeRange': row['shift_time_range']?.toString(),
          'status': row['status']?.toString(),
          'approvedBy': row['approved_by']?.toString(),
        };
      }).toList();
    } catch (e, st) {
      session.log('getRosters failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  // ------------------ Save / Update Roster ------------------
  Future<bool> saveRoster(
    Session session, {
    required String rosterId,
    required String staffId,
    required String shiftType,
    required DateTime shiftDate,
    required String timeRange,
    required String status,
    String? approvedBy,
  }) async {
    try {
      await _initRostersTable(session);

      await session.db.unsafeExecute('''
        INSERT INTO rosters (
          roster_id,
          staff_id,
          shift_type,
          shift_date,
          shift_time_range,
          status,
          approved_by
        )
        VALUES (
          @rid,
          @sid,
          @stype::shift_type,
          @sdate,
          @tr,
          @status::roster_status,
          @app
        )
        ON CONFLICT (roster_id) DO UPDATE SET
          staff_id = EXCLUDED.staff_id,
          shift_type = EXCLUDED.shift_type,
          shift_date = EXCLUDED.shift_date,
          shift_time_range = EXCLUDED.shift_time_range,
          status = EXCLUDED.status,
          approved_by = EXCLUDED.approved_by
      ''',
          parameters: QueryParameters.named({
            'rid': rosterId,
            'sid': staffId,
            'stype': shiftType,
            'sdate': shiftDate,
            'tr': timeRange,
            'status': status,
            'app': approvedBy,
          }));

      return true;
    } catch (e, st) {
      session.log('saveRoster failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  // ------------------ Shift Change Requests ------------------

  /// Submit a new shift change request
  Future<Map<String, dynamic>> submitChangeRequest(
    Session session, {
    required String rosterId,
    required String staffId,
    required String reason,
  }) async {
    try {
      await _initRostersTable(session);

      // Validate that the roster exists and belongs to this staff
      final rosterCheck = await session.db.unsafeQuery('''
        SELECT staff_id, status::text FROM rosters WHERE roster_id = @rid
      ''', parameters: QueryParameters.named({'rid': rosterId}));

      if (rosterCheck.isEmpty) {
        return {'success': false, 'message': 'Roster not found'};
      }

      final rosterRow = rosterCheck.first.toColumnMap();
      if (rosterRow['staff_id'] != staffId) {
        return {
          'success': false,
          'message': 'Unauthorized: roster does not belong to you'
        };
      }

      // Check if there's already a pending request for this roster
      final existingRequest = await session.db.unsafeQuery('''
        SELECT request_id FROM shift_change_requests 
        WHERE roster_id = @rid AND status = 'PENDING'
      ''', parameters: QueryParameters.named({'rid': rosterId}));

      if (existingRequest.isNotEmpty) {
        return {
          'success': false,
          'message': 'A pending request already exists for this shift'
        };
      }

      // Insert the change request
      final result = await session.db.unsafeQuery('''
        INSERT INTO shift_change_requests (roster_id, staff_id, reason)
        VALUES (@rid, @sid, @reason)
        RETURNING request_id
      ''',
          parameters: QueryParameters.named({
            'rid': rosterId,
            'sid': staffId,
            'reason': reason,
          }));

      if (result.isEmpty) {
        return {'success': false, 'message': 'Failed to create request'};
      }

      final requestId = result.first.toColumnMap()['request_id'];
      return {
        'success': true,
        'message': 'Request submitted successfully',
        'requestId': requestId.toString(),
      };
    } catch (e, st) {
      session.log('submitChangeRequest failed: $e\n$st', level: LogLevel.error);
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get all change requests for a staff member
  Future<List<Map<String, dynamic>>> getMyChangeRequests(
    Session session,
    String staffId,
  ) async {
    try {
      await _initRostersTable(session);

      final result = await session.db.unsafeQuery('''
        SELECT 
          scr.request_id,
          scr.roster_id,
          scr.reason,
          scr.request_date::text,
          scr.status::text,
          r.shift_type::text,
          r.shift_date::text,
          r.shift_time_range
        FROM shift_change_requests scr
        JOIN rosters r ON r.roster_id = scr.roster_id
        WHERE scr.staff_id = @sid
        ORDER BY scr.request_date DESC
      ''', parameters: QueryParameters.named({'sid': staffId}));

      return result.map((r) {
        final row = r.toColumnMap();
        return <String, dynamic>{
          'requestId': row['request_id']?.toString(),
          'rosterId': row['roster_id']?.toString(),
          'reason': row['reason']?.toString(),
          'requestDate': row['request_date']?.toString(),
          'status': row['status']?.toString(),
          'shiftType': row['shift_type']?.toString(),
          'shiftDate': row['shift_date']?.toString(),
          'timeRange': row['shift_time_range']?.toString(),
        };
      }).toList();
    } catch (e, st) {
      session.log('getMyChangeRequests failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Get all pending change requests (for admin)
  Future<List<Map<String, dynamic>>> getAllChangeRequests(
    Session session, {
    String? status,
  }) async {
    try {
      await _initRostersTable(session);

      final buffer = StringBuffer('''
        SELECT 
          scr.request_id,
          scr.roster_id,
          scr.staff_id,
          scr.reason,
          scr.request_date::text,
          scr.status::text,
          r.shift_type::text,
          r.shift_date::text,
          r.shift_time_range,
          u.name AS staff_name
        FROM shift_change_requests scr
        JOIN rosters r ON r.roster_id = scr.roster_id
        JOIN users u ON u.user_id = scr.staff_id
      ''');

      if (status != null && status.isNotEmpty) {
        buffer.write(" WHERE scr.status = @status::request_status");
      }

      buffer.write(' ORDER BY scr.request_date DESC');

      final params = status != null && status.isNotEmpty
          ? QueryParameters.named({'status': status})
          : null;

      final result = await session.db.unsafeQuery(
        buffer.toString(),
        parameters: params,
      );

      return result.map((r) {
        final row = r.toColumnMap();
        return <String, dynamic>{
          'requestId': row['request_id']?.toString(),
          'rosterId': row['roster_id']?.toString(),
          'staffId': row['staff_id']?.toString(),
          'staffName': row['staff_name']?.toString(),
          'reason': row['reason']?.toString(),
          'requestDate': row['request_date']?.toString(),
          'status': row['status']?.toString(),
          'shiftType': row['shift_type']?.toString(),
          'shiftDate': row['shift_date']?.toString(),
          'timeRange': row['shift_time_range']?.toString(),
        };
      }).toList();
    } catch (e, st) {
      session.log('getAllChangeRequests failed: $e\n$st',
          level: LogLevel.error);
      return [];
    }
  }

  /// Approve or reject a change request (admin only)
  Future<Map<String, dynamic>> updateRequestStatus(
    Session session, {
    required int requestId,
    required String status, // 'APPROVED' or 'REJECTED'
  }) async {
    try {
      await _initRostersTable(session);

      // Validate status
      if (!['APPROVED', 'REJECTED'].contains(status.toUpperCase())) {
        return {'success': false, 'message': 'Invalid status'};
      }

      // Update the request status
      final result = await session.db.unsafeQuery('''
        UPDATE shift_change_requests
        SET status = @status::request_status
        WHERE request_id = @rid
        RETURNING roster_id
      ''',
          parameters: QueryParameters.named({
            'rid': requestId,
            'status': status.toUpperCase(),
          }));

      if (result.isEmpty) {
        return {'success': false, 'message': 'Request not found'};
      }

      // If approved, update the roster status to CONFIRMED
      if (status.toUpperCase() == 'APPROVED') {
        final rosterId = result.first.toColumnMap()['roster_id'];
        await session.db.unsafeExecute('''
          UPDATE rosters
          SET status = 'CONFIRMED'::roster_status
          WHERE roster_id = @rid
        ''', parameters: QueryParameters.named({'rid': rosterId}));
      }

      return {
        'success': true,
        'message': 'Request ${status.toLowerCase()} successfully',
      };
    } catch (e, st) {
      session.log('updateRequestStatus failed: $e\n$st', level: LogLevel.error);
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ------------------ Audit Log ------------------
  Future<bool> _initAuditLog(Session session) async {
    try {
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS audit_log (
          log_id VARCHAR(50) PRIMARY KEY,
          user_id VARCHAR(50),
          action VARCHAR(200),
          timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      return true;
    } catch (e, st) {
      session.log('initAuditLog failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> addAuditLog(
      Session session, String logId, String userId, String action) async {
    try {
      await _initAuditLog(session);
      await session.db.unsafeExecute('''
        INSERT INTO audit_log (log_id, user_id, action) VALUES (@id, @uid, @act)
      ''',
          parameters: QueryParameters.named(
              {'id': logId, 'uid': userId, 'act': action}));
      return true;
    } catch (e, st) {
      session.log('addAuditLog failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAuditLogs(
      Session session, int limit, int offset) async {
    try {
      await _initAuditLog(session);
      final result = await session.db.unsafeQuery('''
        SELECT log_id, user_id, action, timestamp FROM audit_log ORDER BY timestamp DESC LIMIT @lim OFFSET @off
      ''', parameters: QueryParameters.named({'lim': limit, 'off': offset}));

      final list = <Map<String, dynamic>>[];
      for (final r in result) {
        final row = r.toColumnMap();
        list.add({
          'logId': row['log_id'],
          'userId': row['user_id'],
          'action': row['action'],
          'timestamp': row['timestamp']?.toString(),
        });
      }
      return list;
    } catch (e, st) {
      session.log('getAuditLogs failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  // ------------------ Notifications ------------------
  Future<bool> _initNotifications(Session session) async {
    try {
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS notifications (
          notification_id VARCHAR(50) PRIMARY KEY,
          user_id VARCHAR(50),
          message TEXT,
          sent_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      return true;
    } catch (e, st) {
      session.log('initNotifications failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> sendNotification(Session session, String notificationId,
      String userId, String message) async {
    try {
      await _initNotifications(session);
      await session.db.unsafeExecute('''
        INSERT INTO notifications (notification_id, user_id, message) VALUES (@nid, @uid, @msg)
      ''',
          parameters: QueryParameters.named(
              {'nid': notificationId, 'uid': userId, 'msg': message}));
      return true;
    } catch (e, st) {
      session.log('sendNotification failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listNotifications(
      Session session, String userId, int limit) async {
    try {
      await _initNotifications(session);
      final result = await session.db.unsafeQuery('''
        SELECT notification_id, user_id, message, sent_date FROM notifications WHERE user_id = @uid ORDER BY sent_date DESC LIMIT @lim
      ''', parameters: QueryParameters.named({'uid': userId, 'lim': limit}));

      final list = <Map<String, dynamic>>[];
      for (final r in result) {
        final row = r.toColumnMap();
        list.add({
          'notificationId': row['notification_id'],
          'userId': row['user_id'],
          'message': row['message'],
          'sentDate': row['sent_date']?.toString(),
        });
      }
      return list;
    } catch (e, st) {
      session.log('listNotifications failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  // ------------------ Staff Profiles ------------------
  Future<bool> _initStaffProfiles(Session session) async {
    try {
      await session.db.unsafeExecute('''
        CREATE TABLE IF NOT EXISTS staff_profiles (
          user_id VARCHAR(50) PRIMARY KEY REFERENCES users(user_id),
          specialization VARCHAR(100),
          qualification VARCHAR(100),
          joining_date DATE
        )
      ''');
      return true;
    } catch (e, st) {
      session.log('initStaffProfiles failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listStaff(
      Session session, int limit) async {
    try {
      await _initStaffProfiles(session);
      final result = await session.db.unsafeQuery('''
        SELECT u.user_id, u.name, u.email, u.role::text, u.profile_picture_url, s.specialization, s.qualification, s.joining_date
        FROM users u
        LEFT JOIN staff_profiles s ON s.user_id = u.user_id
        WHERE u.role::text IN ('doctor','dispenser','labstaff') OR u.role::text = 'admin'
        ORDER BY u.name
        LIMIT @lim
      ''', parameters: QueryParameters.named({'lim': limit}));

      final list = <Map<String, dynamic>>[];
      for (final r in result) {
        final row = r.toColumnMap();
        list.add({
          'userId': row['user_id'],
          'name': row['name'],
          'email': row['email'],
          'role': row['role'],
          'profilePictureUrl': row['profile_picture_url'],
          'specialization': row['specialization'],
          'qualification': row['qualification'],
          'joiningDate': row['joining_date']?.toString(),
        });
      }
      return list;
    } catch (e, st) {
      session.log('listStaff failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  // ------------------ Admin Profile / Password Management ------------------
  /// Get profile by email (userId). Returns basic user fields and, if available,
  /// staff profile details (department/specialization, qualification, joining_date).
  /// Returns JSON string to avoid Serverpod deserialization issues.
  Future<String?> getAdminProfile(Session session, String userId) async {
    try {
      // Validate input
      if (userId.trim().isEmpty) {
        session.log('getAdminProfile: empty userId', level: LogLevel.warning);
        return null;
      }

      // Ensure staff_profiles table exists before LEFT JOIN
      await _initStaffProfiles(session);

      final result = await session.db.unsafeQuery(
        '''
        SELECT 
          u.name, u.email, u.phone, u.profile_picture_url,
          s.specialization AS department,
          s.qualification,
          s.joining_date
        FROM users u
        LEFT JOIN staff_profiles s ON s.user_id = u.user_id
        WHERE u.email = @e
        ''',
        parameters: QueryParameters.named({'e': userId.trim()}),
      );

      if (result.isEmpty) {
        session.log('getAdminProfile: user not found for $userId',
            level: LogLevel.warning);
        return null;
      }

      final row = result.first.toColumnMap();
      final data = {
        'name': row['name'] ?? '',
        'email': row['email'] ?? '',
        'phone': row['phone'] ?? '',
        'profilePictureUrl': row['profile_picture_url'] ?? '',
        // Extra fields for staff profiles
        'department': row['department'] ?? '',
        'qualification': row['qualification'] ?? '',
        'joinedDate': row['joining_date']?.toString() ?? '',
      };
      return jsonEncode(data);
    } catch (e, st) {
      session.log('getAdminProfile failed: $e\n$st', level: LogLevel.error);
      return null;
    }
  }

  /// Update admin profile: name, phone, optional small base64 profilePictureData (<=50KB)
  Future<String> updateAdminProfile(Session session, String userId, String name,
      String phone, String? profilePictureData) async {
    try {
      // Validate inputs
      if (userId.trim().isEmpty) {
        return 'Invalid user ID';
      }
      if (name.trim().isEmpty) {
        return 'Name is required';
      }
      if (phone.trim().isEmpty) {
        return 'Phone is required';
      }

      // Check if user exists
      final userCheck = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE email = @e',
        parameters: QueryParameters.named({'e': userId.trim()}),
      );
      if (userCheck.isEmpty) {
        return 'User not found';
      }

      await session.db.unsafeExecute('BEGIN');

      String? profilePictureUrl;
      if (profilePictureData != null && profilePictureData.isNotEmpty) {
        // Validate and size-check base64 payload (<= 50KB)
        try {
          // If a data URI, keep original but validate by decoding the payload
          String base64Payload = profilePictureData;
          final dataUriPattern = RegExp(r'^data:image/[a-zA-Z]+;base64,');
          if (dataUriPattern.hasMatch(profilePictureData)) {
            final commaIndex = profilePictureData.indexOf(',');
            if (commaIndex > -1) {
              base64Payload = profilePictureData.substring(commaIndex + 1);
            }
          }

          // Decode base64 to bytes to check actual size
          final bytes = base64Decode(base64Payload);
          if (bytes.length > 50 * 1024) {
            await session.db.unsafeExecute('ROLLBACK');
            return 'Profile picture too large. Max 50 KB allowed.';
          }
          // Store original string (preserves data URI if present)
          profilePictureUrl = profilePictureData;
        } catch (e) {
          await session.db.unsafeExecute('ROLLBACK');
          session.log('Invalid profile picture data: $e',
              level: LogLevel.warning);
          return 'Invalid profile picture format';
        }
      }

      final updateResult = await session.db.unsafeQuery(
        '''
        UPDATE users
        SET name = @name,
            phone = @phone,
            profile_picture_url = COALESCE(@ppurl, profile_picture_url)
        WHERE email = @e
        RETURNING user_id
        ''',
        parameters: QueryParameters.named({
          'e': userId.trim(),
          'name': name.trim(),
          'phone': phone.trim(),
          'ppurl': profilePictureUrl,
        }),
      );

      if (updateResult.isEmpty) {
        await session.db.unsafeExecute('ROLLBACK');
        return 'Failed to update profile';
      }

      await session.db.unsafeExecute('COMMIT');
      return 'OK';
    } on DatabaseQueryException catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('updateAdminProfile DB error: $e', level: LogLevel.error);
      return 'Database error: ${e.message}';
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('updateAdminProfile failed: $e\n$st', level: LogLevel.error);
      return 'Failed to update profile: $e';
    }
  }

  /// Change password for given user (identified by email/userId). Verifies current password before updating.
  Future<String> changePassword(Session session, String userId,
      String currentPassword, String newPassword) async {
    try {
      // Validate inputs
      if (userId.trim().isEmpty) {
        return 'Invalid user ID';
      }
      if (currentPassword.isEmpty) {
        return 'Current password is required';
      }
      if (newPassword.isEmpty) {
        return 'New password is required';
      }
      if (newPassword.length < 6) {
        return 'New password must be at least 6 characters';
      }
      if (currentPassword == newPassword) {
        return 'New password must be different from current password';
      }

      final result = await session.db.unsafeQuery(
        '''SELECT password_hash FROM users WHERE email = @e''',
        parameters: QueryParameters.named({'e': userId.trim()}),
      );

      if (result.isEmpty) {
        session.log('changePassword: user not found for $userId',
            level: LogLevel.warning);
        return 'User not found';
      }

      final row = result.first.toColumnMap();
      String storedHash;
      final ph = row['password_hash'];
      if (ph == null) {
        storedHash = '';
      } else if (ph is List<int>) {
        storedHash = String.fromCharCodes(ph);
      } else {
        storedHash = ph.toString();
      }

      // Verify current password
      final currHash = sha256.convert(utf8.encode(currentPassword)).toString();
      if (storedHash != currHash) {
        session.log('changePassword: incorrect password for $userId',
            level: LogLevel.warning);
        return 'Incorrect current password';
      }

      // Update to new password
      final newHash = sha256.convert(utf8.encode(newPassword)).toString();
      final updateResult = await session.db.unsafeQuery(
        '''
        UPDATE users 
        SET password_hash = @p 
        WHERE email = @e
        RETURNING user_id
        ''',
        parameters: QueryParameters.named({
          'p': newHash,
          'e': userId.trim(),
        }),
      );

      if (updateResult.isEmpty) {
        return 'Failed to update password';
      }

      session.log('Password changed successfully for $userId',
          level: LogLevel.info);
      return 'OK';
    } on DatabaseQueryException catch (e) {
      session.log('changePassword DB error: $e', level: LogLevel.error);
      return 'Database error: ${e.message}';
    } catch (e, st) {
      session.log('changePassword failed: $e\n$st', level: LogLevel.error);
      return 'Failed to change password';
    }
  }

  /// Update staff profile details for a user identified by email.
  /// Allows updating specialization, qualification, and joining_date.
  /// Returns 'OK' on success or an error message.
  Future<String> updateStaffProfile(
    Session session,
    String userId, {
    String? name,
    String? specialization,
    String? qualification,
    DateTime? joiningDate,
  }) async {
    try {
      if (userId.trim().isEmpty) return 'Invalid user id';
      await session.db.unsafeExecute('BEGIN');

      // Optionally update name in users table
      if (name != null && name.trim().isNotEmpty) {
        await session.db.unsafeExecute(
          'UPDATE users SET name = @name WHERE user_id = @uid',
          parameters: QueryParameters.named({
            'name': name,
            'uid': userId,
          }),
        );
      }

      // Upsert staff profile fields
      await session.db.unsafeExecute(
        '''
      INSERT INTO staff_profiles (user_id, specialization, qualification, joining_date)
      VALUES (@uid, @spec, @qual, @join)
      ON CONFLICT (user_id) DO UPDATE SET
        specialization = COALESCE(EXCLUDED.specialization, staff_profiles.specialization),
        qualification  = COALESCE(EXCLUDED.qualification, staff_profiles.qualification),
        joining_date   = COALESCE(EXCLUDED.joining_date, staff_profiles.joining_date)
      ''',
        parameters: QueryParameters.named({
          'uid': userId,
          'spec': specialization,
          'qual': qualification,
          'join': joiningDate,
        }),
      );

      await session.db.unsafeExecute('COMMIT');

      return 'OK';
    } catch (e, st) {
      try {
        await session.db.unsafeExecute('ROLLBACK');
      } catch (_) {}
      session.log('updateStaffProfile failed: $e\n$st', level: LogLevel.error);
      return 'Failed to update staff profile';
    }
  }
}
