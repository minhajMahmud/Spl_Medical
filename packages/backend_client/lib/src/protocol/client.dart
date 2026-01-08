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
import 'dart:async' as _i2;
import 'package:backend_client/src/protocol/user_list_item.dart' as _i3;
import 'package:uuid/uuid.dart' as _i4;
import 'package:backend_client/src/protocol/lab_test_info.dart' as _i5;
import 'package:backend_client/src/protocol/test_booking_dto.dart' as _i6;
import 'package:backend_client/src/protocol/patient_reponse.dart' as _i7;
import 'package:backend_client/src/protocol/greeting.dart' as _i8;
import 'protocol.dart' as _i9;

/// AdminEndpoints: server-side methods used by the admin UI to manage users,
/// inventory, rosters, audit logs and notifications.
/// {@category Endpoint}
class EndpointAdminEndpoints extends _i1.EndpointRef {
  EndpointAdminEndpoints(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminEndpoints';

  /// List users filtered by role. Use role = 'ALL' to fetch all users.
  _i2.Future<List<_i3.UserListItem>> listUsersByRole(
    String role,
    int limit,
  ) => caller.callServerEndpoint<List<_i3.UserListItem>>(
    'adminEndpoints',
    'listUsersByRole',
    {
      'role': role,
      'limit': limit,
    },
  );

  /// Toggle user's active flag. Returns true on success.
  _i2.Future<bool> toggleUserActive(String userId) =>
      caller.callServerEndpoint<bool>(
        'adminEndpoints',
        'toggleUserActive',
        {'userId': userId},
      );

  /// Create a new user record. Expects passwordHash to already be hashed by the caller.
  /// Returns 'OK' on success or an error message string.
  _i2.Future<String> createUser(
    String userId,
    String name,
    String email,
    String passwordHash,
    String role,
    String? phone,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'createUser',
    {
      'userId': userId,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'role': role,
      'phone': phone,
    },
  );

  /// Create user by hashing the provided raw password server-side.
  _i2.Future<String> createUserWithPassword(
    String userId,
    String name,
    String email,
    String password,
    String role,
    String? phone,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'createUserWithPassword',
    {
      'userId': userId,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
    },
  );

  /// List all medicines with aggregated stock and earliest expiry.
  _i2.Future<List<Map<String, dynamic>>> listMedicines() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'adminEndpoints',
        'listMedicines',
        {},
      );

  /// Add a medicine and return the inserted id or -1 on error.
  _i2.Future<int> addMedicine(
    String name,
    int minimumStock,
  ) => caller.callServerEndpoint<int>(
    'adminEndpoints',
    'addMedicine',
    {
      'name': name,
      'minimumStock': minimumStock,
    },
  );

  /// Add a batch for a medicine.
  _i2.Future<bool> addMedicineBatch(
    int medicineId,
    String batchId,
    int stock,
    DateTime? expiry,
  ) => caller.callServerEndpoint<bool>(
    'adminEndpoints',
    'addMedicineBatch',
    {
      'medicineId': medicineId,
      'batchId': batchId,
      'stock': stock,
      'expiry': expiry,
    },
  );

