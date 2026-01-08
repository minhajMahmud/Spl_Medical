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
import 'package:serverpod/protocol.dart' as _i2;
import 'greeting.dart' as _i3;
import 'lab_test_info.dart' as _i4;
import 'login_response.dart' as _i5;
import 'patient_reponse.dart' as _i6;
import 'test_booking_dto.dart' as _i7;
import 'user_list_item.dart' as _i8;
import 'package:backend_server/src/generated/user_list_item.dart' as _i9;
import 'package:backend_server/src/generated/lab_test_info.dart' as _i10;
import 'package:backend_server/src/generated/test_booking_dto.dart' as _i11;
export 'greeting.dart';
export 'lab_test_info.dart';
export 'login_response.dart';
export 'patient_reponse.dart';
export 'test_booking_dto.dart';
export 'user_list_item.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i3.Greeting) {
      return _i3.Greeting.fromJson(data) as T;
    }
    if (t == _i4.LabTestInfo) {
      return _i4.LabTestInfo.fromJson(data) as T;
    }
    if (t == _i5.LoginResponse) {
      return _i5.LoginResponse.fromJson(data) as T;
    }
    if (t == _i6.PatientProfileDto) {
      return _i6.PatientProfileDto.fromJson(data) as T;
    }
    if (t == _i7.TestBookingDto) {
      return _i7.TestBookingDto.fromJson(data) as T;
    }
    if (t == _i8.UserListItem) {
      return _i8.UserListItem.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.Greeting?>()) {
      return (data != null ? _i3.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.LabTestInfo?>()) {
      return (data != null ? _i4.LabTestInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.LoginResponse?>()) {
      return (data != null ? _i5.LoginResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.PatientProfileDto?>()) {
      return (data != null ? _i6.PatientProfileDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.TestBookingDto?>()) {
      return (data != null ? _i7.TestBookingDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.UserListItem?>()) {
      return (data != null ? _i8.UserListItem.fromJson(data) : null) as T;
    }
    if (t == List<_i9.UserListItem>) {
      return (data as List)
              .map((e) => deserialize<_i9.UserListItem>(e))
              .toList()
          as T;
    }
    if (t == List<Map<String, dynamic>>) {
      return (data as List)
              .map((e) => deserialize<Map<String, dynamic>>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_i10.LabTestInfo>) {
      return (data as List)
              .map((e) => deserialize<_i10.LabTestInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i11.TestBookingDto>) {
      return (data as List)
              .map((e) => deserialize<_i11.TestBookingDto>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.Greeting => 'Greeting',
      _i4.LabTestInfo => 'LabTestInfo',
      _i5.LoginResponse => 'LoginResponse',
      _i6.PatientProfileDto => 'PatientProfileDto',
      _i7.TestBookingDto => 'TestBookingDto',
      _i8.UserListItem => 'UserListItem',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('backend.', '');
    }

    switch (data) {
      case _i3.Greeting():
        return 'Greeting';
      case _i4.LabTestInfo():
        return 'LabTestInfo';
      case _i5.LoginResponse():
        return 'LoginResponse';
      case _i6.PatientProfileDto():
        return 'PatientProfileDto';
      case _i7.TestBookingDto():
        return 'TestBookingDto';
      case _i8.UserListItem():
        return 'UserListItem';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i3.Greeting>(data['data']);
    }
    if (dataClassName == 'LabTestInfo') {
      return deserialize<_i4.LabTestInfo>(data['data']);
    }
    if (dataClassName == 'LoginResponse') {
      return deserialize<_i5.LoginResponse>(data['data']);
    }
    if (dataClassName == 'PatientProfileDto') {
      return deserialize<_i6.PatientProfileDto>(data['data']);
    }
    if (dataClassName == 'TestBookingDto') {
      return deserialize<_i7.TestBookingDto>(data['data']);
    }
    if (dataClassName == 'UserListItem') {
      return deserialize<_i8.UserListItem>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'backend';
}
