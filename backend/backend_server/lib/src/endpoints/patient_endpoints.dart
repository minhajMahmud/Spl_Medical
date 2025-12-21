import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';

class PatientEndpoint extends Endpoint {
  // Fetch patient profile
  Future<PatientProfileDto?> getPatientProfile(Session session, String userId) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
        SELECT u.name, u.email, u.phone, u.profile_picture_url, p.blood_group, p.allergies
        FROM users u
        LEFT JOIN patient_profiles p ON p.user_id = u.user_id
        WHERE u.email = @email
        ''',
        parameters: QueryParameters.named({'email': userId}),
      );

      if (result.isEmpty) return null;

      final row = result.first.toColumnMap();

      return PatientProfileDto(
        name: _safeString(row['name']),
        email: _safeString(row['email']),
        phone: _safeString(row['phone']),
        bloodGroup: _safeString(row['blood_group']),
        allergies: _safeString(row['allergies']),
        profilePictureUrl: _safeString(row['profile_picture_url']), // base64
      );
    } catch (e, stack) {
      session.log('Error getting patient profile: $e\n$stack', level: LogLevel.error);
      return null;
    }
  }

  // Update patient profile
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
        WHERE email = @email
        ''',
        parameters: QueryParameters.named({
          'email': userId,
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
          (SELECT user_id FROM users WHERE email = @email),
          COALESCE((SELECT blood_group FROM patient_profiles WHERE user_id = (SELECT user_id FROM users WHERE email = @email)), ''),
          @allergies
        )
        ON CONFLICT (user_id) 
        DO UPDATE SET allergies = @allergies
        ''',
        parameters: QueryParameters.named({
          'email': userId,
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
    if (value is List<int>) return String.fromCharCodes(value);
    return value.toString();
  }
}
