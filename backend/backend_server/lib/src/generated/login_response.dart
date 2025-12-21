/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class LoginResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LoginResponse._({
    required this.success,
    this.error,
    this.role,
    this.userId,
    this.userName,
    this.phone,
    this.bloodGroup,
    this.allergies,
    this.profilePictureUrl,
  });

  factory LoginResponse({
    required bool success,
    String? error,
    String? role,
    String? userId,
    String? userName,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? profilePictureUrl,
  }) = _LoginResponseImpl;

  factory LoginResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return LoginResponse(
      success: jsonSerialization['success'] as bool,
      error: jsonSerialization['error'] as String?,
      role: jsonSerialization['role'] as String?,
      userId: jsonSerialization['userId'] as String?,
      userName: jsonSerialization['userName'] as String?,
      phone: jsonSerialization['phone'] as String?,
      bloodGroup: jsonSerialization['bloodGroup'] as String?,
      allergies: jsonSerialization['allergies'] as String?,
      profilePictureUrl: jsonSerialization['profilePictureUrl'] as String?,
    );
  }

  bool success;

  String? error;

  String? role;

  String? userId;

  String? userName;

  String? phone;

  String? bloodGroup;

  String? allergies;

  String? profilePictureUrl;

  /// Returns a shallow copy of this [LoginResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LoginResponse copyWith({
    bool? success,
    String? error,
    String? role,
    String? userId,
    String? userName,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? profilePictureUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LoginResponse',
      'success': success,
      if (error != null) 'error': error,
      if (role != null) 'role': role,
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (phone != null) 'phone': phone,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (allergies != null) 'allergies': allergies,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LoginResponse',
      'success': success,
      if (error != null) 'error': error,
      if (role != null) 'role': role,
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (phone != null) 'phone': phone,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (allergies != null) 'allergies': allergies,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LoginResponseImpl extends LoginResponse {
  _LoginResponseImpl({
    required bool success,
    String? error,
    String? role,
    String? userId,
    String? userName,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? profilePictureUrl,
  }) : super._(
         success: success,
         error: error,
         role: role,
         userId: userId,
         userName: userName,
         phone: phone,
         bloodGroup: bloodGroup,
         allergies: allergies,
         profilePictureUrl: profilePictureUrl,
       );

  /// Returns a shallow copy of this [LoginResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LoginResponse copyWith({
    bool? success,
    Object? error = _Undefined,
    Object? role = _Undefined,
    Object? userId = _Undefined,
    Object? userName = _Undefined,
    Object? phone = _Undefined,
    Object? bloodGroup = _Undefined,
    Object? allergies = _Undefined,
    Object? profilePictureUrl = _Undefined,
  }) {
    return LoginResponse(
      success: success ?? this.success,
      error: error is String? ? error : this.error,
      role: role is String? ? role : this.role,
      userId: userId is String? ? userId : this.userId,
      userName: userName is String? ? userName : this.userName,
      phone: phone is String? ? phone : this.phone,
      bloodGroup: bloodGroup is String? ? bloodGroup : this.bloodGroup,
      allergies: allergies is String? ? allergies : this.allergies,
      profilePictureUrl: profilePictureUrl is String?
          ? profilePictureUrl
          : this.profilePictureUrl,
    );
  }
}
