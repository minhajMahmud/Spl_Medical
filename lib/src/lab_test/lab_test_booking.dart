/// Professional Lab Test Booking System
///
/// This file contains two main widgets:
/// 1. PatientBookingEntry - Entry point for patient selection
/// 2. LabTestBooking - Main 5-step booking workflow
///
/// **Features:**
/// - 4-step booking process with visual progress indicator
/// - Patient information capture with validation
/// - Advanced test selection with categories and search
/// - Sample collection scheduling (In-Lab or Home Collection)
/// - Payment method selection and order summary
/// - Automatic discount calculation based on patient type
/// - Terms and conditions agreement
///
/// **Steps:**
/// 1. Patient Information - Capture basic patient details
/// 2. Test Selection - Browse and select tests with pricing
/// 3. Sample Collection - Schedule and location details
/// 4. Payment & Confirmation - Payment method and final review
///
/// **Patient Types Supported:**
/// - Student (with special pricing and discounts)
/// - Employee (with special pricing and discounts)
/// - Out Patient (standard pricing)
///
/// **Discounts:**
/// - Students: 10% off for 3+ tests
/// - Employees: 15% off for 5+ tests
///
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:backend_client/backend_client.dart' as backend;
import 'lab_test_list.dart';
import 'download_receipt_stub.dart'
    if (dart.library.html) 'download_receipt_web.dart';

/// Entry point widget for patient booking selection
class PatientBookingEntry extends StatefulWidget {
  const PatientBookingEntry({super.key});

  @override
  State<PatientBookingEntry> createState() => _PatientBookingEntryState();
}

