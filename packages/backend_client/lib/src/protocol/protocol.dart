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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'greeting.dart' as _i2;
import 'lab_test_info.dart' as _i3;
import 'login_response.dart' as _i4;
import 'patient_reponse.dart' as _i5;
import 'test_booking_dto.dart' as _i6;
import 'user_list_item.dart' as _i7;
import 'package:backend_client/src/protocol/user_list_item.dart' as _i8;
import 'package:backend_client/src/protocol/lab_test_info.dart' as _i9;
import 'package:backend_client/src/protocol/test_booking_dto.dart' as _i10;
export 'greeting.dart';
export 'lab_test_info.dart';
export 'login_response.dart';
export 'patient_reponse.dart';
export 'test_booking_dto.dart';
export 'user_list_item.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

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

    if (t == _i2.Greeting) {
      return _i2.Greeting.fromJson(data) as T;
    }
    if (t == _i3.LabTestInfo) {
      return _i3.LabTestInfo.fromJson(data) as T;
    }
    if (t == _i4.LoginResponse) {
      return _i4.LoginResponse.fromJson(data) as T;
    }
    if (t == _i5.PatientProfileDto) {
      return _i5.PatientProfileDto.fromJson(data) as T;
    }
    if (t == _i6.TestBookingDto) {
      return _i6.TestBookingDto.fromJson(data) as T;
    }
    if (t == _i7.UserListItem) {
      return _i7.UserListItem.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Greeting?>()) {
      return (data != null ? _i2.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.LabTestInfo?>()) {
      return (data != null ? _i3.LabTestInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.LoginResponse?>()) {
      return (data != null ? _i4.LoginResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.PatientProfileDto?>()) {
      return (data != null ? _i5.PatientProfileDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.TestBookingDto?>()) {
      return (data != null ? _i6.TestBookingDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.UserListItem?>()) {
      return (data != null ? _i7.UserListItem.fromJson(data) : null) as T;
    }
    if (t == List<_i8.UserListItem>) {
      return (data as List)
              .map((e) => deserialize<_i8.UserListItem>(e))
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
    if (t == List<_i9.LabTestInfo>) {
      return (data as List).map((e) => deserialize<_i9.LabTestInfo>(e)).toList()
          as T;
    }
    if (t == List<_i10.TestBookingDto>) {
      return (data as List)
              .map((e) => deserialize<_i10.TestBookingDto>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Greeting => 'Greeting',
      _i3.LabTestInfo => 'LabTestInfo',
      _i4.LoginResponse => 'LoginResponse',
      _i5.PatientProfileDto => 'PatientProfileDto',
      _i6.TestBookingDto => 'TestBookingDto',
      _i7.UserListItem => 'UserListItem',
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
      case _i2.Greeting():
        return 'Greeting';
      case _i3.LabTestInfo():
        return 'LabTestInfo';
      case _i4.LoginResponse():
        return 'LoginResponse';
      case _i5.PatientProfileDto():
        return 'PatientProfileDto';
      case _i6.TestBookingDto():
        return 'TestBookingDto';
      case _i7.UserListItem():
        return 'UserListItem';
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
      return deserialize<_i2.Greeting>(data['data']);
    }
    if (dataClassName == 'LabTestInfo') {
      return deserialize<_i3.LabTestInfo>(data['data']);
    }
    if (dataClassName == 'LoginResponse') {
      return deserialize<_i4.LoginResponse>(data['data']);
    }
    if (dataClassName == 'PatientProfileDto') {
      return deserialize<_i5.PatientProfileDto>(data['data']);
    }
    if (dataClassName == 'TestBookingDto') {
      return deserialize<_i6.TestBookingDto>(data['data']);
    }
    if (dataClassName == 'UserListItem') {
      return deserialize<_i7.UserListItem>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
