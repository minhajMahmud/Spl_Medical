import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart' as backend;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'lab_test_booking.dart';

class LabTestPanel extends StatefulWidget {
  const LabTestPanel({super.key});

  @override
  State<LabTestPanel> createState() => _LabTestPanelState();
}

class _LabTestPanelState extends State<LabTestPanel> {
  bool _isDarkMode = true;
  String _selectedFilter = 'All'; // All, Pending, Completed
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadBookings();
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

  Future<void> _loadBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1) Load legacy/local bookings from SharedPreferences
      final bookingsList = prefs.getStringList('lab_test_bookings') ?? [];

      final List<Map<String, dynamic>> localBookings = [];
      for (String bookingStr in bookingsList) {
        try {
          final booking = jsonDecode(bookingStr) as Map<String, dynamic>;
          localBookings.add(booking);
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing booking: $e');
        }
      }

      // 2) Load bookings from backend database (test_bookings table)
      final List<Map<String, dynamic>> backendBookings = [];
      try {
        final rows = await backend.client.profile.listTestBookings();
        print('DEBUG: Loaded ${rows.length} bookings from backend');

        for (final row in rows) {
          final rawBookingId = row.bookingId;
          if (rawBookingId.isEmpty) continue;

          // Normalize booking code to display-friendly format (e.g., BK000123)
          String bookingCode;
          final numericId = int.tryParse(rawBookingId);
          if (numericId != null) {
            bookingCode = 'BK${numericId.toString().padLeft(6, '0')}';
          } else {
            bookingCode = rawBookingId; // Fallback if already formatted
          }

          final bool isExternal = row.isExternalPatient;
          final String? dbPatientId = row.patientId;
          final String patientName =
              row.patientName ??
              (isExternal ? 'Walk-in Patient' : 'Unknown Patient');
          final String patientEmail = row.patientEmail ?? '';
          final String patientPhone = row.patientPhone ?? '';
          final String testId = row.testId.toString();
          final String testName = row.testName;

          final String status = row.status.isEmpty ? 'PENDING' : row.status;

          final String bookingDateStr = row.bookingDate;

          final double amount = row.outsideFee;

          final String patientType = row.patientType.isEmpty
              ? 'outpatient'
              : row.patientType;

          backendBookings.add({
            'bookingId': bookingCode,
            'patient': patientName,
            'patientId': isExternal
                ? 'WALKIN:$bookingCode'
                : (dbPatientId ?? ''),
            'dbPatientId': dbPatientId,
            'isExternalPatient': isExternal,
            'patientType': patientType,
            'tests': [
              {'testId': testId, 'test': testName, 'price': amount},
            ],
            'status': status,
            'bookingDate': bookingDateStr,
            'amount': amount,
            'patientEmail': patientEmail,
            'patientPhone': patientPhone,
          });
        }

        print('DEBUG: Processed ${backendBookings.length} backend bookings');
      } catch (e, st) {
        // ignore: avoid_print
        print('Error loading bookings from backend: $e\n$st');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading bookings from database: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      // 3) Merge local and backend bookings, preferring backend data
      final Map<String, Map<String, dynamic>> merged = {};

      String getUniqueKey(Map<String, dynamic> b) {
        final id = b['bookingId']?.toString() ?? '';
        final tests = b['tests'] as List?;
        if (tests != null && tests.isNotEmpty) {
          // Use first test ID as differentiator if available
          // This handles cases where one booking ID has multiple test rows (separate cards)
          final firstTest = tests.first;
          // Local/Backend test objects might differ but usually map to Map<String, dynamic>
          if (firstTest is Map) {
            final testId = firstTest['testId']?.toString() ?? '';
            if (testId.isNotEmpty) {
              return '${id}_$testId';
            }
          }
        }
        return id;
      }

      for (final b in localBookings) {
        final key = getUniqueKey(b);
        if (key.isNotEmpty) {
          merged[key] = b;
        }
      }

      for (final b in backendBookings) {
        final key = getUniqueKey(b);
        if (key.isNotEmpty) {
          merged[key] = b;
        }
      }

      final mergedList = merged.values.toList()
        ..sort((a, b) {
          final ad = a['bookingDate']?.toString() ?? '';
          final bd = b['bookingDate']?.toString() ?? '';
          return bd.compareTo(ad); // newest first
        });

      print('DEBUG: Total merged bookings: ${mergedList.length}');

      setState(() {
        _bookings = mergedList;
        _applyFilter();
      });
    } catch (e) {
      print('Error loading bookings: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredBookings = List.from(_bookings);
      } else if (_selectedFilter == 'Pending') {
        _filteredBookings = _bookings
            .where(
              (booking) =>
                  (booking['status'] as String?)?.toLowerCase().contains(
                    'pending',
                  ) ??
                  false,
            )
            .toList();
      } else if (_selectedFilter == 'Completed') {
        _filteredBookings = _bookings
            .where(
              (booking) =>
                  (booking['status'] as String?)?.toLowerCase().contains(
                    'completed',
                  ) ??
                  false,
            )
            .toList();
      }
    });
  }

  void _createNewBooking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientBookingEntry()),
    );

    if (result == true) {
      _loadBookings();
    }
  }

  void _uploadResult(Map<String, dynamic> booking) async {
    // Open backend-integrated result upload screen for this booking.
    final prefs = await SharedPreferences.getInstance();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultUploadScreen(
          booking: booking,
          onComplete: (bookingId, newStatus) {
            // Update in-memory booking status
            final idx = _bookings.indexWhere(
              (b) => b['bookingId']?.toString() == bookingId,
            );
            if (idx != -1) {
              _bookings[idx]['status'] = newStatus;
            }

            // Persist updated bookings back to SharedPreferences so that
            // filters (All / Pending / Completed) reflect the new status.
            final updatedList = _bookings
                .map((b) => jsonEncode(b))
                .toList()
                .cast<String>();
            prefs.setStringList('lab_test_bookings', updatedList);
          },
        ),
      ),
    );

    // After returning from upload screen, reload bookings to ensure the
    // latest state (including any external changes) is shown.
    if (mounted) {
      _loadBookings();
    }
  }

  Future<void> _downloadResult(String bookingId) async {
    try {
      if (bookingId.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading result for $bookingId...'),
          duration: const Duration(seconds: 1),
        ),
      );

      final resultJson = await backend.client.profile.downloadTestResult(
        bookingId,
      );
      if (resultJson.isEmpty) {
        throw Exception("Result file not found");
      }

      final Map<String, dynamic> result = jsonDecode(resultJson);
      final filename = result['filename'] as String? ?? 'result_$bookingId.pdf';
      final base64Data = result['data'] as String?;

      if (base64Data == null || base64Data.isEmpty) {
        throw Exception("Empty file content");
      }

      final Uint8List bytes = base64Decode(base64Data);

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", filename)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded $filename'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      Directory? baseDir;
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          baseDir = await getApplicationDocumentsDirectory();
        } else {
          // On Windows/Desktop
          try {
            baseDir = await getDownloadsDirectory();
          } catch (_) {}

          // Fallback for Windows if plugin fails (MissingPluginException)
          if (baseDir == null && Platform.isWindows) {
            final userProfile = Platform.environment['USERPROFILE'];
            if (userProfile != null) {
              final downloads = Directory('$userProfile\\Downloads');
              if (downloads.existsSync()) {
                baseDir = downloads;
              } else {
                final documents = Directory('$userProfile\\Documents');
                if (documents.existsSync()) {
                  baseDir = documents;
                }
              }
            }
          }

          // Fallback to application documents if still null
          baseDir ??= await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        // Absolute fallback for local dev
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          baseDir = Directory.current;
        } else {
          rethrow;
        }
      }

      final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = '${baseDir.path}${Platform.pathSeparator}$safeName';
      final file = File(path);

      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $safeName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(path),
            ),
          ),
        );

        // Auto open
        await OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Lab Test Bookings',
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
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFilterChip('All', textColor, subtextColor),
                const SizedBox(width: 12),
                _buildFilterChip('Pending', textColor, subtextColor),
                const SizedBox(width: 12),
                _buildFilterChip('Completed', textColor, subtextColor),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: _filteredBookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: subtextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_selectedFilter.toLowerCase()} bookings',
                          style: TextStyle(fontSize: 16, color: subtextColor),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredBookings.length,
                      itemBuilder: (context, index) {
                        return _buildBookingCard(
                          _filteredBookings[index],
                          cardColor,
                          textColor,
                          subtextColor,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewBooking,
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color textColor, Color subtextColor) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
            _applyFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : subtextColor.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final status = booking['status'] as String? ?? 'Unknown';
    final isPending = status.toLowerCase().contains('pending');
    final isCompleted = status.toLowerCase().contains('completed');

    Color statusColor;
    IconData statusIcon;
    if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending_actions;
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info;
    }

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking, textColor, subtextColor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['bookingId'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking['patient'] ?? 'Unknown Patient',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: subtextColor),
                  const SizedBox(width: 6),
                  Text(
                    booking['bookingDate'] ?? 'N/A',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.science, size: 14, color: subtextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${(booking['tests'] as List?)?.length ?? 0} test(s)',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ),
                  Text(
                    '৳${booking['amount']?.toString() ?? '0'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _uploadResult(booking),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload Result'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (isCompleted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final bookingId = booking['bookingId']?.toString() ?? '';
                      _downloadResult(bookingId);
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download Result'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(
    Map<String, dynamic> booking,
    Color textColor,
    Color subtextColor,
  ) {
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
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
                        const Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Booking ID',
                      booking['bookingId'] ?? 'N/A',
                    ),
                    _buildDetailRow('Patient', booking['patient'] ?? 'Unknown'),
                    _buildDetailRow(
                      'Patient ID',
                      booking['patientId'] ?? 'N/A',
                    ),
                    _buildDetailRow('Phone', booking['patientPhone'] ?? 'N/A'),
                    _buildDetailRow('Email', booking['patientEmail'] ?? 'N/A'),
                    _buildDetailRow('Date', booking['bookingDate'] ?? 'N/A'),
                    _buildDetailRow('Status', booking['status'] ?? 'Unknown'),
                    const Divider(height: 24),
                    const Text(
                      'Tests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(booking['tests'] as List?)?.map((test) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('• ${test['test'] ?? 'Unknown Test'}'),
                          );
                        }).toList() ??
                        [const Text('No tests')],
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Total Amount',
                      '৳${booking['amount']?.toString() ?? '0'}',
                      isBold: true,
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
