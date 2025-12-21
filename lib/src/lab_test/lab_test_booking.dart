// lab_test_booking.dart (Updated Code with English text and correct currency symbol)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lab_test_list.dart'; // Assumed LabTest class and labTests list are available from this file

class LabTestBooking extends StatefulWidget {
  final String patientId;
  final String patientType;

  const LabTestBooking({
    super.key,
    required this.patientId,
    required this.patientType,
  });

  @override
  State<LabTestBooking> createState() => _LabTestBookingState();
}

class _LabTestBookingState extends State<LabTestBooking> {
  bool _isDarkMode = true;
  final List<LabTest> _selectedTests = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    // Pre-populate with a single test for demo purposes if needed
    // _toggleTestSelection(labTests.first);
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
    _totalAmount = 0.0;
    for (var test in _selectedTests) {
      _totalAmount += test.getFee(widget.patientType);
    }
  }

  void _proceedToPayment() {
    if (_selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one test')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient Header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED),
                        const Color(0xFF6D28D9),
                      ],
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
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Review and confirm your test booking',
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
                      // Patient Information
                      Text(
                        'Patient Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                  'ID: ${widget.patientId}',
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
                                  Icons.badge,
                                  color: Color(0xFF7C3AED),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Type: ${widget.patientType.toUpperCase()}',
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
                      const SizedBox(height: 20),
                      // Tests Summary
                      Text(
                        'Tests Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.science,
                                  color: Color(0xFF7C3AED),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedTests.length} test${_selectedTests.length > 1 ? 's' : ''} selected',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_selectedTests.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Total Amount
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7C3AED).withOpacity(0.1),
                              const Color(0xFF6D28D9).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Fee',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '৳${_totalAmount.toStringAsFixed(2)}',
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmBooking();
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Confirm & Pay'),
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
        );
      },
    );
  }

  void _confirmBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking successful! Total ৳${_totalAmount.toStringAsFixed(2)} booked for ${widget.patientId}.',
        ),
      ),
    );

    Navigator.pop(context, true);
    Navigator.pop(context, true);
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
        title: Text('Book Lab Tests', style: TextStyle(color: textColor)),
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
      body: Column(
        children: [
          // Patient Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient ID:',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      Text(
                        widget.patientId,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFeeChip(
                  'Type',
                  0,
                  true,
                ), // Placeholder chip for patient type
                _buildFeeChip(
                  widget.patientType.toUpperCase(),
                  // Pass a dummy fee to show the type
                  widget.patientType == 'student'
                      ? 0
                      : widget.patientType == 'employee'
                      ? 0
                      : 0,
                  true,
                ),
              ],
            ),
          ),

          // List of available tests
          Expanded(
            child: ListView.builder(
              itemCount: labTests.length,
              itemBuilder: (context, index) {
                final test = labTests[index];
                final isSelected = _selectedTests.contains(test);
                final fee = test.getFee(widget.patientType);

                return Card(
                  elevation: isSelected ? 4 : 1,
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : subtextColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      child: Icon(
                        Icons.medical_services_outlined,
                        color: isSelected ? Colors.blue.shade700 : Colors.grey,
                      ),
                    ),
                    title: Text(
                      test.testName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      test.description,
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${fee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        if (isSelected)
                          const Text(
                            'Selected',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => _toggleTestSelection(test),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _proceedToPayment,
                icon: const Icon(Icons.shopping_cart),
                label: Text(
                  'Book (${_selectedTests.length}) | Total Fee: ৳${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to display fee types as chips
  Widget _buildFeeChip(String label, double amount, bool isActive) {
    return Chip(
      // Corrected the currency symbol and formatting
      label: Text(amount > 0 ? '$label: ৳${amount.toStringAsFixed(0)}' : label),
      backgroundColor: isActive ? Colors.blue.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        fontSize: 10,
        color: isActive ? Colors.blue.shade800 : Colors.grey.shade600,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.all(0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