class _PatientBookingEntryState extends State<PatientBookingEntry> {
  String _selectedPatientType = '';
  final TextEditingController _patientIdCtrl = TextEditingController();
  bool _showPatientTypeSelection = false;
  bool _isSearching = false;
  bool _patientFound = false;
  backend.PatientProfileDto? _patientProfile;

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    super.dispose();
  }

  /// Search for patient by ID or phone number
  Future<void> _searchPatient() async {
    if (_patientIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Patient ID or student Id or name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _patientFound = false;
      _showPatientTypeSelection = false;
      _patientProfile = null;
    });

    try {
      final query = _patientIdCtrl.text.trim();

      // Call backend to search patient profile by userId / patientId
      final profile = await backend.client.patient.getPatientProfile(query);

      if (!mounted) return;

      if (profile != null) {
        // Patient found - auto-detect patient type from user role
        String detectedType = 'outpatient'; // default
        final userRole = profile.role?.toUpperCase() ?? '';

        if (userRole == 'STUDENT') {
          detectedType = 'student';
        } else if ([
          'TEACHER',
          'STAFF',
          'DOCTOR',
          'DISPENSER',
          'LABSTAFF',
          'ADMIN',
        ].contains(userRole)) {
          detectedType = 'staff';
        }

        setState(() {
          _patientFound = true;
          _selectedPatientType = detectedType;
          _isSearching = false;
          _patientProfile = profile;
        });
      } else {
        // Patient not found - show patient type selection for walk-in
        setState(() {
          _patientFound = false;
          _isSearching = false;
          _showPatientTypeSelection = true;
          _selectedPatientType = ''; // Reset selection
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No patient found. Please select patient type for walk-in booking.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToBooking() {
    if (_selectedPatientType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabTestBooking(
          patientId: _patientIdCtrl.text,
          patientType: _selectedPatientType,
          initialName: _patientProfile?.name,
          initialEmail: _patientProfile?.email,
          initialPhone: _patientProfile?.phone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Lab Test Booking'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter patient details to start booking process',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Patient ID / Phone Input with Search
            TextField(
              controller: _patientIdCtrl,
              enabled: !_isSearching && !_patientFound,
              decoration: InputDecoration(
                labelText: 'Patient ID / Student Id / email',
                hintText: 'Enter patient ID, student ID, or email for walk-in',
                prefixIcon: const Icon(Icons.person),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _patientFound
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _searchPatient(),
            ),
            const SizedBox(height: 16),

            // Search Button
            if (!_patientFound)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchPatient,
                  icon: const Icon(Icons.search),
                  label: const Text('Search Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Patient Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _patientFound = false;
                              _selectedPatientType = '';
                              _patientIdCtrl.clear();
                              _patientProfile = null;
                            });
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (_patientProfile != null) ...[
                      _buildInfoRow(Icons.badge, 'ID', _patientIdCtrl.text),
                      _buildInfoRow(
                        Icons.person,
                        'Name',
                        _patientProfile!.name ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        _patientProfile!.email ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        _patientProfile!.phone ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.category,
                        'Type',
                        _selectedPatientType == 'student'
                            ? 'Student'
                            : _selectedPatientType == 'staff'
                            ? 'Staff'
                            : 'Outside Patient',
                      ),
                      if (_patientProfile!.role != null)
                        _buildInfoRow(
                          Icons.work,
                          'Role',
                          _safeStringValue(_patientProfile!.role),
                        ),
                    ],
                  ],
                ),
              ),

            // Patient Type Selection (shown for walk-in patients)
            if (_showPatientTypeSelection) ...[
              const SizedBox(height: 24),
              const Text(
                'Select Patient Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTypeOption(
                'student',
                'Student',
                'University student with ID',
              ),
              const SizedBox(height: 12),
              _buildTypeOption(
                'staff',
                'Staff',
                'University staff/faculty member',
              ),
              const SizedBox(height: 12),
              _buildTypeOption(
                'outpatient',
                'Outside Patient',
                'General public / external patient',
              ),
            ],

            // Patient Type Selection (shown only if patient not found)
            // Note: walk-in patients go directly to booking screen now,
            // so we no longer show the manual patient-type selection here.
            const SizedBox(height: 32),

            // Start Booking Button (shown when patient type is selected)
            if (_patientFound ||
                (_showPatientTypeSelection && _selectedPatientType.isNotEmpty))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_patientFound) {
                      _proceedToBooking();
                    } else {
                      // Walk-in booking
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LabTestBooking(
                            patientId: 'WALKIN:${_patientIdCtrl.text}',
                            patientType: _selectedPatientType,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue to Booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String title, String subtitle) {
    final isSelected = _selectedPatientType == value;
    return InkWell(
      onTap: () => setState(() => _selectedPatientType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blue.shade700 : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Safely convert any value to string, handling UndecodedBytes
  String _safeStringValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value;
    // Handle UndecodedBytes or other types
    return value.toString();
  }
}

class LabTestBooking extends StatefulWidget {
  final String patientId;
  final String patientType;
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;

  const LabTestBooking({
    super.key,
    required this.patientId,
    required this.patientType,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
  });

  @override
  State<LabTestBooking> createState() => _LabTestBookingState();
}

class _LabTestBookingState extends State<LabTestBooking> {
  int _currentStep = 0;
  bool _isDarkMode = false;
  final _formKey = GlobalKey<FormState>();

  // Patient identification
  late String _patientId;
  late String _selectedPatientType;

  // Step 1: Patient Information
  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _patientEmailCtrl = TextEditingController();
  final TextEditingController _patientPhoneCtrl = TextEditingController();
  final TextEditingController _patientAgeCtrl = TextEditingController();
  final TextEditingController _patientAddressCtrl = TextEditingController();
  String _patientGender = 'Male';
  DateTime? _selectedDate;

  // Step 2: Test Selection with Categories
  List<LabTest> _allTests = [];
  final List<LabTest> _selectedTests = [];
  double _totalAmount = 0.0;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _testCategories = [
    'All',
    'Hematology',
    'Biochemistry',
    'Serology',
    'Immunology',
    'Microbiology',
    'Special Tests',
  ];

  final TextEditingController _collectionAddressCtrl = TextEditingController();
  final TextEditingController _specialInstructionsCtrl =
      TextEditingController();

  // Step 4: Payment & Confirmation
  String _paymentMethod = 'Cash';
  String _reportDeliveryMethod = 'Email';
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientId;
    _selectedPatientType = widget.patientType;
    _selectedDate = DateTime.now();

    _loadThemePreference();
    _loadPatientData();
    _loadLabTests();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  void _loadPatientData() {
    // If we were passed initial patient details (from backend search),
    // use them to pre-fill the form.
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _patientNameCtrl.text = widget.initialName!;
    }
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _patientEmailCtrl.text = widget.initialEmail!;
    }
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _patientPhoneCtrl.text = widget.initialPhone!;
    }

    // For walk-in bookings we leave the fields empty so they can be entered
    // manually. The special WALKIN: prefix is only used to distinguish the
    // booking in storage / UI labels.
  }

  List<LabTest> _getFilteredTests() {
    return _allTests.where((test) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          test.testName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          test.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' ||
          _getCategoryForTest(test) == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _loadLabTests() async {
    final tests = await LabTest.fetchFromBackend();
    if (!mounted) return;
    setState(() {
      _allTests = tests;
    });
  }

  String _getCategoryForTest(LabTest test) {
    if ([
      'CBC',
      'Hb%',
      'Blood Grouping',
      'ESR',
      'PCV',
      'TC',
      'DC',
    ].any((k) => test.testName.contains(k))) {
      return 'Hematology';
    } else if ([
      'Glucose',
      'Bilirubin',
      'SGPT',
      'SGOT',
      'Creatinine',
      'Calcium',
      'Lipid',
      'Urea',
      'Cholesterol',
    ].any((k) => test.testName.contains(k))) {
      return 'Biochemistry';
    } else if ([
      'HBsAg',
      'Dengue',
      'Widal',
      'Syphilis',
      'HIV',
      'HCV',
    ].any((k) => test.testName.contains(k))) {
      return 'Serology';
    } else if ([
      'CRP',
      'RA',
      'ASO',
      'ANA',
    ].any((k) => test.testName.contains(k))) {
      return 'Immunology';
    } else if ([
      'Culture',
      'Sensitivity',
    ].any((k) => test.testName.contains(k))) {
      return 'Microbiology';
    } else {
      return 'Special Tests';
    }
  }

  void _toggleTestSelection(LabTest test) {
    setState(() {
      if (_selectedTests.contains(test)) {
        _selectedTests.remove(test);
      } else {
        _selectedTests.add(test);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double subtotal = 0.0;
    for (var test in _selectedTests) {
      subtotal += test.getFee(_selectedPatientType);
    }

    // Apply discounts based on patient type and number of tests
    if (_selectedPatientType == 'student' && _selectedTests.length >= 3) {
    } else if (_selectedPatientType == 'employee' &&
        _selectedTests.length >= 5) {
    } else {}

    _totalAmount = subtotal;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Patient Information
        if (_patientNameCtrl.text.isEmpty ||
            _patientPhoneCtrl.text.isEmpty ||
            _patientAgeCtrl.text.isEmpty) {
          _showError('Please fill all required patient information');
          return false;
        }
        if (_patientEmailCtrl.text.isNotEmpty &&
            !_patientEmailCtrl.text.contains('@')) {
          _showError('Please enter a valid email address');
          return false;
        }
        return true;

      case 1: // Test Selection
        if (_selectedTests.isEmpty) {
          _showError('Please select at least one test');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        if (_currentStep < 3) {
          _currentStep++;
        }
      });
    }
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (!_validateCurrentStep()) return;

    // Generate a unique, display-friendly booking code (client side).
    // Use microsecondsSinceEpoch to avoid collisions across multiple rapid bookings.
    final bookingId = 'BK${DateTime.now().microsecondsSinceEpoch.toString()}';

    final isExternalPatient = _patientId.startsWith('WALKIN:');
    final dbPatientId = isExternalPatient
        ? null
        : _patientId; // For patient_profiles.user_id

    // Create booking data
    final bookingData = {
      "bookingId": bookingId,
      "patient": _patientNameCtrl.text,
      "patientId": _patientId, // UI-facing id (may contain WALKIN: prefix)
      "dbPatientId": dbPatientId, // Pure backend id for patient_profiles
      "isExternalPatient": isExternalPatient,
      "patientType": _selectedPatientType,
      "tests": _selectedTests
          .map(
            (test) => {
              "testId": test.testId,
              "test": test.testName,
              "price": test.getFee(_selectedPatientType),
            },
          )
          .toList(),
      "status": "PENDING",
      "bookingDate": DateTime.now().toString().split(' ')[0],
      "amount": _totalAmount,
      "patientEmail": _patientEmailCtrl.text,
      "patientPhone": _patientPhoneCtrl.text,
      "patientAge": _patientAgeCtrl.text,
      "patientGender": _patientGender,
      "patientAddress": _patientAddressCtrl.text,
      "collectionAddress": _collectionAddressCtrl.text,
      "paymentMethod": _paymentMethod,
      // Payload shaped for backend test_bookings schema
      "backendPayload": {
        "bookingId": bookingId,
        "patientId": dbPatientId,
        "testIds": _selectedTests
            .map((test) => int.tryParse(test.testId))
            .whereType<int>()
            .toList(),
        // DATE only, e.g. 2025-12-30, matching booking_date DATE column
        "bookingDate": DateTime.now().toIso8601String().split('T').first,
        "isExternalPatient": isExternalPatient,
        "patientType": _selectedPatientType,
        // For test_booking_status enum (PENDING will be mapped/handled server-side)
        "status": "PENDING",
      },
    };

    // First, try to send booking to backend (lab_test_endpoint.dart).
    // This keeps the UI ready for full backend integration.
    final confirmedIds = await _sendBookingToBackend(bookingData);

    // Also keep local storage for now so existing flows keep working
    // even before backend is fully implemented.
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsList = prefs.getStringList('lab_test_bookings') ?? [];

      if (confirmedIds.isNotEmpty &&
          confirmedIds.length == _selectedTests.length) {
        // Backend successfully created separate bookings for each test.
        // We save them as separate entries locally to match dashboard expectations.
        for (int i = 0; i < confirmedIds.length; i++) {
          final newBookingId = confirmedIds[i];
          final test = _selectedTests[i];
          final fee = test.getFee(_selectedPatientType);

          final splitBooking = Map<String, dynamic>.from(bookingData);
          splitBooking['bookingId'] = newBookingId;
          splitBooking['tests'] = [
            {"testId": test.testId, "test": test.testName, "price": fee},
          ];
          splitBooking['amount'] = fee; // Amount for this specific booking
          splitBooking['backendPayload']['bookingId'] = newBookingId;

          bookingsList.add(jsonEncode(splitBooking));
        }

        // Update the main bookingData ID for the receipt display only
        bookingData['bookingId'] = confirmedIds.join(', ');
      } else {
        // Fallback: Backend failed or returned unexpected format.
        // Save as a combined booking (legacy behavior) to ensure data isn't lost.
        bookingsList.add(jsonEncode(bookingData));
      }

      await prefs.setStringList('lab_test_bookings', bookingsList);

      if (mounted) {
        // Show detailed booking receipt with print option
        await _showBookingReceipt(bookingData);

        // Navigate back with success
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Hook for backend integration.
  ///
  /// Returns a list of booking IDs created by the backend.
  Future<List<String>> _sendBookingToBackend(
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final payload = bookingData['backendPayload'] as Map<String, dynamic>;
      final bookingId = payload['bookingId'] as String?;
      final patientId = payload['patientId'] as String?;
      final testIdsRaw = payload['testIds'] as List?;
      final bookingDateStr = payload['bookingDate'] as String?;
      final isExternalPatient =
          (payload['isExternalPatient'] as bool?) ?? false;
      final patientType = payload['patientType'] as String?;

      if (bookingId == null || bookingId.isEmpty) {
        // ignore: avoid_print
        print('sendBookingToBackend: missing bookingId');
        return [];
      }
      if (testIdsRaw == null || testIdsRaw.isEmpty) {
        // ignore: avoid_print
        print('sendBookingToBackend: no testIds in payload');
        return [];
      }
      if (bookingDateStr == null || bookingDateStr.isEmpty) {
        // ignore: avoid_print
        print('sendBookingToBackend: missing bookingDate');
        return [];
      }

      final testIds = testIdsRaw.map((e) => e as int).toList();
      final bookingDate = DateTime.parse(bookingDateStr);

      // Get walk-in patient data if external
      final externalPatientName = isExternalPatient
          ? bookingData['patient'] as String?
          : null;
      final externalPatientEmail = isExternalPatient
          ? bookingData['patientEmail'] as String?
          : null;
      final externalPatientPhone = isExternalPatient
          ? bookingData['patientPhone'] as String?
          : null;

      final resultString = await backend.client.profile.createTestBooking(
        bookingId: bookingId,
        patientId: patientId,
        testIds: testIds,
        bookingDate: bookingDate,
        isExternalPatient: isExternalPatient,
        patientType: patientType,
        externalPatientName: externalPatientName,
        externalPatientEmail: externalPatientEmail,
        externalPatientPhone: externalPatientPhone,
      );

      if (resultString.trim().isNotEmpty) {
        // Backend returns comma-separated string: "BK001,BK002"
        final ids = resultString
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        // ignore: avoid_print
        print('✅ Booking synced with server: $ids');
        return ids;
      } else {
        // Backend call failed – show a non-blocking warning.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Booking saved locally but failed to sync with server.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return [];
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Failed to prepare/send booking to backend: $e\n$st');
      return [];
    }
  }

  Future<void> _showBookingReceipt(Map<String, dynamic> bookingData) async {
    // Use a fixed light scheme here so the receipt is always easy to read
    // regardless of the main app theme.
    final textColor = Colors.black87;
    final subtextColor = Colors.grey[700]!;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Header
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Booking ID: ${bookingData['bookingId']}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Booking Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify that the patient details are correct before proceeding.',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                    const SizedBox(height: 12),
                    _buildReceiptRow(
                      'Name',
                      bookingData['patient'],
                      textColor,
                      subtextColor,
                    ),
                    _buildReceiptRow(
                      'Patient ID',
                      bookingData['patientId'],
                      textColor,
                      subtextColor,
                    ),
                    _buildReceiptRow(
                      'Phone',
                      bookingData['patientPhone'],
                      textColor,
                      subtextColor,
                    ),
                    _buildReceiptRow(
                      'Email',
                      bookingData['patientEmail'],
                      textColor,
                      subtextColor,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 24),
                    Text(
                      'Test Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(bookingData['tests'] as List).map((test) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                test['test'],
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            Text(
                              '৳${test['price'].toStringAsFixed(0)}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    const Divider(height: 24),
                    _buildReceiptRow(
                      'Date',
                      bookingData['bookingDate'],
                      textColor,
                      subtextColor,
                    ),
                    _buildReceiptRow(
                      'Status',
                      bookingData['status'],
                      textColor,
                      subtextColor,
                    ),
                    _buildReceiptRow(
                      'Payment Method',
                      bookingData['paymentMethod'],
                      textColor,
                      subtextColor,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '৳${bookingData['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _downloadBookingReceipt(bookingData);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          foregroundColor: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value,
    Color textColor,
    Color subtextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: subtextColor, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadBookingReceipt(Map<String, dynamic> bookingData) async {
    try {
      final bookingId = bookingData['bookingId'] as String;
      // Use the platform-specific PDF download function from
      // download_receipt_stub.dart / download_receipt_web.dart
      await downloadBookingReceipt(bookingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Receipt downloaded: lab_booking_$bookingId.pdf'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientEmailCtrl.dispose();
    _patientPhoneCtrl.dispose();
    _patientAgeCtrl.dispose();
    _patientAddressCtrl.dispose();
    _collectionAddressCtrl.dispose();
    _specialInstructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF1A1F2E) : Colors.grey[50]!;
    final cardColor = _isDarkMode ? const Color(0xFF252B3D) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Lab Test Booking',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
                _saveThemePreference(_isDarkMode);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(textColor, subtextColor),

          // Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: _buildStepContent(
                  bgColor,
                  cardColor,
                  textColor,
                  subtextColor,
                ),
              ),
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Color textColor, Color subtextColor) {
    final steps = ['Patient Info', 'Select Tests', 'Payment'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF252B3D) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : isActive
                        ? const Color(0xFF7C3AED)
                        : subtextColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : subtextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? textColor : subtextColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(
    Color bgColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildPatientInfoStep(cardColor, textColor, subtextColor);
      case 1:
        return _buildTestSelectionStep(cardColor, textColor, subtextColor);
      case 2:
        return _buildPaymentStep(cardColor, textColor, subtextColor);
      default:
        return Container();
    }
  }

  Widget _buildPatientInfoStep(
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: const Color(0xFF7C3AED), size: 28),
                const SizedBox(width: 12),
                Text(
                  'Patient Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Patient ID Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge, color: const Color(0xFF7C3AED)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient ID',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      Text(
                        _patientId,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      _selectedPatientType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color(0xFF7C3AED),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient Name
            TextFormField(
              controller: _patientNameCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Full Name *',
                labelStyle: TextStyle(color: subtextColor),
                prefixIcon: Icon(Icons.person_outline, color: subtextColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Age and Gender Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _patientAgeCtrl,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age *',
                      labelStyle: TextStyle(color: subtextColor),
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: subtextColor,
                      ),
                      filled: true,
                      fillColor: bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _patientGender,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Gender *',
                      labelStyle: TextStyle(color: subtextColor),
                      prefixIcon: Icon(Icons.wc, color: subtextColor),
                      filled: true,
                      fillColor: bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['Male', 'Female']
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _patientGender = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _patientPhoneCtrl,
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                labelStyle: TextStyle(color: subtextColor),
                prefixIcon: Icon(Icons.phone, color: subtextColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _patientEmailCtrl,
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: subtextColor),
                prefixIcon: Icon(Icons.email, color: subtextColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _patientAddressCtrl,
              style: TextStyle(color: textColor),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Address (Optional)',
                labelStyle: TextStyle(color: subtextColor),
                prefixIcon: Icon(Icons.home, color: subtextColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSelectionStep(
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final filteredTests = _getFilteredTests();

    return Column(
      children: [
        // Summary Card
        if (_selectedTests.isNotEmpty)
          Card(
            color: const Color(0xFF7C3AED),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Tests',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_selectedTests.length} test(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '৳${_totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Search and Filter
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search tests by name or code...',
                    hintStyle: TextStyle(color: subtextColor),
                    prefixIcon: Icon(Icons.search, color: subtextColor),
                    filled: true,
                    fillColor: bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _testCategories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : 'All';
                            });
                          },
                          backgroundColor: cardColor,
                          selectedColor: const Color(
                            0xFF7C3AED,
                          ).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF7C3AED),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : subtextColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Test List
        ...filteredTests.map((test) {
          final isSelected = _selectedTests.contains(test);
          final fee = test.getFee(_selectedPatientType);

          return Card(
            color: cardColor,
            elevation: isSelected ? 4 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () => _toggleTestSelection(test),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : subtextColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          isSelected ? Icons.check : Icons.science,
                          color: isSelected ? Colors.white : subtextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.testName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            test.description,
                            style: TextStyle(fontSize: 12, color: subtextColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${fee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentStep(
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Column(
      children: [
        // Lab Summary Card
        Card(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: const Color(0xFF7C3AED),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lab Test Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Review patient details and selected investigations before confirming.',
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),

                // Patient Info
                _buildSummaryRow(
                  'Patient Name',
                  _patientNameCtrl.text,
                  textColor,
                  subtextColor,
                ),
                _buildSummaryRow(
                  'Patient ID',
                  _patientId,
                  textColor,
                  subtextColor,
                ),
                _buildSummaryRow(
                  'Contact Number',
                  _patientPhoneCtrl.text,
                  textColor,
                  subtextColor,
                ),
                const Divider(height: 20),

                // Tests
                Text(
                  'Selected Tests (${_selectedTests.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 8),
                ..._selectedTests.map(
                  (test) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            test.testName,
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        Text(
                          '৳${test.getFee(_selectedPatientType).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),

                _buildSummaryRow(
                  'Tests Total',
                  '৳${_totalAmount.toStringAsFixed(2)}',
                  textColor,
                  subtextColor,
                ),

                const Divider(height: 20),

                _buildSummaryRow(
                  'Grand Total',
                  '৳${_totalAmount.toStringAsFixed(2)}',
                  const Color(0xFF7C3AED),
                  subtextColor,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Payment Method Card
        Card(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...['Cash'].map((method) {
                  return RadioListTile<String>(
                    title: Text(method, style: TextStyle(color: textColor)),
                    value: method,
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    activeColor: const Color(0xFF7C3AED),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Report Delivery Card
        Card(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Delivery Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...['Email', 'SMS', 'Print', 'All'].map((method) {
                  return RadioListTile<String>(
                    title: Text(method, style: TextStyle(color: textColor)),
                    value: method,
                    groupValue: _reportDeliveryMethod,
                    onChanged: (value) {
                      setState(() {
                        _reportDeliveryMethod = value!;
                      });
                    },
                    activeColor: const Color(0xFF7C3AED),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color textColor,
    Color subtextColor, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? textColor : subtextColor,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: const Color(0xFF7C3AED)),
                  foregroundColor: const Color(0xFF7C3AED),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _currentStep < 2 ? _nextStep : _confirmBooking,
              icon: Icon(
                _currentStep < 2 ? Icons.arrow_forward : Icons.check_circle,
              ),
              label: Text(_currentStep < 2 ? 'Next' : 'Confirm Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get bgColor => _isDarkMode ? const Color(0xFF1A1F2E) : Colors.grey[50]!;
}

// ==========================================
// RESULT UPLOAD SCREEN
// ==========================================

/// Result Upload Screen for lab testers to upload test results
class ResultUploadScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(String, String) onComplete;

  const ResultUploadScreen({
    super.key,
    required this.booking,
    required this.onComplete,
  });

  @override
  State<ResultUploadScreen> createState() => _ResultUploadScreenState();
}

class _ResultUploadScreenState extends State<ResultUploadScreen> {
  PlatformFile? _selectedFile;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _doctorEmailController = TextEditingController();
  bool _isUploading = false;
  bool _sendToPatient = true;
  bool _sendToDoctor = false;

  void _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File selected: ${_selectedFile!.name} (${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File selection canceled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  void _submitResult() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a result file first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final patientEmail = (widget.booking['patientEmail'] ?? '')
        .toString()
        .trim();

    // Validate email delivery choices
    if (_sendToDoctor && _doctorEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter doctor email or uncheck "Send to Doctor".',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sendToPatient && patientEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No patient email found. Result will not be emailed to patient.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() => _isUploading = true);

    // Safely resolve booking id as a non-null String.
    final bookingId = (widget.booking["bookingId"] ?? '').toString();

    final resultPayload = {
      "bookingId": bookingId,
      // result_id will typically be generated server-side
      "status": "COMPLETED", // maps to test_result_status
      "resultDate": DateTime.now().toIso8601String().split('T').first,
      "fileName": _selectedFile!.name,
      "fileSize": _selectedFile!.size,
      "notes": _notesController.text,
    };

    try {
      String? base64Content;
      String? mimeType;

      try {
        final bytes = _selectedFile!.bytes;
        if (bytes != null) {
          base64Content = base64Encode(bytes);
          final lowerName = _selectedFile!.name.toLowerCase();
          if (lowerName.endsWith('.pdf')) {
            mimeType = 'application/pdf';
          } else if (lowerName.endsWith('.jpg') ||
              lowerName.endsWith('.jpeg')) {
            mimeType = 'image/jpeg';
          } else if (lowerName.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (lowerName.endsWith('.doc') ||
              lowerName.endsWith('.docx')) {
            mimeType =
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          } else {
            mimeType = 'application/octet-stream';
          }
        }
      } catch (_) {
        // ignore local encoding errors; backend call will still proceed
      }

      final ok = await backend.client.profile.uploadTestResult(
        bookingId: bookingId,
        staffId: null, // TODO: pass logged-in lab staff id when available
        status: resultPayload['status'] as String,
        resultDate: DateTime.parse(resultPayload['resultDate'] as String),
        attachmentPath: _selectedFile!.name,
        sendToPatient: _sendToPatient && patientEmail.isNotEmpty,
        sendToDoctor: _sendToDoctor,
        patientEmailOverride: _sendToPatient && patientEmail.isNotEmpty
            ? patientEmail
            : null,
        doctorEmailOverride:
            _sendToDoctor && _doctorEmailController.text.trim().isNotEmpty
            ? _doctorEmailController.text.trim()
            : null,
        attachmentFileName: _selectedFile!.name,
        attachmentContentBase64: base64Content,
        attachmentContentType: mimeType,
      );

      setState(() => _isUploading = false);

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload result to server.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onComplete(bookingId, "Completed");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Result for $bookingId uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading result: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _doctorEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = (widget.booking["bookingId"] ?? '').toString();
    final patientName = (widget.booking["patient"] ?? 'Unknown Patient')
        .toString();
    final patientEmail = (widget.booking["patientEmail"] ?? '')
        .toString()
        .trim();

    // Tests are stored as a list under the 'tests' key in the booking map.
    // Safely pick the first test name, falling back to a generic label.
    String testName = 'Lab Test';
    final tests = widget.booking["tests"];
    if (tests is List && tests.isNotEmpty) {
      final firstTest = tests.first;
      if (firstTest is Map && firstTest["test"] != null) {
        testName = firstTest["test"].toString();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Result: $bookingId'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.science, color: Colors.white),
                ),
                title: Text(
                  testName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Patient: $patientName\nBooking ID: $bookingId'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Result File",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_selectedFile != null)
                      Row(
                        children: [
                          Icon(
                            _getFileIcon(_selectedFile!.extension ?? ''),
                            size: 40,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatFileSize(_selectedFile!.size),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _selectFile,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _selectedFile == null
                              ? 'Select Result File'
                              : 'Change File',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Lab Tester Notes (Optional)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter any special observations or notes...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Email Delivery Options",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Send to Patient'),
                      subtitle: Text(
                        patientEmail.isEmpty
                            ? 'No patient email available'
                            : patientEmail,
                      ),
                      value: _sendToPatient,
                      onChanged: (v) {
                        setState(() {
                          _sendToPatient = v ?? true;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _doctorEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Email (optional)',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Send to Doctor'),
                      subtitle: Text(
                        _doctorEmailController.text.trim().isEmpty
                            ? 'Enter doctor email above'
                            : _doctorEmailController.text.trim(),
                      ),
                      value: _sendToDoctor,
                      onChanged: (v) {
                        setState(() {
                          _sendToDoctor = v ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _submitResult,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Submit Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
