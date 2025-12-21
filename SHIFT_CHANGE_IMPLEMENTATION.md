# Shift Change Request Implementation Guide

## Overview

You want to:

1. **View your schedule** from the database ✅ (Already working with `getRosters`)
2. **Submit change requests** for shifts (New feature)
3. **View request status** (PENDING/APPROVED/REJECTED)
4. **Admin can approve/reject** requests

## Database Schema (Already Created)

```sql
-- Enum for request status
CREATE TYPE request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- Shift change requests table
CREATE TABLE shift_change_requests (
  request_id SERIAL PRIMARY KEY,
  roster_id VARCHAR(20) REFERENCES rosters(roster_id),
  staff_id VARCHAR(20) REFERENCES staff_profiles(user_id),
  reason TEXT,
  request_date TIMESTAMP DEFAULT NOW(),
  status request_status DEFAULT 'PENDING'
);
```

## Backend Methods to Add

Add these methods to `admin_endpoints.dart` after the `saveRoster` method:

```dart
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
      return {'success': false, 'message': 'Unauthorized: roster does not belong to you'};
    }

    // Check if there's already a pending request for this roster
    final existingRequest = await session.db.unsafeQuery('''
      SELECT request_id FROM shift_change_requests
      WHERE roster_id = @rid AND status = 'PENDING'
    ''', parameters: QueryParameters.named({'rid': rosterId}));

    if (existingRequest.isNotEmpty) {
      return {'success': false, 'message': 'A pending request already exists for this shift'};
    }

    // Insert the change request
    final result = await session.db.unsafeQuery('''
      INSERT INTO shift_change_requests (roster_id, staff_id, reason)
      VALUES (@rid, @sid, @reason)
      RETURNING request_id
    ''', parameters: QueryParameters.named({
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
    session.log('getAllChangeRequests failed: $e\n$st', level: LogLevel.error);
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
    ''', parameters: QueryParameters.named({
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
```

## Update \_initRostersTable

Add the shift_change_requests table creation:

```dart
// Add to _initRostersTable method after creating rosters table:

// 3️⃣ Create shift change requests table and enum
await session.db.unsafeExecute(r'''
  DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_status') THEN
      CREATE TYPE request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
    END IF;
  END
  $$;
''');

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
```

## Frontend Implementation (change_request_rostering.dart)

### Update UI to Add "Request Change" Button

