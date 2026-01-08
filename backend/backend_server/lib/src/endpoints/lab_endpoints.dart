import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:uuid/uuid.dart';
import '../generated/protocol.dart' as protocol;

//lab profile
class ProfileEndpoint extends Endpoint {
  /// =========================
  /// GET USER PROFILE
  /// =========================
  Future<Map<String, dynamic>?> getProfile(
    Session session,
    Uuid userId,
  ) async {
    try {
      // Validate input
      if (userId.toString().isEmpty) {
        session.log('getProfile: empty userId', level: LogLevel.warning);
        return null;
      }

      final result = await session.db.unsafeQuery(
        '''
        SELECT 
          u.user_id,
          u.name,
          u.email,
          u.phone,
          u.role,
          u.profile_picture_url,
          s.specialization,
          s.qualification,
          s.joining_date
        FROM users u
        LEFT JOIN staff_profiles s ON u.user_id = s.user_id
        WHERE u.user_id = @userId
        ''',
        parameters: QueryParameters.named({
          'userId': userId,
        }),
      );

      if (result.isEmpty) {
        session.log('getProfile: user not found for $userId',
            level: LogLevel.warning);
        return null;
      }

      return result.first.toColumnMap();
    } on DatabaseQueryException catch (e) {
      session.log('getProfile DB error: ${e.message}', level: LogLevel.error);
      return null;
    } catch (e, st) {
      session.log('getProfile failed: $e\n$st', level: LogLevel.error);
      return null;
    }
  }