  /// Get batches for a medicine.
  _i2.Future<List<Map<String, dynamic>>> getMedicineBatches(int medicineId) =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'adminEndpoints',
        'getMedicineBatches',
        {'medicineId': medicineId},
      );

  /// Get low stock medicines (where total stock < minimum_stock)
  _i2.Future<List<Map<String, dynamic>>> getLowStockItems() =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'adminEndpoints',
        'getLowStockItems',
        {},
      );

  _i2.Future<List<Map<String, dynamic>>> getRosters({
    String? staffId,
    DateTime? fromDate,
    DateTime? toDate,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'adminEndpoints',
    'getRosters',
    {
      'staffId': staffId,
      'fromDate': fromDate,
      'toDate': toDate,
    },
  );

  _i2.Future<bool> saveRoster({
    required String rosterId,
    required String staffId,
    required String shiftType,
    required DateTime shiftDate,
    required String timeRange,
    required String status,
    String? approvedBy,
  }) => caller.callServerEndpoint<bool>(
    'adminEndpoints',
    'saveRoster',
    {
      'rosterId': rosterId,
      'staffId': staffId,
      'shiftType': shiftType,
      'shiftDate': shiftDate,
      'timeRange': timeRange,
      'status': status,
      'approvedBy': approvedBy,
    },
  );

  /// Submit a new shift change request
  _i2.Future<Map<String, dynamic>> submitChangeRequest({
    required String rosterId,
    required String staffId,
    required String reason,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'adminEndpoints',
    'submitChangeRequest',
    {
      'rosterId': rosterId,
      'staffId': staffId,
      'reason': reason,
    },
  );

  /// Get all change requests for a staff member
  _i2.Future<List<Map<String, dynamic>>> getMyChangeRequests(String staffId) =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'adminEndpoints',
        'getMyChangeRequests',
        {'staffId': staffId},
      );

  /// Get all pending change requests (for admin)
  _i2.Future<List<Map<String, dynamic>>> getAllChangeRequests({
    String? status,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'adminEndpoints',
    'getAllChangeRequests',
    {'status': status},
  );

  /// Approve or reject a change request (admin only)
  _i2.Future<Map<String, dynamic>> updateRequestStatus({
    required int requestId,
    required String status,
  }) => caller.callServerEndpoint<Map<String, dynamic>>(
    'adminEndpoints',
    'updateRequestStatus',
    {
      'requestId': requestId,
      'status': status,
    },
  );

  _i2.Future<bool> addAuditLog(
    String logId,
    String userId,
    String action,
  ) => caller.callServerEndpoint<bool>(
    'adminEndpoints',
    'addAuditLog',
    {
      'logId': logId,
      'userId': userId,
      'action': action,
    },
  );

  _i2.Future<List<Map<String, dynamic>>> getAuditLogs(
    int limit,
    int offset,
  ) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'adminEndpoints',
    'getAuditLogs',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  _i2.Future<bool> sendNotification(
    String notificationId,
    String userId,
    String message,
  ) => caller.callServerEndpoint<bool>(
    'adminEndpoints',
    'sendNotification',
    {
      'notificationId': notificationId,
      'userId': userId,
      'message': message,
    },
  );

  _i2.Future<List<Map<String, dynamic>>> listNotifications(
    String userId,
    int limit,
  ) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'adminEndpoints',
    'listNotifications',
    {
      'userId': userId,
      'limit': limit,
    },
  );

  _i2.Future<List<Map<String, dynamic>>> listStaff(int limit) =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'adminEndpoints',
        'listStaff',
        {'limit': limit},
      );

  /// Get profile by email (userId). Returns basic user fields and, if available,
  /// staff profile details (department/specialization, qualification, joining_date).
  /// Returns JSON string to avoid Serverpod deserialization issues.
  _i2.Future<String?> getAdminProfile(String userId) =>
      caller.callServerEndpoint<String?>(
        'adminEndpoints',
        'getAdminProfile',
        {'userId': userId},
      );

  /// Update admin profile: name, phone, optional small base64 profilePictureData (<=50KB)
  _i2.Future<String> updateAdminProfile(
    String userId,
    String name,
    String phone,
    String? profilePictureData,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'updateAdminProfile',
    {
      'userId': userId,
      'name': name,
      'phone': phone,
      'profilePictureData': profilePictureData,
    },
  );

  /// Change password for given user (identified by email/userId). Verifies current password before updating.
  _i2.Future<String> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'changePassword',
    {
      'userId': userId,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
  );

  /// Update staff profile details for a user identified by email.
  /// Allows updating specialization, qualification, and joining_date.
  /// Returns 'OK' on success or an error message.
  _i2.Future<String> updateStaffProfile(
    String userId, {
    String? name,
    String? specialization,
    String? qualification,
    DateTime? joiningDate,
  }) => caller.callServerEndpoint<String>(
    'adminEndpoints',
    'updateStaffProfile',
    {
      'userId': userId,
      'name': name,
      'specialization': specialization,
      'qualification': qualification,
      'joiningDate': joiningDate,
    },
  );
}

