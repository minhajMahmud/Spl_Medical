import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';

class PatientEndpoint extends Endpoint {
  // Fetch patient profile by either email OR user_id.
  // The incoming `userId` is treated as a generic identifier.
  Future<PatientProfileDto?> getPatientProfile(
      Session session, String userId) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
        SELECT u.name::text as name, 
               u.email::text as email, 
               u.phone::text as phone, 
               u.role::text as role, 
               p.blood_group::text as blood_group, 
               p.allergies::text as allergies
        FROM users u
        LEFT JOIN patient_profiles p ON p.user_id = u.user_id
        WHERE u.email = @id 
           OR u.user_id::text = @id 
           OR u.phone = @id
           OR u.phone LIKE '%' || @id || '%'
        ''',
        parameters: QueryParameters.named({'id': userId}),
      );

      if (result.isEmpty) return null;

      final row = result.first.toColumnMap();

      return PatientProfileDto(
        name: _safeString(row['name']),
        email: _safeString(row['email']),
        phone: _safeString(row['phone']),
        bloodGroup: _safeString(row['blood_group']),
        allergies: _safeString(row['allergies']),
        profilePictureUrl: '', // Not stored in current schema
        role: _safeString(row['role']),
      );
    } catch (e, stack) {
      session.log('Error getting patient profile: $e\n$stack',
          level: LogLevel.error);
      return null;
    }
  }

  // Update patient profile using either email OR user_id as identifier.
  Future<String> updatePatientProfile(
    Session session,
    String userId,
    String name,
    String phone,
    String allergies,
    String? profilePictureData,
  ) async {
    try {
      await session.db.unsafeExecute('BEGIN');

      String? profilePictureUrl;

      // Handle small images (≤50 KB)
      if (profilePictureData != null && profilePictureData.isNotEmpty) {
        if (profilePictureData.length <= 50 * 1024) {
          profilePictureUrl = profilePictureData; // store base64
        } else {
          throw Exception('Image too large. Max 50 KB allowed.');
        }
      }

      // Update users table
      await session.db.unsafeExecute(
        '''
        UPDATE users 
        SET name = @name, phone = @phone,
    		    profile_picture_url = COALESCE(@profilePictureUrl, profile_picture_url)
    		WHERE email = @id OR user_id::text = @id
        ''',
        parameters: QueryParameters.named({
          'id': userId,
          'name': name,
          'phone': phone,
          'profilePictureUrl': profilePictureUrl,
        }),
      );

      // Update or insert into patient_profiles
      await session.db.unsafeExecute(
        '''
        INSERT INTO patient_profiles (user_id, blood_group, allergies)
    VALUES (
      (SELECT user_id FROM users WHERE email = @id OR user_id::text = @id),
      COALESCE((
        SELECT blood_group
        FROM patient_profiles
        WHERE user_id = (
          SELECT user_id FROM users WHERE email = @id OR user_id::text = @id
        )
      ), ''),
      @allergies
    )
        ON CONFLICT (user_id) 
        DO UPDATE SET allergies = @allergies
        ''',
        parameters: QueryParameters.named({
          'id': userId,
          'allergies': allergies,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return 'Profile updated successfully';
    } catch (e, stack) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('Update profile failed: $e\n$stack', level: LogLevel.error);
      return 'Failed to update profile: $e';
    }
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;

    // Handle List<int> and UndecodedBytes
    try {
      if (value is List) {
        final bytes = List<int>.from(value);
        return String.fromCharCodes(bytes);
      }
    } catch (_) {
      // Continue to other attempts
    }

    // Try to access underlying bytes if it has a 'bytes' property
    try {
      final valueStr = value.toString();
      if (valueStr.contains('UndecodedBytes')) {
        // Try reflection-style access
        final dynamic obj = value;
        if (obj.bytes != null) {
          return String.fromCharCodes(List<int>.from(obj.bytes));
        }
      }
    } catch (_) {
      // Continue to fallback
    }

    return value.toString();
  }
}
