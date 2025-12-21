// lab_test_panel.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lab_booking_entry.dart';

class LabTestPanel extends StatefulWidget {
  const LabTestPanel({super.key});

  @override
  State<LabTestPanel> createState() => _LabTestPanelState();
}

class _LabTestPanelState extends State<LabTestPanel> {
  bool _isDarkMode = true;
  final List<Map<String, dynamic>> _bookedTests = [
    {
      "bookingId": "BK004",
      "patient": "Kamrul Islam",
      "patientId": "emp123",
      "patientType": "employee",
      "test": "Lipid Profile",
      "testId": "10",
      "status": "Sample Pending",
      "bookingDate": "2024-10-08",
      "amount": 450.0,
    },
    {
      "bookingId": "BK003",
      "patient": "Ayesha Begum",
      "patientId": "WALKIN:01712345678",
      "patientType": "out_patient",
      "test": "Urine R/M/E",
      "testId": "04",
      "status": "In Progress",
      "bookingDate": "2024-10-09",
      "amount": 150.0,
    },
    {
      "bookingId": "BK002",
      "patient": "Maya Rahman",
      "patientId": "stu123",
      "patientType": "student",
      "test": "Blood Grouping",
      "testId": "08",
      "status": "In Progress",
      "bookingDate": "2024-10-09",
      "amount": 60.0,
    },
    {
      "bookingId": "BK001",
      "patient": "Rafi Ahmed",
      "patientId": "STU2024001",
      "patientType": "student",
      "test": "CBC",
      "testId": "02",
      "status": "Completed",
      "bookingDate": "2024-10-08",
      "amount": 200.0,
    },
    {
      "bookingId": "BK005",
      "patient": "Barsha Islam",
      "patientId": "STU2024002",
      "patientType": "student",
      "test": "Blood Glucose",
      "testId": "08",
      "status": "Sample Pending",
      "bookingDate": "2024-10-10",
      "amount": 60.0,
    },
    {
      "bookingId": "BK006",
      "patient": "Habiba Sultana",
      "patientId": "EMP456",
      "patientType": "employee",
      "test": "CBC",
      "testId": "02",
      "status": "Completed",
      "bookingDate": "2024-10-09",
      "amount": 230.0,
    },
  ];

  String _searchQuery = '';
  String _selectedStatus = 'All';

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

