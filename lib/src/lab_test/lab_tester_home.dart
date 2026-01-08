import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart' as backend;
import 'dart:convert';
import 'lab_staff_profile.dart';
import 'lab_test_panel.dart';

class LabTesterHome extends StatefulWidget {
  const LabTesterHome({super.key});

  @override
  State<LabTesterHome> createState() => _LabTesterHomeState();
}

class _LabTesterHomeState extends State<LabTesterHome> {
  int _selectedIndex = 0;
  final Color primaryColor = Colors.blueAccent;
  final List<int> _navigationHistory = [];
  bool _isDarkMode = true;

  String name = "Lab Technician";
  String role = "Lab Technician";

  // Booking statistics
  int _totalBookings = 0;
  int _pendingBookings = 0;
  int _completedBookings = 0;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadProfileData();
    _loadBookingStats();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('user_id');

      if (uid == null || uid.isEmpty) return;

      final jsonData = await backend.client.adminEndpoints.getAdminProfile(uid);

      if (jsonData != null && jsonData.isNotEmpty && mounted) {
        final data = jsonDecode(jsonData) as Map<String, dynamic>;
        setState(() {
          name = data['name']?.toString() ?? 'Lab Technician';
          role =
              data['specialization']?.toString() ??
              data['role']?.toString() ??
              'Lab Technician';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading profile data: $e');
    }
  }

  Future<void> _loadBookingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1) Load legacy/local bookings from SharedPreferences
      final localList = prefs.getStringList('lab_test_bookings') ?? [];
      final Map<String, String> mergedStatus = {};

      for (final encoded in localList) {
        try {
          final data = jsonDecode(encoded) as Map<String, dynamic>;
          final id = data['bookingId']?.toString();
          if (id == null || id.isEmpty) continue;
          final status = (data['status'] as String?) ?? '';
          mergedStatus[id] = status;
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing local booking for stats: $e');
        }
      }

      // 2) Load bookings from backend database (test_bookings table)
      try {
        print('DEBUG: Attempting to connect to backend...');
        final rows = await backend.client.profile.listTestBookings();
        print(
          'DEBUG: Successfully connected! Loaded ${rows.length} bookings for stats from backend',
        );

        for (final row in rows) {
          final id = row.bookingId;
          if (id.isEmpty) continue;

          final status = row.status.isEmpty ? 'PENDING' : row.status;

          mergedStatus[id] = status;
        }

        print('DEBUG: Total bookings for stats: ${mergedStatus.length}');
      } catch (e, st) {
        // ignore: avoid_print
        print('Error loading booking stats from backend: $e\n$st');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot connect to backend server. Please check your connection.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      int total = mergedStatus.length;
      int pending = 0;
      int completed = 0;

      mergedStatus.forEach((_, status) {
        final lower = status.toLowerCase();
        if (lower.contains('pending')) {
          pending++;
        } else if (lower.contains('completed')) {
          completed++;
        }
      });

      if (mounted) {
        setState(() {
          _totalBookings = total;
          _pendingBookings = pending;
          _completedBookings = completed;
        });
      }
    } catch (e) {
      print('Error loading booking stats: $e');
    }
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
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF1A1F2E) : Colors.grey[50]!;
    final cardColor = _isDarkMode ? const Color(0xFF252B3D) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return WillPopScope(
      onWillPop: () async {
        if (_navigationHistory.isNotEmpty) {
          setState(() {
            _selectedIndex = _navigationHistory.removeLast();
          });
          return false;
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Exit App?"),
              content: const Text("Do you want to exit the application?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Yes"),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? "Home"
                : _selectedIndex == 1
                ? "Tests"
                : "Profile",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
          backgroundColor: bgColor,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: primaryColor,
              ),
              onPressed: () => _saveThemePreference(!_isDarkMode),
            ),
            IconButton(
              icon: const Icon(
                Icons.notification_add,
                color: Colors.blueAccent,
                size: 28,
              ),
              onPressed: () {
                // Handle notification tap
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No new notifications")),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _selectedIndex == 0
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.science,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role,
                                    style: TextStyle(color: subtextColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Today's Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: cardColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.pending_actions,
                                      size: 20,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "$_pendingBookings",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Pending Tests",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            color: cardColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.science,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "$_totalBookings",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total Tests",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.task_alt,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "$_completedBookings",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Completed",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              )
            : _selectedIndex == 1
            ? const LabTestPanel()
            : const LabTesterProfile(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index != _selectedIndex) {
              setState(() {
                _navigationHistory.add(_selectedIndex);
                _selectedIndex = index;
              });
              if (index == 0) {
                // Refresh stats when returning to Home tab so that
                // new bookings / completed tests are reflected.
                _loadBookingStats();
              }
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.science), label: "Tests"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
