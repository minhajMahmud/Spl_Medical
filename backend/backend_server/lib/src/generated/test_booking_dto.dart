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

abstract class TestBookingDto
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TestBookingDto._({
    required this.bookingId,
    this.patientId,
    required this.testId,
    required this.bookingDate,
    required this.isExternalPatient,
    required this.patientType,
    required this.status,
    this.patientName,
    this.patientEmail,
    this.patientPhone,
    required this.testName,
    required this.outsideFee,
  });

  factory TestBookingDto({
    required String bookingId,
    String? patientId,
    required int testId,
    required String bookingDate,
    required bool isExternalPatient,
    required String patientType,
    required String status,
    String? patientName,
    String? patientEmail,
    String? patientPhone,
    required String testName,
    required double outsideFee,
  }) = _TestBookingDtoImpl;

  factory TestBookingDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return TestBookingDto(
      bookingId: jsonSerialization['bookingId'] as String,
      patientId: jsonSerialization['patientId'] as String?,
      testId: jsonSerialization['testId'] as int,
      bookingDate: jsonSerialization['bookingDate'] as String,
      isExternalPatient: jsonSerialization['isExternalPatient'] as bool,
      patientType: jsonSerialization['patientType'] as String,
      status: jsonSerialization['status'] as String,
      patientName: jsonSerialization['patientName'] as String?,
      patientEmail: jsonSerialization['patientEmail'] as String?,
      patientPhone: jsonSerialization['patientPhone'] as String?,
      testName: jsonSerialization['testName'] as String,
      outsideFee: (jsonSerialization['outsideFee'] as num).toDouble(),
    );
  }

  String bookingId;

  String? patientId;

  int testId;

  String bookingDate;

  bool isExternalPatient;

  String patientType;

  String status;

  String? patientName;

  String? patientEmail;

  String? patientPhone;

  String testName;

  double outsideFee;

  /// Returns a shallow copy of this [TestBookingDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TestBookingDto copyWith({
    String? bookingId,
    String? patientId,
    int? testId,
    String? bookingDate,
    bool? isExternalPatient,
    String? patientType,
    String? status,
    String? patientName,
    String? patientEmail,
    String? patientPhone,
    String? testName,
    double? outsideFee,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TestBookingDto',
      'bookingId': bookingId,
      if (patientId != null) 'patientId': patientId,
      'testId': testId,
      'bookingDate': bookingDate,
      'isExternalPatient': isExternalPatient,
      'patientType': patientType,
      'status': status,
      if (patientName != null) 'patientName': patientName,
      if (patientEmail != null) 'patientEmail': patientEmail,
      if (patientPhone != null) 'patientPhone': patientPhone,
      'testName': testName,
      'outsideFee': outsideFee,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TestBookingDto',
      'bookingId': bookingId,
      if (patientId != null) 'patientId': patientId,
      'testId': testId,
      'bookingDate': bookingDate,
      'isExternalPatient': isExternalPatient,
      'patientType': patientType,
      'status': status,
      if (patientName != null) 'patientName': patientName,
      if (patientEmail != null) 'patientEmail': patientEmail,
      if (patientPhone != null) 'patientPhone': patientPhone,
      'testName': testName,
      'outsideFee': outsideFee,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TestBookingDtoImpl extends TestBookingDto {
  _TestBookingDtoImpl({
    required String bookingId,
    String? patientId,
    required int testId,
    required String bookingDate,
    required bool isExternalPatient,
    required String patientType,
    required String status,
    String? patientName,
    String? patientEmail,
    String? patientPhone,
    required String testName,
    required double outsideFee,
  }) : super._(
         bookingId: bookingId,
         patientId: patientId,
         testId: testId,
         bookingDate: bookingDate,
         isExternalPatient: isExternalPatient,
         patientType: patientType,
         status: status,
         patientName: patientName,
         patientEmail: patientEmail,
         patientPhone: patientPhone,
         testName: testName,
         outsideFee: outsideFee,
       );

  /// Returns a shallow copy of this [TestBookingDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TestBookingDto copyWith({
    String? bookingId,
    Object? patientId = _Undefined,
    int? testId,
    String? bookingDate,
    bool? isExternalPatient,
    String? patientType,
    String? status,
    Object? patientName = _Undefined,
    Object? patientEmail = _Undefined,
    Object? patientPhone = _Undefined,
    String? testName,
    double? outsideFee,
  }) {
    return TestBookingDto(
      bookingId: bookingId ?? this.bookingId,
      patientId: patientId is String? ? patientId : this.patientId,
      testId: testId ?? this.testId,
      bookingDate: bookingDate ?? this.bookingDate,
      isExternalPatient: isExternalPatient ?? this.isExternalPatient,
      patientType: patientType ?? this.patientType,
      status: status ?? this.status,
      patientName: patientName is String? ? patientName : this.patientName,
      patientEmail: patientEmail is String? ? patientEmail : this.patientEmail,
      patientPhone: patientPhone is String? ? patientPhone : this.patientPhone,
      testName: testName ?? this.testName,
      outsideFee: outsideFee ?? this.outsideFee,
    );
  }
}