  void _updateBookingStatus(String bookingId, String newStatus) {
    setState(() {
      final index = _bookedTests.indexWhere((b) => b["bookingId"] == bookingId);
      if (index != -1) {
        _bookedTests[index]["status"] = newStatus;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking $bookingId updated to "$newStatus"'),
            backgroundColor: newStatus == "Completed"
                ? Colors.green
                : newStatus == "In Progress"
                ? Colors.blue
                : newStatus == "Sample Pending"
                ? Colors.orange
                : Colors.grey,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final bgColor = _isDarkMode ? const Color(0xFF1A1F2E) : Colors.grey[50]!;
    final cardColor = _isDarkMode ? const Color(0xFF252B3D) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    // Inline filtered bookings
    List<Map<String, dynamic>> filteredBookings = _bookedTests;
    if (_selectedStatus != 'All') {
      filteredBookings = filteredBookings
          .where((b) => b["status"] == _selectedStatus)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredBookings = filteredBookings.where((b) {
        return b["patient"].toLowerCase().contains(q) ||
            b["patientId"].toLowerCase().contains(q) ||
            b["test"].toLowerCase().contains(q) ||
            b["bookingId"].toLowerCase().contains(q);
      }).toList();
    }

    List<Map<String, dynamic>> pendingBookings = filteredBookings
        .where((b) => b["status"] != "Completed")
        .toList();

    Color getStatusColor(String status) {
      switch (status) {
        case "Completed":
          return Colors.green;
        case "In Progress":
          return Colors.blue;
        case "Sample Pending":
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Container(
            color: cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.list_alt), text: 'Bookings'),
                      Tab(
                        icon: Icon(Icons.science_outlined),
                        text: 'Result/Sample Action',
                      ),
                    ],
                    labelColor: const Color(0xFF7C3AED),
                    unselectedLabelColor: textColor.withOpacity(0.6),
                  ),
                ),
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
          ),
        ),
        body: Column(
          children: [
            // Inline Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: bgColor,
              child: Column(
                children: [
                  TextField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText:
                          'Search by patient name, ID, test, or booking ID...',
                      hintStyle: TextStyle(color: subtextColor),
                      prefixIcon: Icon(Icons.search, color: subtextColor),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            'All',
                            'Sample Pending',
                            'In Progress',
                            'Completed',
                          ].map((status) {
                            bool isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = selected ? status : 'All';
                                  });
                                },
                                backgroundColor: cardColor,
                                selectedColor: getStatusColor(
                                  status,
                                ).withOpacity(0.2),
                                checkmarkColor: getStatusColor(status),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? getStatusColor(status)
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
            // Tab View
            Expanded(
              child: TabBarView(
                children: [
                  // Bookings Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // New Booking
                        Card(
                          elevation: 2,
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Start New Test Booking",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Search for a registered patient ID or select a Walk-in type.",
                                  style: TextStyle(color: subtextColor),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PatientBookingEntry(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_box),
                                    label: const Text('Select Patient/Type'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Results Count
                        Row(
                          children: [
                            Text(
                              "Bookings",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filteredBookings.length} found',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (filteredBookings.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: subtextColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookings found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search or filter',
                                  style: TextStyle(color: subtextColor),
                                ),
                              ],
                            ),
                          )
                        else
                          ...filteredBookings.map((booking) {
                            return Card(
                              elevation: 1,
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: getStatusColor(
                                    booking["status"],
                                  ),
                                  child: Text(
                                    booking["bookingId"].toString().substring(
                                      2,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${booking["test"]}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  '${booking["patient"]} (${booking["patientId"]})\nDate: ${booking["bookingDate"]} | Fee: ৳${booking["amount"].toStringAsFixed(0)}',
                                  style: TextStyle(color: subtextColor),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(
                                      booking["status"],
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    booking["status"],
                                    style: TextStyle(
                                      color: getStatusColor(booking["status"]),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Viewing booking ${booking["bookingId"]}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  // Result / Sample Action Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Results Count
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Action Required: Sample & Result Entry",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pendingBookings.length} pending',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        if (pendingBookings.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 64,
                                  color: Colors.green.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "🎉 All booked tests have been processed and completed.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No pending tests match your search criteria',
                                  style: TextStyle(color: subtextColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...pendingBookings.map((booking) {
                            final status = booking["status"];
                            final bookingId = booking["bookingId"];
                            Widget actionButton;
                            if (status == "Sample Pending") {
                              actionButton = ElevatedButton.icon(
                                onPressed: () => _updateBookingStatus(
                                  bookingId,
                                  "In Progress",
                                ),
                                icon: const Icon(Icons.colorize),
                                label: const Text('Collect Sample'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              );
                            } else if (status == "In Progress") {
                              actionButton = ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResultUploadScreen(
                                        booking: booking,
                                        onComplete: _updateBookingStatus,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Result (File)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              );
                            } else {
                              actionButton = const SizedBox.shrink();
                            }

                            return Card(
                              elevation: 2,
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.science,
                                        color: getStatusColor(status),
                                      ),
                                      title: Text(
                                        '${booking["test"]} (${booking["bookingId"]})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${booking["patient"]} (${booking["patientId"]})\nStatus: $status',
                                        style: TextStyle(color: subtextColor),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(
                                            status,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 10),
                                    actionButton,
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ResultUploadScreen inline version
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
  bool _isUploading = false;

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
        const SnackBar(content: Text('Please select a result file to upload.')),
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Result file "${_selectedFile!.name}" uploaded successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );
    widget.onComplete(widget.booking["bookingId"], "Completed");
    if (mounted) {
      Navigator.pop(context);
    }
  }

  IconData _getFileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
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
  Widget build(BuildContext context) {
    final bookingId = widget.booking["bookingId"];
    final patientName = widget.booking["patient"];
    final testName = widget.booking["test"];
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
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(
                  patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Test: $testName'),
                trailing: Text(bookingId),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Upload Result File (PDF/Image/Document)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedFile == null)
                    const Column(
                      children: [
                        Icon(Icons.cloud_upload, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No file selected',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          _getFileIcon(_selectedFile!.extension),
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatFileSize(_selectedFile!.size),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${_selectedFile!.extension?.toUpperCase() ?? 'Unknown'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: Colors.green.shade600),
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
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isUploading
                  ? ElevatedButton(
                      onPressed: null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Uploading...'),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _submitResult,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Submit Result and Complete Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
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
