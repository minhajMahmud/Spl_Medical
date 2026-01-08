import 'package:flutter/material.dart';

// Admin imports
import 'src/admin/admin_profile.dart';
import 'src/admin/history_screen.dart';
import 'src/admin/inventory_management.dart';
import 'src/admin/reports_analytics.dart';
import 'src/admin/staff_rostering.dart';
import 'src/admin/user_management.dart';
import 'src/admin/admin_dashboard.dart';

// Doctor imports
import 'src/doctor/emergency_cases.dart';
import 'src/doctor/patient_records.dart';
import 'src/doctor/doctor_dashboard.dart';
import 'src/doctor/prescription_page.dart';
import 'src/doctor/setting.dart';
import 'src/doctor/doctor_profile.dart';

// Lab imports
import 'src/lab_test/lab_tester_home.dart';
import 'src/lab_test/lab_staff_profile.dart';

// Dispenser imports
import 'src/dispenser/dispenser_dashboard.dart';
import 'src/dispenser/dispenser_profile.dart';

// Patient imports
import 'src/patient/patient_dashboard.dart';
import 'src/patient/patient_profile.dart';
import 'src/patient/patient_prescriptions.dart';
import 'src/patient/patient_report.dart';
import 'src/patient/patient_report_upload.dart';
import 'src/patient/patient_lab_test_availability.dart';
import 'src/patient/patient_ambulance_staff.dart';
import 'src/patient/patient_signup.dart';

// Login
import 'src/universal_login.dart';
// Forgot password
import 'src/ForgetPassword.dart';

// Import from your existing backend_client package
import 'package:backend_client/backend_client.dart';

import 'package:flutter/foundation.dart'; // For kDebugMode, kIsWeb

void main() {
  // Initialize Serverpod client before running app
  WidgetsFlutterBinding.ensureInitialized();

  String? displayUrl;

  // For Android Emulator in Debug mode, use the special IP
  if (kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    displayUrl = 'http://10.0.2.2:8080/';
  }

  // Pass null to let backend_client use environment variable or localhost default
  initServerpodClient(url: displayUrl);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Care',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Raleway',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        // Main routes
        '/': (context) => const HomePage(),

        // Admin routes
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/admin-profile': (context) => const AdminProfile(),
        '/admin-user-management': (context) => const UserManagement(),
        '/admin-inventory-management': (context) => const InventoryManagement(),
        '/admin-reports-analytics': (context) => const ReportsAnalytics(),
        '/admin-history': (context) => const HistoryScreen(),
        '/admin-staff-rostering': (context) => const StaffRostering(),

        // Doctor routes
        '/doctor-dashboard': (context) => const DoctorDashboard(),
        '/doctor-profile': (context) => const ProfilePage(),
        '/doctor-patient-record': (context) => const PatientRecordsPage(),
        '/doctor-emergency-cases': (context) => const EmergencyCasesPage(),
        '/doctor-prescription-template': (context) => const PrescriptionPage(),
        '/doctor-setting': (context) => const Setting(),

        // Dispenser routes
        '/dispenser-dashboard': (context) => const DispenserDashboard(),
        '/dispenser-profile': (context) => const DispenserProfile(),

        // Lab tester routes
        '/lab-dashboard': (context) => const LabTesterHome(),
        '/lab-profile': (context) => const LabTesterProfile(),

        // Patient routes
        // PatientProfilePage now loads its own data (resolves user id from SharedPreferences),
        // so we don't pass any id here.
        '/patient-profile': (context) => const PatientProfilePage(),

        // PatientDashboard will also load stored profile info if route args are missing,
        // so create it with empty values to avoid requiring callers to pass data.
        '/patient-dashboard': (context) =>
            const PatientDashboard(name: '', email: ''),

        '/patient-prescriptions': (context) => const PatientPrescriptions(),
        '/patient-reports': (context) => const PatientReports(),
        '/patient-report-upload': (context) => const PatientReportUpload(),
        '/patient-lab-availability': (context) =>
            const PatientLabTestAvailability(),
        '/patient-ambulance-staff': (context) => const PatientAmbulanceStaff(),
        '/patient-signup': (context) => const PatientSignupPage(),
        '/forgotpassword': (context) => const ForgetPassword(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(child: Text("Page not found: ${settings.name}")),
        ),
      ),
    );
  }
}
