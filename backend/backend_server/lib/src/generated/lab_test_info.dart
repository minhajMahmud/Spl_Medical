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

abstract class LabTestInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LabTestInfo._({
    required this.testId,
    required this.testName,
    this.description,
    required this.studentFee,
    required this.staffFee,
    required this.outsideFee,
    required this.available,
  });

  factory LabTestInfo({
    required int testId,
    required String testName,
    String? description,
    required double studentFee,
    required double staffFee,
    required double outsideFee,
    required bool available,
  }) = _LabTestInfoImpl;

  factory LabTestInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return LabTestInfo(
      testId: jsonSerialization['testId'] as int,
      testName: jsonSerialization['testName'] as String,
      description: jsonSerialization['description'] as String?,
      studentFee: (jsonSerialization['studentFee'] as num).toDouble(),
      staffFee: (jsonSerialization['staffFee'] as num).toDouble(),
      outsideFee: (jsonSerialization['outsideFee'] as num).toDouble(),
      available: jsonSerialization['available'] as bool,
    );
  }

  int testId;

  String testName;

  String? description;

  double studentFee;

  double staffFee;

  double outsideFee;

  bool available;

  /// Returns a shallow copy of this [LabTestInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LabTestInfo copyWith({
    int? testId,
    String? testName,
    String? description,
    double? studentFee,
    double? staffFee,
    double? outsideFee,
    bool? available,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LabTestInfo',
      'testId': testId,
      'testName': testName,
      if (description != null) 'description': description,
      'studentFee': studentFee,
      'staffFee': staffFee,
      'outsideFee': outsideFee,
      'available': available,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LabTestInfo',
      'testId': testId,
      'testName': testName,
      if (description != null) 'description': description,
      'studentFee': studentFee,
      'staffFee': staffFee,
      'outsideFee': outsideFee,
      'available': available,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LabTestInfoImpl extends LabTestInfo {
  _LabTestInfoImpl({
    required int testId,
    required String testName,
    String? description,
    required double studentFee,
    required double staffFee,
    required double outsideFee,
    required bool available,
  }) : super._(
         testId: testId,
         testName: testName,
         description: description,
         studentFee: studentFee,
         staffFee: staffFee,
         outsideFee: outsideFee,
         available: available,
       );

  /// Returns a shallow copy of this [LabTestInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LabTestInfo copyWith({
    int? testId,
    String? testName,
    Object? description = _Undefined,
    double? studentFee,
    double? staffFee,
    double? outsideFee,
    bool? available,
  }) {
    return LabTestInfo(
      testId: testId ?? this.testId,
      testName: testName ?? this.testName,
      description: description is String? ? description : this.description,
      studentFee: studentFee ?? this.studentFee,
      staffFee: staffFee ?? this.staffFee,
      outsideFee: outsideFee ?? this.outsideFee,
      available: available ?? this.available,
    );
  }
}
