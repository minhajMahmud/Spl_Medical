import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestResult {
  final String resultId;
  final String bookingId;
  final String patientName;
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

  final List<TestResult> _testResults = [
    TestResult(
      resultId: "RES001",
      bookingId: "BK001",
      patientName: "Rafi Ahmed",
      testName: "CBC",
      status: "COMPLETED",
      resultValue: "Normal",
      normalRange: "Normal",
      resultDate: DateTime(2024, 1, 15),
    ),
    TestResult(
      resultId: "RES002",
      bookingId: "BK002",
      patientName: "Maya Rahman",
      testName: "Blood Glucose",
      status: "PENDING",
    ),
    TestResult(
      resultId: "RES003",
      bookingId: "BK003",
      patientName: "Barsha Khan",
      testName: "Lipid Profile",
      status: "COMPLETED",
      resultValue: "CHO: 180 mg/dL\nTG: 150 mg/dL",
      normalRange: "CHO: <200 mg/dL\nTG: <150 mg/dL",
      resultDate: DateTime(2024, 1, 14),
    ),
  ];

  final TextEditingController _resultController = TextEditingController();
  final TextEditingController _rangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
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

  void _uploadResult(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(20),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Patient: ${_testResults[index].patientName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.science,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Test: ${_testResults[index].testName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _resultController,
                      decoration: InputDecoration(
                        labelText: 'Result Value',
                        hintText: 'Enter test result...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rangeController,
                      decoration: InputDecoration(
                        labelText: 'Normal Range',
                        hintText: 'e.g., 4.5-11.0 x10^9/L',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Alternative: Upload File',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _selectFile(),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Choose File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resultController.clear();
                        _rangeController.clear();
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _saveResult(index);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save Result'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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

  void _selectFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File selection would be implemented here')),
    );
  }

  void _saveResult(int index) {
    setState(() {
      _testResults[index] = TestResult(
        resultId: _testResults[index].resultId,
        bookingId: _testResults[index].bookingId,
        patientName: _testResults[index].patientName,
        testName: _testResults[index].testName,
        status: "COMPLETED",
        resultValue: _resultController.text,
        normalRange: _rangeController.text,
        resultDate: DateTime.now(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Result for ${_testResults[index].testName} uploaded successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );

    _resultController.clear();
    _rangeController.clear();
  }

  void _viewResultDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _testResults[index].resultValue != null
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${_testResults[index].testName} Result',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _testResults[index].resultValue != null
                                ? 'COMPLETED'
                                : 'PENDING',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test Details',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient & Booking Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF7C3AED),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Patient: ${_testResults[index].patientName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.bookmark,
                                color: Color(0xFF7C3AED),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Booking ID: ${_testResults[index].bookingId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_testResults[index].resultValue != null) ...[
                      // Result Value (Green)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          border: Border(
                            left: BorderSide(
                              color: const Color(0xFF10B981),
                              width: 4,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Result Value',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _testResults[index].resultValue!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Normal Range (Blue)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          border: Border(
                            left: BorderSide(color: Colors.blue, width: 4),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Normal Range',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _testResults[index].normalRange ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date (Grey)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey[400]!,
                              width: 4,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _testResults[index].resultDate
                                          ?.toString()
                                          .split(' ')[0] ??
                                      'N/A',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Pending Info (Orange)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEDEBD),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Result is pending. Upload the result when available.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (_testResults[index].status == "PENDING")
                      const SizedBox(width: 12),
                    if (_testResults[index].status == "PENDING")
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _uploadResult(index);
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Result'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "COMPLETED":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
          'Test Results Management',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
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
          IconButton(
            icon: Icon(Icons.filter_list, color: textColor),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testResults.length,
        itemBuilder: (context, index) {
          final result = _testResults[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: cardColor,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(result.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.status == "COMPLETED" ? Icons.task_alt : Icons.pending,
                  color: _getStatusColor(result.status),
                ),
              ),
              title: Text(
                result.testName,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: ${result.patientName}',
                    style: TextStyle(color: subtextColor),
                  ),
                  Text(
                    'Status: ${result.status}',
                    style: TextStyle(color: subtextColor),
                  ),
                  if (result.resultDate != null)
                    Text(
                      'Date: ${result.resultDate!.toString().split(' ')[0]}',
                      style: TextStyle(color: subtextColor),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (result.status == "PENDING")
                    IconButton(
                      icon: const Icon(Icons.upload, color: Colors.blue),
                      onPressed: () => _uploadResult(index),
                    ),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.green),
                    onPressed: () => _viewResultDetails(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewTest(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Results'),
              leading: Radio<String>(
                value: 'all',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Pending Only'),
              leading: Radio<String>(
                value: 'pending',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Completed Only'),
              leading: Radio<String>(
                value: 'completed',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _addNewTest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new test functionality would be implemented here'),
      ),
    );
  }
}
