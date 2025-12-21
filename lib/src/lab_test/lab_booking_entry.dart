import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lab_test_booking.dart';

class PatientBookingEntry extends StatefulWidget {
  const PatientBookingEntry({super.key});

  @override
  State<PatientBookingEntry> createState() => _PatientBookingEntryState();
}

class _PatientBookingEntryState extends State<PatientBookingEntry> {
  bool _isDarkMode = true;
  final TextEditingController _idController = TextEditingController();

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

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _navigateToBooking(String patientId, String patientType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LabTestBooking(patientId: patientId, patientType: patientType),
      ),
    );
  }

  void _searchRegisteredPatient() {
    final patientId = _idController.text.trim();
    if (patientId.isEmpty) {
      _showSnackBar("Please enter a Patient ID");
      return;
    }

    String type;
    if (patientId.toUpperCase().startsWith('STU')) {
      type = 'student';
    } else if (patientId.toUpperCase().startsWith('EMP')) {
      type = 'employee';
    } else if (patientId.toUpperCase().startsWith('OUT')) {
      type = 'out_patient';
    } else {
      _showSnackBar(
        "Unknown ID prefix! Please enter correct ID or use Walk-in.",
      );
      return;
    }

    _navigateToBooking(patientId, type);
  }

  void _showWalkInDialog(String type) {
    String labelText = type == 'student'
        ? 'Student ID or Email'
        : type == 'employee'
        ? 'Employee ID or Email'
        : 'Out Patient Name or Phone Number';

    String hintText = type == 'student'
        ? 'e.g., 2024001 or name@nstu.edu.bd'
        : type == 'employee'
        ? 'e.g., EMP123 or employee@nstu.edu.bd'
        : 'e.g., John Doe or 017xxxxxxxx';

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${type.toUpperCase()} Details'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final walkInId = controller.text.trim();
              if (walkInId.isEmpty) {
                _showSnackBar(
                  "Please enter valid ${type == 'out_patient' ? 'Name/Number' : 'ID/Email'}",
                );
                return;
              }
              Navigator.pop(context);
              _navigateToBooking("WALKIN:$walkInId", type);
            },
            child: const Text('Start Booking'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        title: Text('Start Booking', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section title (was _buildSection) ---
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '1. Search Registered Patient',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // --- Card for registered patient search ---
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Enter Patient ID (STU, EMP, or OUT prefix):",
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _idController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Patient ID',
                        labelStyle: TextStyle(color: subtextColor),
                        hintText: 'Example: STU2024001',
                        hintStyle: TextStyle(color: subtextColor),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: subtextColor),
                        ),
                        prefixIcon: Icon(Icons.badge, color: subtextColor),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _searchRegisteredPatient,
                      icon: const Icon(Icons.search),
                      label: const Text('Search and Start Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 30),

            // --- Section title (was _buildSection) ---
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '2. Walk-in Booking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // --- Card for walk-in patient ---
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Patient Type for walk-in booking:",
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      children: [
                        // --- Button (was _buildTypeButton) ---
                        ElevatedButton(
                          onPressed: () => _showWalkInDialog('student'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Student'),
                        ),

                        // --- Button (was _buildTypeButton) ---
                        ElevatedButton(
                          onPressed: () => _showWalkInDialog('employee'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Employee'),
                        ),

                        // --- Button (was _buildTypeButton) ---
                        ElevatedButton(
                          onPressed: () => _showWalkInDialog('out_patient'),
                          child: const Text('Out Patient'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