/// {@category Endpoint}
class EndpointProfile extends _i1.EndpointRef {
  EndpointProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'profile';

  /// =========================
  /// GET USER PROFILE
  /// =========================
  _i2.Future<Map<String, dynamic>?> getProfile(_i4.Uuid userId) =>
      caller.callServerEndpoint<Map<String, dynamic>?>(
        'profile',
        'getProfile',
        {'userId': userId},
      );

  /// =========================
  /// CHANGE PASSWORD
  /// =========================
  _i2.Future<bool> changePassword(
    _i4.Uuid userId,
    String oldPassword,
    String newPassword,
  ) => caller.callServerEndpoint<bool>(
    'profile',
    'changePassword',
    {
      'userId': userId,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    },
  );

  /// =========================
  /// UPDATE PROFILE (PHONE / QUALIFICATION)
  /// =========================
  _i2.Future<bool> updateProfile(
    _i4.Uuid userId,
    String phone,
    String qualification,
  ) => caller.callServerEndpoint<bool>(
    'profile',
    'updateProfile',
    {
      'userId': userId,
      'phone': phone,
      'qualification': qualification,
    },
  );

  /// List all lab tests from the lab_tests table.
  /// Returns strongly-typed LabTestInfo models so the Flutter app
  /// can deserialize them safely.
  _i2.Future<List<_i5.LabTestInfo>> listLabTests() =>
      caller.callServerEndpoint<List<_i5.LabTestInfo>>(
        'profile',
        'listLabTests',
        {},
      );

  /// List all lab test bookings with basic joined information for dashboard.
  ///
  /// Returns one [protocol.TestBookingDto] per booking-test pairing.
  _i2.Future<List<_i6.TestBookingDto>> listTestBookings() =>
      caller.callServerEndpoint<List<_i6.TestBookingDto>>(
        'profile',
        'listTestBookings',
        {},
      );

  /// Insert a new lab test into lab_tests and return the generated test_id.
  _i2.Future<int?> createLabTest({
    required String testName,
    String? description,
    required double studentFee,
    required double staffFee,
    required double outsideFee,
    required bool available,
  }) => caller.callServerEndpoint<int?>(
    'profile',
    'createLabTest',
    {
      'testName': testName,
      'description': description,
      'studentFee': studentFee,
      'staffFee': staffFee,
      'outsideFee': outsideFee,
      'available': available,
    },
  );

  /// Update an existing lab test. All fields are required to keep the query
  /// simple on the client side.
  _i2.Future<bool> updateLabTest({
    required int testId,
    required String testName,
    String? description,
    required double studentFee,
    required double staffFee,
    required double outsideFee,
    required bool available,
  }) => caller.callServerEndpoint<bool>(
    'profile',
    'updateLabTest',
    {
      'testId': testId,
      'testName': testName,
      'description': description,
      'studentFee': studentFee,
      'staffFee': staffFee,
      'outsideFee': outsideFee,
      'available': available,
    },
  );

  /// Search for a patient/user by user_id, email, or phone number.
  /// Returns user details if found, null otherwise.
  _i2.Future<Map<String, dynamic>?> searchPatient({
    required String searchTerm,
  }) => caller.callServerEndpoint<Map<String, dynamic>?>(
    'profile',
    'searchPatient',
    {'searchTerm': searchTerm},
  );

