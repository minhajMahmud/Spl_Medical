import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:uuid/uuid.dart';

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
}

//CReate lab test