```dart
// Add to each schedule card in the My Schedule tab:

Widget _buildScheduleCard(Map<String, dynamic> schedule) {
  final rosterId = schedule['rosterId'] ?? '';
  final shiftType = schedule['shiftType'] ?? '';
  final shiftDate = schedule['shiftDate'] ?? '';
  final timeRange = schedule['timeRange'] ?? '';
  final status = schedule['status'] ?? '';

  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                shiftType,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Chip(
                label: Text(status),
                backgroundColor: status == 'CONFIRMED'
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('Date: $shiftDate'),
          Text('Time: $timeRange'),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showChangeRequestDialog(rosterId, shiftDate, shiftType),
            icon: Icon(Icons.edit),
            label: Text('Request Change'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Add Dialog to Submit Request

```dart
Future<void> _showChangeRequestDialog(
  String rosterId,
  String shiftDate,
  String shiftType,
) async {
  final reasonController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Request Schedule Change'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shift: $shiftType on $shiftDate'),
          SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: 'Reason for change',
              border: OutlineInputBorder(),
              hintText: 'e.g., Medical appointment, family emergency',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter a reason')),
              );
              return;
            }

            Navigator.pop(context);
            await _submitChangeRequest(rosterId, reasonController.text.trim());
          },
          child: Text('Submit Request'),
        ),
      ],
    ),
  );
}
```

### Add Submit Method

```dart
Future<void> _submitChangeRequest(String rosterId, String reason) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    final result = await client.adminEndpoints.submitChangeRequest(
      rosterId: rosterId,
      staffId: userId,
      reason: reason,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload requests
      _loadMyRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Load My Requests

```dart
Future<void> _loadMyRequests() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    final requests = await client.adminEndpoints.getMyChangeRequests(userId);

    setState(() {
      _myRequests = requests;
      _isLoadingRequests = false;
    });
  } catch (e) {
    print('Error loading requests: $e');
    setState(() {
      _isLoadingRequests = false;
      _errorLoadingRequests = true;
    });
  }
}
```

### Display My Requests Tab

```dart
Widget _buildRequestCard(Map<String, dynamic> request) {
  final requestId = request['requestId'] ?? '';
  final shiftType = request['shiftType'] ?? '';
  final shiftDate = request['shiftDate'] ?? '';
  final reason = request['reason'] ?? '';
  final status = request['status'] ?? '';
  final requestDate = request['requestDate'] ?? '';

  Color statusColor;
  IconData statusIcon;

  switch (status) {
    case 'APPROVED':
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      break;
    case 'REJECTED':
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      break;
    default: // PENDING
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
  }

  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Spacer(),
              Text(
                'Request #$requestId',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          Divider(),
          Text('Shift: $shiftType', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Date: $shiftDate'),
          SizedBox(height: 8),
          Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(reason),
          SizedBox(height: 8),
          Text(
            'Requested: ${_formatDateTime(requestDate)}',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

String _formatDateTime(String dateTimeStr) {
  try {
    final dt = DateTime.parse(dateTimeStr);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return dateTimeStr;
  }
}
```

## Step-by-Step Implementation

### Step 1: Update Database Initialization

Add the shift_change_requests table creation to `_initRostersTable` method in admin_endpoints.dart

### Step 2: Add Backend Methods

Copy all 4 new methods to admin_endpoints.dart:

- `submitChangeRequest`
- `getMyChangeRequests`
- `getAllChangeRequests`
- `updateRequestStatus`

### Step 3: Regenerate Backend Code

```bash
cd backend/backend_server
serverpod generate
```

### Step 4: Update Flutter Client

```bash
cd ../../
flutter pub get
```

### Step 5: Update change_request_rostering.dart

Add:

- Request change button to schedule cards
- Dialog to input reason
- Submit method
- Load and display requests in "My Requests" tab

### Step 6: Test the Flow

1. View your schedule (already working)
2. Click "Request Change" on a shift
3. Enter reason and submit
4. View status in "My Requests" tab
5. Admin approves/rejects from admin panel
6. Status updates to APPROVED/REJECTED

## Database Queries Summary

**View Schedules (Already Working):**

```sql
SELECT * FROM rosters
WHERE staff_id = 'lab@gmail.com'
  AND approved_by = 'admin@gmail.com'
  AND status = 'SCHEDULED'
ORDER BY shift_date;
```

**Submit Change Request:**

```sql
INSERT INTO shift_change_requests (roster_id, staff_id, reason)
VALUES ('ROS-104', 'lab@gmail.com', 'Medical appointment')
RETURNING request_id;
```

**View My Requests:**

```sql
SELECT scr.*, r.shift_type, r.shift_date, r.shift_time_range
FROM shift_change_requests scr
JOIN rosters r ON r.roster_id = scr.roster_id
WHERE scr.staff_id = 'lab@gmail.com'
ORDER BY scr.request_date DESC;
```

**Admin Approves Request:**

```sql
-- Update request status
UPDATE shift_change_requests
SET status = 'APPROVED'
WHERE request_id = 1;

-- Update roster status to CONFIRMED
UPDATE rosters
SET status = 'CONFIRMED'
WHERE roster_id = 'ROS-104';
```

## Result

- ✅ Staff can view their scheduled shifts
- ✅ Staff can request changes with a reason
- ✅ Staff can see status of their requests (PENDING/APPROVED/REJECTED)
- ✅ Admin can view all requests
- ✅ Admin can approve/reject requests
- ✅ When approved, roster status changes to CONFIRMED
