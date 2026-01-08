import 'dart:convert';
import 'dart:io';

import 'package:backend_client/backend_client.dart' as backend;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestResult {
  final String resultId;
  final String bookingId;
  final String patientName;
  final String patientType;
  final String? patientId;
  final String patientEmail;
  final String? doctorId;
  final String? doctorEmail;
  final String testName;
  final String status;
  final String? resultValue;
  final String? normalRange;
  final String? attachmentPath;
  final DateTime? resultDate;

  TestResult({
    required this.resultId,
    required this.bookingId,
    required this.patientName,
    required this.patientType,
    this.patientId,
    required this.patientEmail,
    this.doctorId,
    this.doctorEmail,
    required this.testName,
    required this.status,
    this.resultValue,
    this.normalRange,
    this.attachmentPath,
    this.resultDate,
  });
}

class LabTestResults extends StatefulWidget {
  const LabTestResults({super.key});

  @override
  State<LabTestResults> createState() => _LabTestResultsState();
}

class _LabTestResultsState extends State<LabTestResults> {
  bool _isDarkMode = true;

  final TextEditingController _resultController = TextEditingController();
  final TextEditingController _rangeController = TextEditingController();

  /// One entry per test for each booking.
  /// Example: if a booking has tests A1 and A2, this list will contain
  /// two [TestResult] items so each test has its own separate upload option.
  List<TestResult> _testResults = [];

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadResultsFromBookings();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool('isDarkMode') ?? true);
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  /// Load all lab test bookings and expand them so each individual test
  /// becomes its own [TestResult] row.
  Future<void> _loadResultsFromBookings() async {
    final prefs = await SharedPreferences.getInstance();
    // 1) Expand locally stored bookings from SharedPreferences
    final rawList = prefs.getStringList('lab_test_bookings') ?? [];

    final Map<String, TestResult> resultsById = {};

    for (final encoded in rawList) {
      try {
        final Map<String, dynamic> booking =
            jsonDecode(encoded) as Map<String, dynamic>;

        final String bookingId = booking['bookingId']?.toString() ?? '';
        if (bookingId.isEmpty) continue;

        // Safely extract string values, handling potential byte arrays
        final patientRaw = booking['patient'];
        final String patientName = patientRaw is String
            ? patientRaw
            : (patientRaw?.toString().startsWith('Instance of') ?? false)
            ? 'Unknown Patient'
            : patientRaw?.toString() ?? '';

        final String patientType = booking['patientType']?.toString() ?? '';
        final String? patientId = booking['patientId']?.toString();

        final emailRaw = booking['patientEmail'];
        final String patientEmail = emailRaw is String
            ? emailRaw
            : (emailRaw?.toString().startsWith('Instance of') ?? false)
            ? ''
            : emailRaw?.toString() ?? '';

        final List tests = booking['tests'] as List? ?? [];

        for (final t in tests) {
          final Map<String, dynamic> test = t as Map<String, dynamic>;

          final String testId = test['testId']?.toString() ?? '';
          final String testName = test['test']?.toString() ?? '';
          if (testId.isEmpty) continue;

          final id = '${bookingId}_$testId';
          resultsById[id] = TestResult(
            resultId: id,
            bookingId: bookingId,
            patientName: patientName,
            patientType: patientType,
            patientId: patientId,
            patientEmail: patientEmail,
            doctorId: null,
            doctorEmail: null,
            testName: testName,
            status: 'PENDING',
          );
        }
      } catch (_) {
        // Ignore malformed entries and continue.
      }
    }

    // 2) Also expand bookings from backend database so that
    //    previous bookings stored in DB show up even after app restart.
    try {
      // Use generated profile endpoint that exposes the booking listing
      // (server-side name is ProfileEndpoint.listTestBookings).
      final rows = await backend.client.profile.listTestBookings();
      print('DEBUG: Loaded ${rows.length} test results from backend');

      for (final row in rows) {
        final String bookingId = row.bookingId;
        if (bookingId.isEmpty) continue;

        final bool isExternal = row.isExternalPatient;
        final String patientName =
            row.patientName ??
            (isExternal ? 'Walk-in Patient' : 'Unknown Patient');
        final String patientEmail = row.patientEmail ?? '';

        final String testId = row.testId.toString();
        final String testName = row.testName;
        if (testId.isEmpty) continue;

        final String rawStatus = row.status.isEmpty ? 'PENDING' : row.status;
        final String patientType = row.patientType.isEmpty
            ? 'outpatient'
            : row.patientType;

        final String id = '${bookingId}_$testId';
        resultsById[id] = TestResult(
          resultId: id,
          bookingId: bookingId,
          patientName: patientName,
          patientType: patientType,
          patientId: isExternal ? 'WALKIN:$bookingId' : row.patientId,
          patientEmail: patientEmail,
          doctorId: null,
          doctorEmail: null,
          testName: testName,
          status: rawStatus,
        );
      }

      print('DEBUG: Processed ${resultsById.length} test results total');
    } catch (e, st) {
      // ignore: avoid_print
      print('Error loading results from backend: $e\n$st');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading test results: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _testResults = resultsById.values.toList();
      });
    }
  }

  // ======================== UPLOAD RESULT ========================

  void _uploadResult(int index) {
    bool sendToPatient = true;
    bool sendToDoctor = true;
    String? selectedFileName;
    String? selectedFilePath;

    final test = _testResults[index];
    final TextEditingController doctorIdController = TextEditingController(
      text: test.doctorId ?? '',
    );
    final TextEditingController doctorEmailController = TextEditingController(
      text: test.doctorEmail ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Test Result',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Patient: ${test.patientName}\nTest: ${test.testName}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // BODY
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Result entry
                        TextFormField(
                          controller: _resultController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Result Value',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rangeController,
                          decoration: const InputDecoration(
                            labelText: 'Normal Range',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Auto-filled patient & doctor info
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Patient & Doctor Info',
                            style: Theme.of(dialogContext).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (test.patientId != null) ...[
                          TextFormField(
                            readOnly: true,
                            initialValue: test.patientId,
                            decoration: const InputDecoration(
                              labelText: 'Patient ID',
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextFormField(
                          readOnly: true,
                          initialValue: test.patientEmail,
                          decoration: const InputDecoration(
                            labelText: 'Patient Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Doctor info: editable so lab staff can enter/update
                        TextFormField(
                          controller: doctorIdController,
                          decoration: const InputDecoration(
                            labelText: 'Doctor ID (optional)',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: doctorEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Email (optional)',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        CheckboxListTile(
                          title: const Text('Send to Patient'),
                          subtitle: Text(test.patientEmail),
                          value: sendToPatient,
                          onChanged: (v) =>
                              setDialogState(() => sendToPatient = v ?? true),
                        ),

                        CheckboxListTile(
                          title: const Text('Send to Doctor'),
                          subtitle: Text(
                            doctorEmailController.text.isEmpty
                                ? 'Enter doctor email above'
                                : doctorEmailController.text,
                          ),
                          value: sendToDoctor,
                          onChanged: (v) =>
                              setDialogState(() => sendToDoctor = v ?? true),
                        ),

                        const SizedBox(height: 16),

                        // File attach section (PDF / documents)
                        const Divider(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Attach PDF / Document (optional)',
                            style: Theme.of(dialogContext).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'doc', 'docx'],
                                  );

                              if (result == null || result.files.isEmpty) {
                                return;
                              }

                              final file = result.files.single;

                              setDialogState(() {
                                selectedFileName = file.name;
                                selectedFilePath = file.path;
                              });
                            },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Choose File'),
                          ),
                        ),
                        if (selectedFileName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.description, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    selectedFileName!,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // FOOTER
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final hasTextResult = _resultController.text
                                  .trim()
                                  .isNotEmpty;
                              final hasFile = selectedFilePath != null;

                              if (!hasTextResult && !hasFile) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a result value or attach a file.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final now = DateTime.now();

                              setState(() {
                                _testResults[index] = TestResult(
                                  resultId: test.resultId,
                                  bookingId: test.bookingId,
                                  patientName: test.patientName,
                                  patientType: test.patientType,
                                  patientId: test.patientId,
                                  patientEmail: test.patientEmail,
                                  doctorId: doctorIdController.text.isNotEmpty
                                      ? doctorIdController.text
                                      : null,
                                  doctorEmail:
                                      doctorEmailController.text.isNotEmpty
                                      ? doctorEmailController.text
                                      : null,
                                  testName: test.testName,
                                  status: 'COMPLETED',
                                  resultValue: hasTextResult
                                      ? _resultController.text
                                      : test.resultValue,
                                  normalRange: hasTextResult
                                      ? _rangeController.text
                                      : test.normalRange,
                                  attachmentPath:
                                      selectedFilePath ?? test.attachmentPath,
                                  resultDate: now,
                                );
                              });

                              try {
                                String? base64Content;
                                String? mimeType;
                                String? fileName;

                                if (selectedFilePath != null &&
                                    selectedFilePath!.isNotEmpty) {
                                  try {
                                    final file = File(selectedFilePath!);
                                    if (await file.exists()) {
                                      final bytes = await file.readAsBytes();
                                      base64Content = base64Encode(bytes);
                                      fileName = selectedFileName;
                                      if (fileName != null &&
                                          fileName.toLowerCase().endsWith(
                                            '.pdf',
                                          )) {
                                        mimeType = 'application/pdf';
                                      } else if (fileName != null &&
                                          (fileName.toLowerCase().endsWith(
                                                '.jpg',
                                              ) ||
                                              fileName.toLowerCase().endsWith(
                                                '.jpeg',
                                              ))) {
                                        mimeType = 'image/jpeg';
                                      } else if (fileName != null &&
                                          fileName.toLowerCase().endsWith(
                                            '.png',
                                          )) {
                                        mimeType = 'image/png';
                                      } else if (fileName != null &&
                                          (fileName.toLowerCase().endsWith(
                                                '.doc',
                                              ) ||
                                              fileName.toLowerCase().endsWith(
                                                '.docx',
                                              ))) {
                                        mimeType =
                                            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
                                      } else {
                                        mimeType = 'application/octet-stream';
                                      }
                                    }
                                  } catch (_) {
                                    // ignore file read errors; backend call will
                                    // still go through without attachment.
                                  }
                                }

                                await backend.client.profile.uploadTestResult(
                                  bookingId: test.bookingId,
                                  staffId: doctorIdController.text.isNotEmpty
                                      ? doctorIdController.text.trim()
                                      : null,
                                  status: 'COMPLETED',
                                  resultDate: now,
                                  attachmentPath:
                                      selectedFilePath ?? test.attachmentPath,
                                  sendToPatient: sendToPatient,
                                  sendToDoctor: sendToDoctor,
                                  patientEmailOverride: sendToPatient
                                      ? test.patientEmail
                                      : null,
                                  doctorEmailOverride:
                                      sendToDoctor &&
                                          doctorEmailController.text
                                              .trim()
                                              .isNotEmpty
                                      ? doctorEmailController.text.trim()
                                      : null,
                                  attachmentFileName: fileName,
                                  attachmentContentBase64: base64Content,
                                  attachmentContentType: mimeType,
                                );
                              } catch (e, st) {
                                // ignore: avoid_print
                                print(
                                  'Failed to upload result to backend: $e\n$st',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Result saved locally but failed to sync with server.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }

                              _resultController.clear();
                              _rangeController.clear();
                              Navigator.pop(dialogContext);

                              // Reload results to show updated status
                              await _loadResultsFromBookings();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Result uploaded successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Text('Save Result'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ======================== UI ========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results Management'),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
                _saveTheme(_isDarkMode);
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _testResults.length,
        itemBuilder: (context, index) {
          final r = _testResults[index];
          return Card(
            child: ListTile(
              title: Text(r.testName),
              subtitle: Text(
                '${r.patientName} • ${r.status}' +
                    (r.attachmentPath != null ? ' • File attached' : ''),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r.status == "PENDING")
                    IconButton(
                      icon: const Icon(Icons.upload),
                      onPressed: () => _uploadResult(index),
                    ),
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