  /// =========================
  /// CHANGE PASSWORD
  /// =========================
  Future<bool> changePassword(
    Session session,
    Uuid userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // Validate inputs
      if (userId.toString().isEmpty) {
        session.log('changePassword: empty userId', level: LogLevel.warning);
        return false;
      }
      if (oldPassword.isEmpty) {
        session.log('changePassword: empty old password',
            level: LogLevel.warning);
        return false;
      }
      if (newPassword.isEmpty) {
        session.log('changePassword: empty new password',
            level: LogLevel.warning);
        return false;
      }
      if (newPassword.length < 6) {
        session.log('changePassword: new password too short',
            level: LogLevel.warning);
        return false;
      }
      if (oldPassword == newPassword) {
        session.log('changePassword: same password', level: LogLevel.warning);
        return false;
      }

      final result = await session.db.unsafeQuery(
        'SELECT password_hash FROM users WHERE user_id = @userId',
        parameters: QueryParameters.named({'userId': userId}),
      );

      if (result.isEmpty) {
        session.log('changePassword: user not found for $userId',
            level: LogLevel.warning);
        return false;
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
      final oldHash = sha256.convert(utf8.encode(oldPassword)).toString();
      if (storedHash != oldHash) {
        session.log('changePassword: incorrect old password for $userId',
            level: LogLevel.warning);
        return false;
      }

      final newHash = sha256.convert(utf8.encode(newPassword)).toString();

      await session.db.unsafeExecute(
        '''
        UPDATE users
        SET password_hash = @newHash
        WHERE user_id = @userId
        ''',
        parameters: QueryParameters.named({
          'newHash': newHash,
          'userId': userId,
        }),
      );

      session.log('changePassword: success for $userId', level: LogLevel.info);
      return true;
    } on DatabaseQueryException catch (e) {
      session.log('changePassword DB error: ${e.message}',
          level: LogLevel.error);
      return false;
    } catch (e, st) {
      session.log('changePassword failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// =========================
  /// UPDATE PROFILE (PHONE / QUALIFICATION)
  /// =========================
  Future<bool> updateProfile(
    Session session,
    Uuid userId,
    String phone,
    String qualification,
  ) async {
    try {
      // Validate inputs
      if (userId.toString().isEmpty) {
        session.log('updateProfile: empty userId', level: LogLevel.warning);
        return false;
      }
      if (phone.trim().isEmpty) {
        session.log('updateProfile: empty phone', level: LogLevel.warning);
        return false;
      }

      // Check if user exists
      final userCheck = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE user_id = @userId',
        parameters: QueryParameters.named({'userId': userId}),
      );
      if (userCheck.isEmpty) {
        session.log('updateProfile: user not found for $userId',
            level: LogLevel.warning);
        return false;
      }

      await session.db.unsafeExecute(
        '''
        UPDATE users
        SET phone = @phone
        WHERE user_id = @userId
        ''',
        parameters: QueryParameters.named({
          'phone': phone.trim(),
          'userId': userId,
        }),
      );

      if (qualification.trim().isNotEmpty) {
        await session.db.unsafeExecute(
          '''
          INSERT INTO staff_profiles (user_id, qualification)
          VALUES (@userId, @qualification)
          ON CONFLICT (user_id)
          DO UPDATE SET qualification = @qualification
          ''',
          parameters: QueryParameters.named({
            'userId': userId,
            'qualification': qualification.trim(),
          }),
        );
      }

      session.log('updateProfile: success for $userId', level: LogLevel.info);
      return true;
    } on DatabaseQueryException catch (e) {
      session.log('updateProfile DB error: ${e.message}',
          level: LogLevel.error);
      return false;
    } catch (e, st) {
      session.log('updateProfile failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  // ========== LAB TEST BOOKING METHODS ==========
  // These methods were moved from LabEndpoints class to ProfileEndpoint
  // so they're accessible via client.profile.methodName()

  /// List all lab tests from the lab_tests table.
  /// Returns strongly-typed LabTestInfo models so the Flutter app
  /// can deserialize them safely.
  Future<List<protocol.LabTestInfo>> listLabTests(Session session) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''
        SELECT
          test_id,
          test_name,
          description,
          student_fee,
          staff_fee,
          outside_fee,
          available
        FROM lab_tests
        ORDER BY test_name
        ''',
      );

      return rows
          .map((r) {
            final m = r.toColumnMap();

            // Be defensive: handle possible nulls and unexpected types so that
            // a bad row doesn't crash the whole endpoint.
            final rawTestId = m['test_id'];
            final rawTestName = m['test_name'];

            if (rawTestId == null || rawTestName == null) {
              session.log(
                'listLabTests: skipping row with missing test_id or test_name: $m',
                level: LogLevel.warning,
              );
              // This will be filtered out by whereType below.
              return null;
            }

            double _numToDouble(dynamic v, double fallback) {
              if (v == null) return fallback;
              if (v is num) return v.toDouble();
              final parsed = double.tryParse(v.toString());
              return parsed ?? fallback;
            }

            return protocol.LabTestInfo(
              testId: rawTestId is int
                  ? rawTestId
                  : int.parse(rawTestId.toString()),
              testName: rawTestName.toString(),
              description: m['description'] as String?,
              studentFee: _numToDouble(m['student_fee'], 0.0),
              // Map DB column staff_fee -> model field staffFee
              staffFee: _numToDouble(m['staff_fee'], 0.0),
              outsideFee: _numToDouble(m['outside_fee'], 0.0),
              available: (m['available'] as bool?) ?? true,
            );
          })
          .whereType<protocol.LabTestInfo>()
          .toList();
    } on DatabaseQueryException catch (e) {
      session.log('listLabTests DB error: ${e.message}', level: LogLevel.error);
      return [];
    } catch (e, st) {
      session.log('listLabTests failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Helper to ensure schema columns exist for walk-in patients.
  /// This is a safe "hot-fix" migration to ensure the server works without manual DB intervention.
  Future<void> _ensureExternalPatientColumns(Session session) async {
    try {
      await session.db.unsafeExecute(
          'ALTER TABLE test_bookings ADD COLUMN IF NOT EXISTS external_patient_name text');
      await session.db.unsafeExecute(
          'ALTER TABLE test_bookings ADD COLUMN IF NOT EXISTS external_patient_email text');
      await session.db.unsafeExecute(
          'ALTER TABLE test_bookings ADD COLUMN IF NOT EXISTS external_patient_phone text');
    } catch (e) {
      // Ignore errors if columns exist or race conditions
      session.log('Schema check ignored: $e', level: LogLevel.debug);
    }
  }

  /// List all lab test bookings with basic joined information for dashboard.
  ///
  /// Returns one [protocol.TestBookingDto] per booking-test pairing.
  Future<List<protocol.TestBookingDto>> listTestBookings(
    Session session,
  ) async {
    try {
      // Ensure columns exist (fast NO-OP if they do)
      await _ensureExternalPatientColumns(session);

      final rows = await session.db.unsafeQuery(
        '''
        SELECT
          tb.booking_id,
          tb.patient_id,
          bt.test_id,
          tb.booking_date,
          tb.is_external_patient,
          tb.status::text,
          tb.external_patient_name,
          tb.external_patient_email,
          tb.external_patient_phone,
          u.name AS user_name,
          u.email AS user_email,
          u.phone AS user_phone,
          lt.test_name,
          lt.outside_fee
        FROM test_bookings tb
        LEFT JOIN booking_tests bt ON tb.booking_id = bt.booking_id
        LEFT JOIN lab_tests lt ON bt.test_id = lt.test_id
        LEFT JOIN users u ON tb.patient_id = u.user_id
        ORDER BY tb.booking_date DESC, tb.booking_id DESC
        ''',
      );

      return rows.map((r) {
        final m = r.toColumnMap();
        final bookingId = m['booking_id']?.toString() ?? '';
        if (bookingId.isEmpty) {
          throw StateError('Encountered booking row without booking_id');
        }

        final patientId = m['patient_id']?.toString();

        // Safely parse testId - DB may return as String or int
        final testIdRaw = m['test_id'];
        final testId = testIdRaw is int
            ? testIdRaw
            : int.tryParse(testIdRaw?.toString() ?? '0') ?? 0;

        // Handle bookingDate - may be DateTime or String
        final bookingDateRaw = m['booking_date'];
        final bookingDate = bookingDateRaw is DateTime
            ? bookingDateRaw.toIso8601String().split('T').first
            : bookingDateRaw?.toString() ?? '';

        final isExternal = (m['is_external_patient'] as bool?) ?? false;
        final patientType =
            'outpatient'; // Default; inferred from user role in createTestBooking
        final rawStatus = m['status']?.toString();
        final status =
            (rawStatus == null || rawStatus.isEmpty) ? 'PENDING' : rawStatus;

        // Fallback logic for patient details: User Table -> External Columns -> Generic
        final patientName = m['user_name']?.toString() ??
            m['external_patient_name']?.toString();

        final patientEmail = m['user_email']?.toString() ??
            m['external_patient_email']?.toString();

        final patientPhone = m['user_phone']?.toString() ??
            m['external_patient_phone']?.toString();

        final testName = m['test_name']?.toString() ?? '';

        // Safely parse outsideFee - DB may return as String or num
        final outsideFeeRaw = m['outside_fee'];
        final outsideFee = outsideFeeRaw is num
            ? outsideFeeRaw.toDouble()
            : double.tryParse(outsideFeeRaw?.toString() ?? '0') ?? 0.0;

        return protocol.TestBookingDto(
          bookingId: bookingId,
          patientId: patientId,
          testId: testId,
          bookingDate: bookingDate,
          isExternalPatient: isExternal,
          patientType: patientType,
          status: status,
          patientName: patientName,
          patientEmail: patientEmail,
          patientPhone: patientPhone,
          testName: testName,
          outsideFee: outsideFee,
        );
      }).toList();
    } on DatabaseQueryException catch (e) {
      session.log(
        'listTestBookings DB error: ${e.message}',
        level: LogLevel.error,
      );
      return [];
    } catch (e, st) {
      session.log(
        'listTestBookings failed: ${e.toString()}\n$st',
        level: LogLevel.error,
      );
      return [];
    }
  }

  /// Insert a new lab test into lab_tests and return the generated test_id.
  Future<int?> createLabTest(
    Session session, {
    required String testName,
    String? description,
    double studentFee = 0.0,
    double staffFee = 0.0,
    double outsideFee = 0.0,
    bool available = true,
  }) async {
    try {
      final rows = await session.db.unsafeQuery(
        '''
        INSERT INTO lab_tests (
          test_name,
          description,
          student_fee,
          staff_fee,
          outside_fee,
          available
        ) VALUES (
          @testName,
          @description,
          @studentFee,
          @staffFee,
          @outsideFee,
          @available
        )
        RETURNING test_id
        ''',
        parameters: QueryParameters.named({
          'testName': testName.trim(),
          'description': description?.trim(),
          'studentFee': studentFee,
          'staffFee': staffFee,
          'outsideFee': outsideFee,
          'available': available,
        }),
      );

      if (rows.isEmpty) return null;
      final value = rows.first.toColumnMap()['test_id'];
      if (value is int) return value;
      return int.tryParse(value.toString());
    } on DatabaseQueryException catch (e) {
      session.log('createLabTest DB error: ${e.message}',
          level: LogLevel.error);
      return null;
    } catch (e, st) {
      session.log('createLabTest failed: $e\n$st', level: LogLevel.error);
      return null;
    }
  }

  /// Update an existing lab test. All fields are required to keep the query
  /// simple on the client side.
  Future<bool> updateLabTest(
    Session session, {
    required int testId,
    required String testName,
    String? description,
    required double studentFee,
    required double staffFee,
    required double outsideFee,
    required bool available,
  }) async {
    try {
      await session.db.unsafeExecute(
        '''
        UPDATE lab_tests
        SET
          test_name = @testName,
          description = @description,
          student_fee = @studentFee,
          staff_fee = @staffFee,
          outside_fee = @outsideFee,
          available = @available
        WHERE test_id = @testId
        ''',
        parameters: QueryParameters.named({
          'testId': testId,
          'testName': testName.trim(),
          'description': description?.trim(),
          'studentFee': studentFee,
          'staffFee': staffFee,
          'outsideFee': outsideFee,
          'available': available,
        }),
      );
      return true;
    } on DatabaseQueryException catch (e) {
      session.log('updateLabTest DB error: ${e.message}',
          level: LogLevel.error);
      return false;
    } catch (e, st) {
      session.log('updateLabTest failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// Search for a patient/user by user_id, email, or phone number.
  /// Returns user details if found, null otherwise.
  Future<Map<String, dynamic>?> searchPatient(
    Session session, {
    required String searchTerm,
  }) async {
    try {
      final trimmed = searchTerm.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final results = await session.db.unsafeQuery(
        '''
        SELECT 
          u.user_id,
          u.name,
          u.email,
          u.phone,
          u.role,
          pp.blood_group,
          pp.date_of_birth
        FROM users u
        LEFT JOIN patient_profiles pp ON u.user_id = pp.user_id
        WHERE u.email = @searchTerm 
           OR u.user_id = @searchTerm 
           OR u.phone = @searchTerm
           OR u.phone LIKE '%' || @searchTerm || '%'
        LIMIT 1
        ''',
        parameters: QueryParameters.named({
          'searchTerm': trimmed,
        }),
      );

      if (results.isEmpty) {
        session.log(
          'searchPatient: no user found for search term: $trimmed',
          level: LogLevel.info,
        );
        return null;
      }

      final row = results.first.toColumnMap();

      // Determine patient type from role
      final role = row['role']?.toString().toUpperCase() ?? '';
      String patientType = 'outpatient';
      if (role == 'STUDENT') {
        patientType = 'student';
      } else if ([
        'TEACHER',
        'STAFF',
        'DOCTOR',
        'DISPENSER',
        'LABSTAFF',
        'ADMIN'
      ].contains(role)) {
        patientType = 'staff';
      }

      return {
        'userId': row['user_id']?.toString(),
        'name': row['name']?.toString(),
        'email': row['email']?.toString(),
        'phone': row['phone']?.toString(),
        'role': role,
        'patientType': patientType,
        'bloodGroup': row['blood_group']?.toString(),
        'dateOfBirth': row['date_of_birth']?.toString(),
      };
    } on DatabaseQueryException catch (e) {
      session.log('searchPatient DB error: ${e.message}',
          level: LogLevel.error);
      return null;
    } catch (e, st) {
      session.log('searchPatient failed: $e\n$st', level: LogLevel.error);
      return null;
    }
  }

  /// Create separate test bookings for each selected test.
  ///
  /// IMPORTANT: This method creates ONE BOOKING PER TEST, not a single booking with multiple tests.
  ///
  /// Business Logic:
  /// - If patient selects [CBC, SGPT], creates 2 separate bookings
  /// - Each booking has its own booking_id and booking_code
  /// - Each booking can have its own result file uploaded independently
  /// - One-to-one relationship: 1 booking = 1 test
  ///
  /// Patient ID Resolution:
  /// - If patientId matches a user_id from database: uses actual user_id, is_external_patient=false
  /// - If patientId is a generated ID (>= 1000000): stores as external patient
  /// - If patientId not found in database: marks as external patient
  ///
  /// Returns a comma-separated list of booking codes (e.g., "BK000001,BK000002,BK000003")
  /// Returns empty string "" on failure.
  Future<String> createTestBooking(
    Session session, {
    required String bookingId,
    String? patientId,
    required List<int> testIds,
    required DateTime bookingDate,
    bool isExternalPatient = false,
    String? patientType,
    String? externalPatientName,
    String? externalPatientEmail,
    String? externalPatientPhone,
  }) async {
    try {
      // Ensure columns exist (fast NO-OP if they do)
      await _ensureExternalPatientColumns(session);

      final trimmedBookingId = bookingId.trim();
      if (trimmedBookingId.isEmpty) {
        session.log('createTestBooking: empty bookingId',
            level: LogLevel.warning);
        return '';
      }
      if (testIds.isEmpty) {
        session.log('createTestBooking: empty testIds',
            level: LogLevel.warning);
        return '';
      }

      // Resolve patientId (which the client may send as email, user_id, or phone)
      // into the actual users.user_id value
      int? dbPatientId;

      if (patientId != null && patientId.trim().isNotEmpty) {
        final lookup = await session.db.unsafeQuery(
          '''
          SELECT user_id, role, email, phone 
          FROM users 
          WHERE email = @id 
             OR user_id::text = @id 
             OR phone = @id
             OR phone LIKE '%' || @id || '%'
          LIMIT 1
          ''',
          parameters: QueryParameters.named({
            'id': patientId.trim(),
          }),
        );

        if (lookup.isNotEmpty) {
          final row = lookup.first.toColumnMap();
          final raw = row['user_id'];
          if (raw != null) {
            dbPatientId = raw is int ? raw : int.tryParse(raw.toString());
          }
        } else {
          session.log(
            'createTestBooking: no user found for identifier=$patientId, storing as external patient',
            level: LogLevel.warning,
          );
        }
      }

      final effectiveIsExternal = isExternalPatient || dbPatientId == null;

      // Use the provided patientId (which may be auto-generated from searchPatient)
      // If it's a generated ID, it will be an external patient
      int? finalPatientId = dbPatientId;
      bool finalIsExternal = effectiveIsExternal;

      // If patientId was provided and is external (not found in users table)
      if (patientId != null && patientId.isNotEmpty && dbPatientId == null) {
        // Try to parse it as an integer (could be generated ID)
        final parsedId = int.tryParse(patientId.trim());
        if (parsedId != null) {
          finalPatientId = parsedId;
          finalIsExternal = true;
          session.log(
            'createTestBooking: using generated/external patientId=$parsedId',
            level: LogLevel.info,
          );
        }
      }

      // Create a SEPARATE booking for EACH test
      // This ensures one-to-one relationship: 1 booking = 1 test
      final List<String> createdBookingCodes = [];

      for (final testId in testIds) {
        try {
          // Insert individual booking record for this test
          final insertRows = await session.db.unsafeQuery(
            '''
            INSERT INTO test_bookings (
              patient_id,
              booking_date,
              is_external_patient,
              status,
              external_patient_name,
              external_patient_email,
              external_patient_phone
            ) VALUES (
              @patientId,
              @bookingDate,
              @isExternalPatient,
              'PENDING'::test_booking_status,
              @extName,
              @extEmail,
              @extPhone
            )
            RETURNING booking_id
            ''',
            parameters: QueryParameters.named({
              'patientId': finalPatientId,
              'bookingDate': bookingDate,
              'isExternalPatient': finalIsExternal,
              'extName': externalPatientName,
              'extEmail': externalPatientEmail,
              'extPhone': externalPatientPhone,
            }),
          );

          if (insertRows.isEmpty) {
            session.log(
              'createTestBooking: failed to create booking for testId=$testId',
              level: LogLevel.warning,
            );
            continue;
          }

          final bookingIdRaw = insertRows.first.toColumnMap()['booking_id'];
          final bookingPk = bookingIdRaw is int
              ? bookingIdRaw
              : int.tryParse(bookingIdRaw?.toString() ?? '') ?? -1;

          if (bookingPk <= 0) {
            session.log(
              'createTestBooking: invalid booking_id for testId=$testId',
              level: LogLevel.warning,
            );
            continue;
          }

          final bookingCode = 'BK${bookingPk.toString().padLeft(6, '0')}';

          // Link test to booking via junction table
          try {
            await session.db.unsafeExecute(
              '''
              INSERT INTO booking_tests (booking_id, test_id)
              VALUES (@bookingId, @testId)
              ON CONFLICT (booking_id, test_id) DO NOTHING
              ''',
              parameters: QueryParameters.named({
                'bookingId': bookingPk,
                'testId': testId,
              }),
            );

            createdBookingCodes.add(bookingCode);
            session.log(
              'createTestBooking: created booking $bookingCode (id=$bookingPk) for testId=$testId, patient=$finalPatientId',
              level: LogLevel.info,
            );
          } catch (e) {
            session.log(
              'createTestBooking: failed to link test $testId to booking $bookingCode: $e',
              level: LogLevel.warning,
            );
          }
        } catch (e) {
          session.log(
            'createTestBooking: error creating booking for testId=$testId: $e',
            level: LogLevel.warning,
          );
        }
      }

      if (createdBookingCodes.isEmpty) {
        session.log(
          'createTestBooking failed: no bookings created for testIds=$testIds',
          level: LogLevel.error,
        );
        return '';
      }

      final resultCodes = createdBookingCodes.join(',');
      session.log(
        'createTestBooking: successfully created ${createdBookingCodes.length} bookings: $resultCodes for testIds=$testIds, patient=$finalPatientId',
        level: LogLevel.info,
      );
      return resultCodes;
    } on DatabaseQueryException catch (e) {
      if (e.message.contains('duplicate key') || e.message.contains('23505')) {
        // Duplicate booking - treat as idempotent success
        session.log(
          'createTestBooking: duplicate booking detected (${e.message}), treating as success',
          level: LogLevel.info,
        );
        return '';
      }
      session.log('createTestBooking DB error: ${e.message}',
          level: LogLevel.error);
      return '';
    } catch (e, st) {
      session.log('createTestBooking failed: $e\n$st', level: LogLevel.error);
      return '';
    }
  }

  /// Upload or update a test result entry for a specific booking test.
  ///
  /// This writes to the `test_results` table with a reference to booking_tests.
  /// Since a booking can have multiple tests (via booking_tests junction table),
  /// this endpoint handles results for individual test entries.
  ///
  /// The result references booking_test_id (the junction table record),
  /// which links to both a booking and a test.
  Future<bool> uploadTestResult(
    Session session, {
    required String bookingId,
    String? testId,
    String? staffId,
    String status = 'COMPLETED',
    DateTime? resultDate,
    String? attachmentPath,
    bool sendToPatient = true,
    bool sendToDoctor = true,
    String? patientEmailOverride,
    String? doctorEmailOverride,
    String? attachmentFileName,
    String? attachmentContentBase64,
    String? attachmentContentType,
  }) async {
    try {
      final trimmedBookingId = bookingId.trim();
      if (trimmedBookingId.isEmpty) {
        session.log('uploadTestResult: empty bookingId',
            level: LogLevel.warning);
        return false;
      }

      // Parse booking code (e.g., BK000123) to numeric booking_id
      int? bookingPk;
      final bkMatch = RegExp(r'^BK(\d+)$', caseSensitive: false)
          .firstMatch(trimmedBookingId);
      if (bkMatch != null) {
        bookingPk = int.tryParse(bkMatch.group(1)!);
      } else {
        bookingPk = int.tryParse(trimmedBookingId);
      }

      if (bookingPk == null) {
        session.log(
          'uploadTestResult: unable to parse bookingId=$trimmedBookingId',
          level: LogLevel.warning,
        );
        return false;
      }

      // Verify booking exists
      final bookingCheck = await session.db.unsafeQuery(
        'SELECT 1 FROM test_bookings WHERE booking_id = @bookingId',
        parameters: QueryParameters.named({'bookingId': bookingPk}),
      );

      if (bookingCheck.isEmpty) {
        session.log(
          'uploadTestResult: booking not found for id=$trimmedBookingId (pk=$bookingPk)',
          level: LogLevel.warning,
        );
        return false;
      }

      // Get first test for this booking if testId not specified
      int? effectiveTestId;
      if (testId != null && testId.trim().isNotEmpty) {
        effectiveTestId = int.tryParse(testId.trim());
      } else {
        // Get first booking_test record
        final testRows = await session.db.unsafeQuery(
          '''
          SELECT test_id FROM booking_tests 
          WHERE booking_id = @bookingId 
          LIMIT 1
          ''',
          parameters: QueryParameters.named({'bookingId': bookingPk}),
        );
        if (testRows.isNotEmpty) {
          final raw = testRows.first.toColumnMap()['test_id'];
          effectiveTestId =
              raw is int ? raw : int.tryParse(raw?.toString() ?? '');
        }
      }

      if (effectiveTestId == null) {
        session.log(
          'uploadTestResult: no test found for booking $trimmedBookingId',
          level: LogLevel.warning,
        );
        return false;
      }

      // Get the booking_test record for this booking + test combo
      final bookingTestRows = await session.db.unsafeQuery(
        '''
        SELECT booking_test_id FROM booking_tests 
        WHERE booking_id = @bookingId AND test_id = @testId
        LIMIT 1
        ''',
        parameters: QueryParameters.named({
          'bookingId': bookingPk,
          'testId': effectiveTestId,
        }),
      );

      if (bookingTestRows.isEmpty) {
        session.log(
          'uploadTestResult: booking_test record not found for booking_id=$bookingPk and test_id=$effectiveTestId',
          level: LogLevel.warning,
        );
        return false;
      }

      final bookingTestRaw =
          bookingTestRows.first.toColumnMap()['booking_test_id'];
      final bookingTestId = bookingTestRaw is int
          ? bookingTestRaw
          : int.tryParse(bookingTestRaw?.toString() ?? '') ?? -1;

      if (bookingTestId <= 0) {
        session.log('uploadTestResult: invalid booking_test_id',
            level: LogLevel.error);
        return false;
      }

      final now = DateTime.now();
      final effectiveDate = resultDate ?? now;

      // Handle attachment storage
      String? attachmentKey = attachmentPath?.trim();

      if (attachmentContentBase64 != null &&
          attachmentContentBase64.trim().isNotEmpty) {
        try {
          final bytes = base64Decode(attachmentContentBase64.trim());

          // Create booking-specific subdirectory
          final bookingDir = Directory(
              'uploaded_results/BK${bookingPk.toString().padLeft(6, '0')}');
          if (!await bookingDir.exists()) {
            await bookingDir.create(recursive: true);
          }

          String safeName =
              (attachmentFileName == null || attachmentFileName.trim().isEmpty)
                  ? 'result_${const Uuid().v4()}'
                  : attachmentFileName
                      .trim()
                      .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

          final relativePath =
              'uploaded_results/BK${bookingPk.toString().padLeft(6, '0')}/$safeName';

          final file = File(relativePath);
          await file.writeAsBytes(bytes, flush: true);
          attachmentKey = relativePath;
        } catch (e, st) {
          session.log(
            'uploadTestResult: failed to persist attachment: $e\n$st',
            level: LogLevel.error,
          );
        }
      }

      final normalizedStatus = status.toUpperCase();

      // Insert result for this specific booking_test (individual test result)
      try {
        await session.db.unsafeExecute(
          '''
          INSERT INTO test_results (
            booking_test_id,
            staff_id,
            status,
            result_date,
            attachment_path
          ) VALUES (
            @bookingTestId,
            @staffId,
            @normalizedStatus::test_result_status,
            @resultDate,
            @attachmentPath
          )
          ON CONFLICT (booking_test_id) DO UPDATE SET
            staff_id = EXCLUDED.staff_id,
            status = EXCLUDED.status,
            result_date = EXCLUDED.result_date,
            attachment_path = EXCLUDED.attachment_path,
            updated_at = CURRENT_TIMESTAMP
          ''',
          parameters: QueryParameters.named({
            'bookingTestId': bookingTestId,
            'staffId': staffId,
            'normalizedStatus': normalizedStatus,
            'resultDate': effectiveDate,
            'attachmentPath': attachmentKey,
          }),
        );
      } on DatabaseQueryException catch (e) {
        if (e.message.contains('test_result_status') ||
            e.message.contains('22P02')) {
          session.log(
            'uploadTestResult: retrying without status enum cast',
            level: LogLevel.warning,
          );

          await session.db.unsafeExecute(
            '''
            INSERT INTO test_results (
              booking_test_id,
              staff_id,
              result_date,
              attachment_path
            ) VALUES (
              @bookingTestId,
              @staffId,
              @resultDate,
              @attachmentPath
            )
            ON CONFLICT (booking_test_id) DO UPDATE SET
              staff_id = EXCLUDED.staff_id,
              result_date = EXCLUDED.result_date,
              attachment_path = EXCLUDED.attachment_path,
              updated_at = CURRENT_TIMESTAMP
            ''',
            parameters: QueryParameters.named({
              'bookingTestId': bookingTestId,
              'staffId': staffId,
              'resultDate': effectiveDate,
              'attachmentPath': attachmentKey,
            }),
          );
        } else {
          rethrow;
        }
      }

      // Check if all tests in this booking are completed
      final pendingTests = await session.db.unsafeQuery(
        '''
        SELECT COUNT(*) as count FROM booking_tests bt
        LEFT JOIN test_results tr ON bt.booking_test_id = tr.booking_test_id
        WHERE bt.booking_id = @bookingId 
        AND (tr.status IS NULL OR tr.status::text != 'COMPLETED')
        ''',
        parameters: QueryParameters.named({'bookingId': bookingPk}),
      );

      bool allCompleted = false;
      if (pendingTests.isNotEmpty) {
        final row = pendingTests.first.toColumnMap();
        final countRaw = row['count'];
        final count = countRaw is int
            ? countRaw
            : int.tryParse(countRaw?.toString() ?? '0') ?? 0;
        allCompleted = count == 0;
      }

      // Update booking status to COMPLETED if all tests are done
      if (allCompleted) {
        try {
          await session.db.unsafeExecute(
            '''
            UPDATE test_bookings
            SET status = 'COMPLETED'::test_booking_status, updated_at = CURRENT_TIMESTAMP
            WHERE booking_id = @bookingId
            ''',
            parameters: QueryParameters.named({'bookingId': bookingPk}),
          );
        } catch (e) {
          session.log(
            'uploadTestResult: warning - failed to update booking status: $e',
            level: LogLevel.warning,
          );
        }
      }

      // Resolve email recipients
      String? patientEmail = patientEmailOverride;
      String? doctorEmail = doctorEmailOverride;

      if (sendToPatient &&
          (patientEmail == null || patientEmail.trim().isEmpty)) {
        final patientRows = await session.db.unsafeQuery(
          '''
          SELECT u.email
          FROM test_bookings tb
          LEFT JOIN users u ON tb.patient_id = u.user_id
          WHERE tb.booking_id = @bookingId
          ''',
          parameters: QueryParameters.named({'bookingId': bookingPk}),
        );

        if (patientRows.isNotEmpty) {
          final row = patientRows.first.toColumnMap();
          final raw = row['email'];
          if (raw != null) patientEmail = raw.toString();
        }
      }

      if (sendToDoctor &&
          (doctorEmail == null || doctorEmail.trim().isEmpty) &&
          staffId != null &&
          staffId.trim().isNotEmpty) {
        final doctorRows = await session.db.unsafeQuery(
          '''
          SELECT u.email
          FROM users u
          WHERE u.user_id::text = @staffId OR u.email = @staffId
          LIMIT 1
          ''',
          parameters: QueryParameters.named({'staffId': staffId.trim()}),
        );

        if (doctorRows.isNotEmpty) {
          final row = doctorRows.first.toColumnMap();
          final raw = row['email'];
          if (raw != null) doctorEmail = raw.toString();
        }
      }

      // Send emails - but don't fail the upload if email fails
      if (sendToPatient || sendToDoctor) {
        try {
          await _sendResultEmails(
            session,
            bookingId: trimmedBookingId,
            patientEmail: sendToPatient ? patientEmail : null,
            doctorEmail: sendToDoctor ? doctorEmail : null,
            attachmentPath: attachmentKey,
            attachmentFileName: attachmentFileName,
            attachmentContentType: attachmentContentType,
          );
        } catch (e, st) {
          // Log email error but don't fail the upload
          session.log(
            'uploadTestResult: email sending failed but result was saved: $e\n$st',
            level: LogLevel.warning,
          );
        }
      }

      session.log(
        'uploadTestResult: result stored for bookingId=$trimmedBookingId, status=$status',
        level: LogLevel.info,
      );
      return true;
    } on DatabaseQueryException catch (e) {
      session.log('uploadTestResult DB error: ${e.message}',
          level: LogLevel.error);
      return false;
    } catch (e, st) {
      session.log('uploadTestResult failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// Download the test result file for a specific booking.
  ///
  /// Returns a JSON string containing:
  /// {
  ///   "filename": "report.pdf",
  ///   "contentType": "application/pdf",
  ///   "data": "base64_encoded_content..."
  /// }
  /// Returns empty string if not found or error.
  Future<String> downloadTestResult(
    Session session,
    String bookingId,
  ) async {
    try {
      final trimmedBookingId = bookingId.trim();
      if (trimmedBookingId.isEmpty) return '';

      // Parse booking ID
      int? bookingPk;
      final bkMatch = RegExp(r'^BK(\d+)$', caseSensitive: false)
          .firstMatch(trimmedBookingId);
      if (bkMatch != null) {
        bookingPk = int.tryParse(bkMatch.group(1)!);
      } else {
        bookingPk = int.tryParse(trimmedBookingId);
      }

      if (bookingPk == null) return '';

      // Find the result path
      final rows = await session.db.unsafeQuery(
        '''
        SELECT tr.attachment_path
        FROM test_results tr
        JOIN booking_tests bt ON tr.booking_test_id = bt.booking_test_id
        WHERE bt.booking_id = @bookingId
        ORDER BY tr.updated_at DESC
        LIMIT 1
        ''',
        parameters: QueryParameters.named({'bookingId': bookingPk}),
      );

      if (rows.isEmpty) {
        session.log(
          'downloadTestResult: no result found for booking $bookingId',
          level: LogLevel.warning,
        );
        return '';
      }

      final path = rows.first.toColumnMap()['attachment_path']?.toString();
      if (path == null || path.isEmpty) return '';

      final file = File(path);
      if (!await file.exists()) {
        session.log(
          'downloadTestResult: file not found at $path',
          level: LogLevel.warning,
        );
        return '';
      }

      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);
      final filename = path.split('/').last;

      String contentType = 'application/octet-stream';
      if (filename.toLowerCase().endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (filename.toLowerCase().endsWith('.jpg')) {
        contentType = 'image/jpeg';
      } else if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      }

      return jsonEncode({
        'filename': filename,
        'contentType': contentType,
        'data': base64Data,
      });
    } catch (e, st) {
      session.log('downloadTestResult failed: $e\n$st', level: LogLevel.error);
      return '';
    }
  }
}

/// Sends lab test result emails to patient and doctor using the Resend API.
///
/// Configuration is read from environment variables (see `.env` in the
/// project root):
/// - `RESEND_API_KEY`        – required, your Resend API key
/// - `EMAIL_FROM_ADDRESS`    – required, verified sender address
Future<void> _sendResultEmails(
  Session session, {
  required String bookingId,
  String? patientEmail,
  String? doctorEmail,
  String? attachmentPath,
  String? attachmentFileName,
  String? attachmentContentType,
}) async {
  // Read configuration from environment.
  final apiKey = Platform.environment['RESEND_API_KEY'] ?? '';
  final fromAddress = Platform.environment['EMAIL_FROM_ADDRESS'] ?? '';
  final replyTo = Platform.environment['EMAIL_REPLY_TO'];
  final fromName = Platform.environment['EMAIL_FROM_NAME'] ?? 'Lab';
  final emailMode =
      Platform.environment['EMAIL_MODE']?.toLowerCase() ?? 'development';
  final devRecipient = Platform.environment['EMAIL_DEV_RECIPIENT'] ??
      'mahmudminhaj003@gmail.com';

  // Build initial recipient list
  final requestedRecipients = <String>[];
  if (patientEmail != null && patientEmail.trim().isNotEmpty) {
    requestedRecipients.add(patientEmail.trim());
  }
  if (doctorEmail != null && doctorEmail.trim().isNotEmpty) {
    final trimmedDoctor = doctorEmail.trim();
    if (!requestedRecipients.contains(trimmedDoctor)) {
      requestedRecipients.add(trimmedDoctor);
    }
  }

  if (requestedRecipients.isEmpty) {
    session.log(
      'sendResultEmails: no email recipients for bookingId=$bookingId',
      level: LogLevel.info,
    );
    return;
  }

  // Handle development mode - only send to dev recipient
  final List<String> recipients;
  if (emailMode == 'development') {
    // In development, check if any requested recipient is the dev recipient
    final hasDevRecipient = requestedRecipients.any(
      (email) => email.toLowerCase() == devRecipient.toLowerCase(),
    );

    if (hasDevRecipient) {
      // Send to dev recipient only
      recipients = [devRecipient];
      session.log(
        'sendResultEmails: [DEV MODE] Sending to $devRecipient only (requested: ${requestedRecipients.join(", ")})',
        level: LogLevel.info,
      );
    } else {
      // Skip sending - Resend would reject with 403
      session.log(
        'sendResultEmails: [DEV MODE] Skipping email - Resend only allows $devRecipient in development mode. '
        'Requested recipients: ${requestedRecipients.join(", ")}',
        level: LogLevel.warning,
      );
      return;
    }
  } else {
    // Production mode - send to all requested recipients
    recipients = requestedRecipients;
    session.log(
      'sendResultEmails: [PROD MODE] Sending to: ${recipients.join(", ")}',
      level: LogLevel.info,
    );
  }

  if (apiKey.isEmpty || apiKey == 'replace_with_resend_api_key') {
    session.log(
      'sendResultEmails: RESEND_API_KEY is not configured; cannot send email.',
      level: LogLevel.warning,
    );
    return;
  }

  if (fromAddress.isEmpty) {
    session.log(
      'sendResultEmails: EMAIL_FROM_ADDRESS is not configured; cannot send email.',
      level: LogLevel.warning,
    );
    return;
  }

  final uri = Uri.parse('https://api.resend.com/emails');
  final Map<String, dynamic> payload = {
    'from': '$fromName <$fromAddress>',
    'to': recipients,
    'subject': 'Lab Test Result - Booking $bookingId',
    'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #218085; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: #f9f9f9; padding: 30px; border: 1px solid #ddd; border-radius: 0 0 5px 5px; }
    .button { display: inline-block; background-color: #218085; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🧪 Lab Test Result Available</h1>
    </div>
    <div class="content">
      <p>Dear Patient/Doctor,</p>
      <p>Your lab test result for <strong>Booking ID: $bookingId</strong> is now ready and attached to this email.</p>
      <p>Please find the test report attached as a PDF document. Review the results and consult with your healthcare provider if you have any questions.</p>
      <p><strong>Important:</strong> Keep this report for your medical records.</p>
      <p>If you have any questions or concerns about your results, please don't hesitate to contact us.</p>
    </div>
    <div class="footer">
      <p>© ${DateTime.now().year} Dishari Medical Lab. All rights reserved.</p>
      <p>This is an automated message. Please do not reply to this email.</p>
    </div>
  </div>
</body>
</html>
''',
    'text':
        'Your lab test result for booking $bookingId is now available. Please review the attached report. If you have any questions, please contact us.',
  };

  // Add reply-to if configured
  if (replyTo != null && replyTo.trim().isNotEmpty) {
    payload['reply_to'] = replyTo.trim();
  }

  // If we have a stored attachment key, include the corresponding file as a
  // Resend attachment so that the patient / doctor receives the document.
  // The attachmentPath is the full relative path like 'uploaded_results/<bookingId>/<filename>'
  if (attachmentPath != null && attachmentPath.trim().isNotEmpty) {
    try {
      final fullPath = attachmentPath.trim();
      session.log(
        'sendResultEmails: attempting to attach file from path: $fullPath',
        level: LogLevel.info,
      );

      final file = File(fullPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final content = base64Encode(bytes);
        final name =
            (attachmentFileName == null || attachmentFileName.trim().isEmpty)
                ? 'lab_result_$bookingId.pdf'
                : attachmentFileName.trim();
        final mimeType = (attachmentContentType == null ||
                attachmentContentType.trim().isEmpty)
            ? 'application/pdf'
            : attachmentContentType.trim();

        payload['attachments'] = [
          {
            'filename': name,
            'content': content,
            'contentType': mimeType,
          },
        ];

        session.log(
          'sendResultEmails: ✓ Attachment added - filename: $name, size: ${bytes.length} bytes, type: $mimeType',
          level: LogLevel.info,
        );
      } else {
        session.log(
          'sendResultEmails: ⚠ Attachment file not found at $fullPath',
          level: LogLevel.warning,
        );
      }
    } catch (e, st) {
      session.log(
        'sendResultEmails: ✗ Failed to read attachment at $attachmentPath: $e\n$st',
        level: LogLevel.error,
      );
    }
  } else {
    session.log(
      'sendResultEmails: No attachment path provided for bookingId=$bookingId',
      level: LogLevel.info,
    );
  }

  final body = jsonEncode(payload);

  try {
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      session.log(
        'sendResultEmails: ✓ Email sent successfully for bookingId=$bookingId to ${recipients.join(", ")}',
        level: LogLevel.info,
      );
    } else if (response.statusCode == 403) {
      // Handle 403 Forbidden (e.g., development mode restriction)
      session.log(
        'sendResultEmails: ⚠ Email blocked (403 Forbidden) for bookingId=$bookingId. '
        'This is expected in Resend development mode. Recipients: ${recipients.join(", ")}. '
        'Response: ${response.body}',
        level: LogLevel.warning,
      );
    } else {
      session.log(
        'sendResultEmails: ✗ Failed to send email for bookingId=$bookingId. '
        'Status=${response.statusCode}, body=${response.body}',
        level: LogLevel.warning,
      );
    }
  } catch (e, st) {
    // Catch all exceptions to prevent upload failure
    session.log(
      'sendResultEmails: ✗ Exception while sending email for bookingId=$bookingId: $e\n$st',
      level: LogLevel.warning,
    );
  }
}