  /// Create separate test bookings for each selected test.
  ///
  /// IMPORTANT: This method creates ONE BOOKING PER TEST, not a single booking with multiple tests.
  ///
  /// Business Logic:
  /// - If patient selects [CBC, SGPT], creates 2 separate bookings
  /// - Each booking has its own booking_id and booking_code
  /// - Each booking can have its own result file uploaded independently
  /// - One-to-one relationship: 1 booking = 1 test
  ///
  /// Patient ID Resolution:
  /// - If patientId matches a user_id from database: uses actual user_id, is_external_patient=false
  /// - If patientId is a generated ID (>= 1000000): stores as external patient
  /// - If patientId not found in database: marks as external patient
  ///
  /// Returns a comma-separated list of booking codes (e.g., "BK000001,BK000002,BK000003")
  /// Returns empty string "" on failure.
  _i2.Future<String> createTestBooking({
    required String bookingId,
    String? patientId,
    required List<int> testIds,
    required DateTime bookingDate,
    required bool isExternalPatient,
    String? patientType,
    String? externalPatientName,
    String? externalPatientEmail,
    String? externalPatientPhone,
  }) => caller.callServerEndpoint<String>(
    'profile',
    'createTestBooking',
    {
      'bookingId': bookingId,
      'patientId': patientId,
      'testIds': testIds,
      'bookingDate': bookingDate,
      'isExternalPatient': isExternalPatient,
      'patientType': patientType,
      'externalPatientName': externalPatientName,
      'externalPatientEmail': externalPatientEmail,
      'externalPatientPhone': externalPatientPhone,
    },
  );

  /// Upload or update a test result entry for a specific booking test.
  ///
  /// This writes to the `test_results` table with a reference to booking_tests.
  /// Since a booking can have multiple tests (via booking_tests junction table),
  /// this endpoint handles results for individual test entries.
  ///
  /// The result references booking_test_id (the junction table record),
  /// which links to both a booking and a test.
  _i2.Future<bool> uploadTestResult({
    required String bookingId,
    String? testId,
    String? staffId,
    required String status,
    DateTime? resultDate,
    String? attachmentPath,
    required bool sendToPatient,
    required bool sendToDoctor,
    String? patientEmailOverride,
    String? doctorEmailOverride,
    String? attachmentFileName,
    String? attachmentContentBase64,
    String? attachmentContentType,
  }) => caller.callServerEndpoint<bool>(
    'profile',
    'uploadTestResult',
    {
      'bookingId': bookingId,
      'testId': testId,
      'staffId': staffId,
      'status': status,
      'resultDate': resultDate,
      'attachmentPath': attachmentPath,
      'sendToPatient': sendToPatient,
      'sendToDoctor': sendToDoctor,
      'patientEmailOverride': patientEmailOverride,
      'doctorEmailOverride': doctorEmailOverride,
      'attachmentFileName': attachmentFileName,
      'attachmentContentBase64': attachmentContentBase64,
      'attachmentContentType': attachmentContentType,
    },
  );

  /// Download the test result file for a specific booking.
  ///
  /// Returns a JSON string containing:
  /// {
  ///   "filename": "report.pdf",
  ///   "contentType": "application/pdf",
  ///   "data": "base64_encoded_content..."
  /// }
  /// Returns empty string if not found or error.
  _i2.Future<String> downloadTestResult(String bookingId) =>
      caller.callServerEndpoint<String>(
        'profile',
        'downloadTestResult',
        {'bookingId': bookingId},
      );
}

/// {@category Endpoint}
class EndpointPatient extends _i1.EndpointRef {
  EndpointPatient(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'patient';

  _i2.Future<_i7.PatientProfileDto?> getPatientProfile(String userId) =>
      caller.callServerEndpoint<_i7.PatientProfileDto?>(
        'patient',
        'getPatientProfile',
        {'userId': userId},
      );

  _i2.Future<String> updatePatientProfile(
    String userId,
    String name,
    String phone,
    String allergies,
    String? profilePictureData,
  ) => caller.callServerEndpoint<String>(
    'patient',
    'updatePatientProfile',
    {
      'userId': userId,
      'name': name,
      'phone': phone,
      'allergies': allergies,
      'profilePictureData': profilePictureData,
    },
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i8.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i8.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i9.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    adminEndpoints = EndpointAdminEndpoints(this);
    profile = EndpointProfile(this);
    patient = EndpointPatient(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointAdminEndpoints adminEndpoints;

  late final EndpointProfile profile;

  late final EndpointPatient patient;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'adminEndpoints': adminEndpoints,
    'profile': profile,
    'patient': patient,
    'greeting': greeting,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
