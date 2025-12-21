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

abstract class PatientProfileDto
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PatientProfileDto._({
    required this.name,
    required this.email,
    required this.phone,
    required this.bloodGroup,
    required this.allergies,
    this.profilePictureUrl,
  });

  factory PatientProfileDto({
    required String name,
    required String email,
    required String phone,
    required String bloodGroup,
    required String allergies,
    String? profilePictureUrl,
  }) = _PatientProfileDtoImpl;

  factory PatientProfileDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return PatientProfileDto(
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      phone: jsonSerialization['phone'] as String,
      bloodGroup: jsonSerialization['bloodGroup'] as String,
      allergies: jsonSerialization['allergies'] as String,
      profilePictureUrl: jsonSerialization['profilePictureUrl'] as String?,
    );
  }

  String name;

  String email;

  String phone;

  String bloodGroup;

  String allergies;

  String? profilePictureUrl;

  /// Returns a shallow copy of this [PatientProfileDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatientProfileDto copyWith({
    String? name,
    String? email,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? profilePictureUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatientProfileDto',
      'name': name,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatientProfileDto',
      'name': name,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PatientProfileDtoImpl extends PatientProfileDto {
  _PatientProfileDtoImpl({
    required String name,
    required String email,
    required String phone,
    required String bloodGroup,
    required String allergies,
    String? profilePictureUrl,
  }) : super._(
         name: name,
         email: email,
         phone: phone,
         bloodGroup: bloodGroup,
         allergies: allergies,
         profilePictureUrl: profilePictureUrl,
       );

  /// Returns a shallow copy of this [PatientProfileDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatientProfileDto copyWith({
    String? name,
    String? email,
    String? phone,
    String? bloodGroup,
    String? allergies,
    Object? profilePictureUrl = _Undefined,
  }) {
    return PatientProfileDto(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      profilePictureUrl: profilePictureUrl is String?
          ? profilePictureUrl
          : this.profilePictureUrl,
    );
  }
}
