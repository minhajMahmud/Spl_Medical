import 'package:backend_client/backend_client.dart' as backend;

// Lab test master list with pricing for different patient types
class LabTest {
  final String testId;
  final String testName;
  final String description;
  final double feeStudent;
  final double feeEmployee;
  final double feeOutPatient;
  final bool available;

  LabTest({
    required this.testId,
    required this.testName,
    required this.description,
    required this.feeStudent,
    required this.feeEmployee,
    required this.feeOutPatient,
    required this.available,
  });

  factory LabTest.fromBackend(Map<String, dynamic> row) {
    return LabTest(
      testId: row['test_id']?.toString() ?? '',
      testName: row['test_name']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      feeStudent: (row['student_fee'] as num?)?.toDouble() ?? 0.0,
      feeEmployee: (row['staff_fee'] as num?)?.toDouble() ?? 0.0,
      feeOutPatient: (row['outside_fee'] as num?)?.toDouble() ?? 0.0,
      available: row['available'] as bool? ?? true,
    );
  }

  static Future<List<LabTest>> fetchFromBackend() async {
    try {
      // Prefer the generated, strongly-typed endpoint ref.
      final result = await backend.client.profile.listLabTests();

      if (result.isEmpty) return [];

      // Map backend LabTestInfo models to the UI LabTest model.
      return result
          .map(
            (info) => LabTest(
              testId: info.testId?.toString() ?? '',
              testName: info.testName?.toString() ?? '',
              description: info.description?.toString() ?? '',
              feeStudent: (info.studentFee as num?)?.toDouble() ?? 0.0,
              feeEmployee: (info.staffFee as num?)?.toDouble() ?? 0.0,
              feeOutPatient: (info.outsideFee as num?)?.toDouble() ?? 0.0,
              available: info.available as bool? ?? true,
            ),
          )
          .toList();
    } catch (e, st) {
      // Log the error so it's visible in the console during debugging.
      // If anything goes wrong, return an empty list so the UI doesn't crash.
      // ignore: avoid_print
      print('Failed to load lab tests from backend: $e\n$st');
      return [];
    }
  }

  double getFee(String patientType) {
    switch (patientType) {
      case 'student':
        return feeStudent;
      case 'employee':
      case 'staff':
        return feeEmployee;
      case 'out_patient':
      case 'outpatient':
        return feeOutPatient;
      default:
        return feeOutPatient; // Default to outpatient fee
    }
  }
}

// Lab Test Categories for different user types
enum PatientType { student, employee, outPatient }

extension PatientTypeExt on PatientType {
  String get displayName {
    switch (this) {
      case PatientType.student:
        return 'Student';
      case PatientType.employee:
        return 'Employee';
      case PatientType.outPatient:
        return 'Out Patient';
    }
  }

  String get value {
    switch (this) {
      case PatientType.student:
        return 'student';
      case PatientType.employee:
        return 'employee';
      case PatientType.outPatient:
        return 'out_patient';
    }
  }
}

// NOTE: The old hard-coded labTests list has been removed.
// All lab test pricing now comes from the backend (lab_tests table).
