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
import '../endpoints/admin_endpoints.dart' as _i2;
import '../endpoints/lab_endpoints.dart' as _i3;
import '../endpoints/patient_endpoints.dart' as _i4;
import '../greeting_endpoint.dart' as _i5;
import 'package:uuid/uuid.dart' as _i6;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'adminEndpoints': _i2.AdminEndpoints()
        ..initialize(
          server,
          'adminEndpoints',
          null,
        ),
      'profile': _i3.ProfileEndpoint()
        ..initialize(
          server,
          'profile',
          null,
        ),
      'patient': _i4.PatientEndpoint()
        ..initialize(
          server,
          'patient',
          null,
        ),
      'greeting': _i5.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['adminEndpoints'] = _i1.EndpointConnector(
      name: 'adminEndpoints',
      endpoint: endpoints['adminEndpoints']!,
      methodConnectors: {
        'listUsersByRole': _i1.MethodConnector(
          name: 'listUsersByRole',
          params: {
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .listUsersByRole(
                    session,
                    params['role'],
                    params['limit'],
                  ),
        ),
        'toggleUserActive': _i1.MethodConnector(
          name: 'toggleUserActive',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .toggleUserActive(
                    session,
                    params['userId'],
                  ),
        ),
        'createUser': _i1.MethodConnector(
          name: 'createUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'passwordHash': _i1.ParameterDescription(
              name: 'passwordHash',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .createUser(
                    session,
                    params['userId'],
                    params['name'],
                    params['email'],
                    params['passwordHash'],
                    params['role'],
                    params['phone'],
                  ),
        ),
        'createUserWithPassword': _i1.MethodConnector(
          name: 'createUserWithPassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .createUserWithPassword(
                    session,
                    params['userId'],
                    params['name'],
                    params['email'],
                    params['password'],
                    params['role'],
                    params['phone'],
                  ),
        ),
        'listMedicines': _i1.MethodConnector(
          name: 'listMedicines',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .listMedicines(session),
        ),
        'addMedicine': _i1.MethodConnector(
          name: 'addMedicine',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'minimumStock': _i1.ParameterDescription(
              name: 'minimumStock',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .addMedicine(
                    session,
                    params['name'],
                    params['minimumStock'],
                  ),
        ),
        'addMedicineBatch': _i1.MethodConnector(
          name: 'addMedicineBatch',
          params: {
            'medicineId': _i1.ParameterDescription(
              name: 'medicineId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'batchId': _i1.ParameterDescription(
              name: 'batchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'stock': _i1.ParameterDescription(
              name: 'stock',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'expiry': _i1.ParameterDescription(
              name: 'expiry',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .addMedicineBatch(
                    session,
                    params['medicineId'],
                    params['batchId'],
                    params['stock'],
                    params['expiry'],
                  ),
        ),
        'getMedicineBatches': _i1.MethodConnector(
          name: 'getMedicineBatches',
          params: {
            'medicineId': _i1.ParameterDescription(
              name: 'medicineId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getMedicineBatches(
                    session,
                    params['medicineId'],
                  ),
        ),
        'getLowStockItems': _i1.MethodConnector(
          name: 'getLowStockItems',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getLowStockItems(session),
        ),
        'getRosters': _i1.MethodConnector(
          name: 'getRosters',
          params: {
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'fromDate': _i1.ParameterDescription(
              name: 'fromDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
            'toDate': _i1.ParameterDescription(
              name: 'toDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getRosters(
                    session,
                    staffId: params['staffId'],
                    fromDate: params['fromDate'],
                    toDate: params['toDate'],
                  ),
        ),
        'saveRoster': _i1.MethodConnector(
          name: 'saveRoster',
          params: {
            'rosterId': _i1.ParameterDescription(
              name: 'rosterId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'shiftType': _i1.ParameterDescription(
              name: 'shiftType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'shiftDate': _i1.ParameterDescription(
              name: 'shiftDate',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'timeRange': _i1.ParameterDescription(
              name: 'timeRange',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'approvedBy': _i1.ParameterDescription(
              name: 'approvedBy',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .saveRoster(
                    session,
                    rosterId: params['rosterId'],
                    staffId: params['staffId'],
                    shiftType: params['shiftType'],
                    shiftDate: params['shiftDate'],
                    timeRange: params['timeRange'],
                    status: params['status'],
                    approvedBy: params['approvedBy'],
                  ),
        ),
        'submitChangeRequest': _i1.MethodConnector(
          name: 'submitChangeRequest',
          params: {
            'rosterId': _i1.ParameterDescription(
              name: 'rosterId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .submitChangeRequest(
                    session,
                    rosterId: params['rosterId'],
                    staffId: params['staffId'],
                    reason: params['reason'],
                  ),
        ),
        'getMyChangeRequests': _i1.MethodConnector(
          name: 'getMyChangeRequests',
          params: {
            'staffId': _i1.ParameterDescription(
              name: 'staffId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getMyChangeRequests(
                    session,
                    params['staffId'],
                  ),
        ),
        'getAllChangeRequests': _i1.MethodConnector(
          name: 'getAllChangeRequests',
          params: {
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getAllChangeRequests(
                    session,
                    status: params['status'],
                  ),
        ),
        'updateRequestStatus': _i1.MethodConnector(
          name: 'updateRequestStatus',
          params: {
            'requestId': _i1.ParameterDescription(
              name: 'requestId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .updateRequestStatus(
                    session,
                    requestId: params['requestId'],
                    status: params['status'],
                  ),
        ),
        'addAuditLog': _i1.MethodConnector(
          name: 'addAuditLog',
          params: {
            'logId': _i1.ParameterDescription(
              name: 'logId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'action': _i1.ParameterDescription(
              name: 'action',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .addAuditLog(
                    session,
                    params['logId'],
                    params['userId'],
                    params['action'],
                  ),
        ),
        'getAuditLogs': _i1.MethodConnector(
          name: 'getAuditLogs',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getAuditLogs(
                    session,
                    params['limit'],
                    params['offset'],
                  ),
        ),
        'sendNotification': _i1.MethodConnector(
          name: 'sendNotification',
          params: {
            'notificationId': _i1.ParameterDescription(
              name: 'notificationId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .sendNotification(
                    session,
                    params['notificationId'],
                    params['userId'],
                    params['message'],
                  ),
        ),
        'listNotifications': _i1.MethodConnector(
          name: 'listNotifications',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .listNotifications(
                    session,
                    params['userId'],
                    params['limit'],
                  ),
        ),
        'listStaff': _i1.MethodConnector(
          name: 'listStaff',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminEndpoints'] as _i2.AdminEndpoints).listStaff(
                    session,
                    params['limit'],
                  ),
        ),
        'getAdminProfile': _i1.MethodConnector(
          name: 'getAdminProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .getAdminProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'updateAdminProfile': _i1.MethodConnector(
          name: 'updateAdminProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureData': _i1.ParameterDescription(
              name: 'profilePictureData',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .updateAdminProfile(
                    session,
                    params['userId'],
                    params['name'],
                    params['phone'],
                    params['profilePictureData'],
                  ),
        ),
        'changePassword': _i1.MethodConnector(
          name: 'changePassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'currentPassword': _i1.ParameterDescription(
              name: 'currentPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .changePassword(
                    session,
                    params['userId'],
                    params['currentPassword'],
                    params['newPassword'],
                  ),
        ),
        'updateStaffProfile': _i1.MethodConnector(
          name: 'updateStaffProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'specialization': _i1.ParameterDescription(
              name: 'specialization',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'qualification': _i1.ParameterDescription(
              name: 'qualification',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'joiningDate': _i1.ParameterDescription(
              name: 'joiningDate',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminEndpoints'] as _i2.AdminEndpoints)
                  .updateStaffProfile(
                    session,
                    params['userId'],
                    name: params['name'],
                    specialization: params['specialization'],
                    qualification: params['qualification'],
                    joiningDate: params['joiningDate'],
                  ),
        ),
      },
    );
    connectors['profile'] = _i1.EndpointConnector(
      name: 'profile',
      endpoint: endpoints['profile']!,
      methodConnectors: {
        'getProfile': _i1.MethodConnector(
          name: 'getProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i6.Uuid>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i3.ProfileEndpoint).getProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'changePassword': _i1.MethodConnector(
          name: 'changePassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i6.Uuid>(),
              nullable: false,
            ),
            'oldPassword': _i1.ParameterDescription(
              name: 'oldPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i3.ProfileEndpoint).changePassword(
                    session,
                    params['userId'],
                    params['oldPassword'],
                    params['newPassword'],
                  ),
        ),
        'updateProfile': _i1.MethodConnector(
          name: 'updateProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i6.Uuid>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'qualification': _i1.ParameterDescription(
              name: 'qualification',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i3.ProfileEndpoint).updateProfile(
                    session,
                    params['userId'],
                    params['phone'],
                    params['qualification'],
                  ),
        ),
      },
    );
    connectors['patient'] = _i1.EndpointConnector(
      name: 'patient',
      endpoint: endpoints['patient']!,
      methodConnectors: {
        'getPatientProfile': _i1.MethodConnector(
          name: 'getPatientProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i4.PatientEndpoint)
                  .getPatientProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'updatePatientProfile': _i1.MethodConnector(
          name: 'updatePatientProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'allergies': _i1.ParameterDescription(
              name: 'allergies',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'profilePictureData': _i1.ParameterDescription(
              name: 'profilePictureData',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['patient'] as _i4.PatientEndpoint)
                  .updatePatientProfile(
                    session,
                    params['userId'],
                    params['name'],
                    params['phone'],
                    params['allergies'],
                    params['profilePictureData'],
                  ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i5.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
  }
}
