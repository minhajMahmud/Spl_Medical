import 'package:flutter/material.dart';
import 'user_management.dart';
import 'inventory_management.dart';
import 'reports_analytics.dart';
import 'history_screen.dart';
import 'staff_rostering.dart';
import 'admin_profile.dart'; // Dedicated profile screen

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF00796B); // Deep Teal (For consistency)
  final Color accentColor = const Color(0xFF80CBC4); // Light Teal

  // navigation history like DoctorDashboard
  final List<int> _navigationHistory = [];

  final List<Widget> _pages = [
    const UserManagement(),
    const InventoryManagement(),
    const ReportsAnalytics(),
    const HistoryScreen(),
    const StaffRostering(),
  ];

  final List<String> _titles = const [
    "User Management",
    "Inventory Management",
    "Reports & Analytics",
    "Audit History",
    "Staff Rostering"
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_navigationHistory.isNotEmpty) {
          setState(() {
            _selectedIndex = _navigationHistory.removeLast();
          });
          return false;
        } else {
          // If no history, show exit confirmation dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Exit App Confirmation"),
              content: const Text("Do you want to exit?"),
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
        backgroundColor: Colors.white, // Setting scaffold background for AppBar elevation effect
        appBar: AppBar(
          title: Text(
            _titles[_selectedIndex],
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blueAccent), // Color changed to white
          ),
          backgroundColor: Colors.white, // Fixed to Deep Teal
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon:
              const Icon(Icons.account_circle, color: Colors.blueAccent, size: 28), // Color changed to white
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminProfile()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor, // Fixed to Deep Teal
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              // Add to history only if the index is changing
              if (index != _selectedIndex) {
                _navigationHistory.add(_selectedIndex);
                _selectedIndex = index;
              }
            });
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.people), label: "Users"),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory), label: "Inventory"),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: "Reports"),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(
                icon: Icon(Icons.schedule), label: "Roster"),
          ],
        ),
      ),
    );
  }
}