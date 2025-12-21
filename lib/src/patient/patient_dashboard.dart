import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';

class PatientDashboard extends StatefulWidget {
  final String name;
  final String email;
  final String? profilePictureUrl;

  const PatientDashboard({
    super.key,
    required this.name,
    required this.email,
    this.profilePictureUrl,
  });

  static Future<PatientDashboard> fromRouteArguments(
    Map<String, dynamic> arguments,
  ) async {
    // Do not read or return stored profile data here. The dashboard will
    // always query the backend for fresh profile data on init.
    return const PatientDashboard(name: '', email: '');
  }

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  late String name;
  late String email;
  late String? profilePictureUrl;
  bool _isLoading = true;
  String? _resolvedUserId;

  @override
  void initState() {
    super.initState();
    name = '';
    email = '';
    profilePictureUrl = null;

    // Always fetch fresh profile data from backend on page open.
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _resolvedUserId = prefs.getString('user_id');

      if (_resolvedUserId == null || _resolvedUserId!.isEmpty) {
        // No id available - prompt sign in
        setState(() {
          _isLoading = false;
        });
        _showDialog('Not signed in', 'Please sign in to view your dashboard.');
        return;
      }

      final profile = await client.patient.getPatientProfile(_resolvedUserId!);

      if (profile != null) {
        setState(() {
          name = profile.name;
          email = profile.email;
          profilePictureUrl = profile.profilePictureUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showDialog('No profile', 'No profile found for this user.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to fetch profile: $e');
      _showDialog('Error', 'Failed to fetch profile: $e');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double responsiveWidth(double w) => size.width * w / 375;
    double responsiveHeight(double h) => size.height * h / 812;

    // Dummy notifications - replace with dynamic data
    final List<Map<String, dynamic>> notifications = [
      {
        "icon": Icons.medical_services,
        "title": "Prescription Reminder",
        "subtitle": "Time to see your updated prescription.",
      },
      {
        "icon": Icons.science,
        "title": "Lab Report Result",
        "subtitle": "Your latest test results are in.",
      },
    ];

    // Build profile image widget
    Widget buildProfileImage() {
      if (profilePictureUrl == null || profilePictureUrl!.isEmpty) {
        print("Profile image: null or empty, showing default.");
        return const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 50, color: Colors.black54),
        );
      }

      String base64String = profilePictureUrl!.trim();

      try {
        if (base64String.startsWith('data:image')) {
          base64String = base64String.split(',').last;
        }

        base64String = base64String.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64.decode(base64String);

        if (bytes.isEmpty) throw Exception("Decoded bytes empty");

        return CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[300],
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        print("Error decoding profile image: $e");
        return const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 50, color: Colors.black54),
        );
      }
    }

    // Quick action card
    Widget buildActionCard({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color startColor = Colors.greenAccent,
      Color endColor = Colors.green,
      double width = 0,
    }) {
      return SizedBox(
        width: width,
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            shadowColor: Colors.black26,
            elevation: 4,
          ),
          onPressed: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [startColor.withOpacity(0.8), endColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: endColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsiveWidth(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsiveHeight(20)),

              // Avatar + Name + Email
              Center(
                child: Column(
                  children: [
                    Container(
                      width: responsiveWidth(100),
                      height: responsiveWidth(100),
                      child: buildProfileImage(),
                    ),
                    SizedBox(height: responsiveHeight(14)),
                    Text(
                      "Welcome, ${name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : ''}",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: responsiveHeight(4)),
                    Text(
                      "Your email: $email",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsiveHeight(24)),

              // Notifications
              const Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsiveHeight(12)),

              Column(
                children: notifications.map((notif) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(notif["icon"], color: Colors.green, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif["title"],
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif["subtitle"],
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: responsiveHeight(28)),

              // Quick Actions
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsiveHeight(12)),

              LayoutBuilder(
                builder: (context, constraints) {
                  double itemWidth =
                      (constraints.maxWidth - responsiveWidth(16)) / 2;

                  return Wrap(
                    spacing: responsiveWidth(16),
                    runSpacing: responsiveHeight(16),
                    children: [
                      buildActionCard(
                        icon: Icons.person,
                        label: "Profile",
                        onTap: () {
                          // Open profile page; profile page will fetch the data itself.
                          Navigator.pushNamed(context, '/patient-profile');
                        },
                        width: itemWidth,
                      ),
                      buildActionCard(
                        icon: Icons.medication,
                        label: "Prescriptions",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/patient-prescriptions',
                          );
                        },
                        width: itemWidth,
                      ),
                      buildActionCard(
                        icon: Icons.description,
                        label: "My Reports",
                        onTap: () {
                          Navigator.pushNamed(context, '/patient-reports');
                        },
                        width: itemWidth,
                      ),
                      buildActionCard(
                        icon: Icons.upload_file,
                        label: "Upload Results",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/patient-report-upload',
                          );
                        },
                        width: itemWidth,
                        startColor: Colors.blueAccent,
                        endColor: Colors.blue,
                      ),
                      buildActionCard(
                        icon: Icons.science_outlined,
                        label: "Lab Test Availability",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/patient-lab-availability',
                          );
                        },
                        width: itemWidth,
                        startColor: Colors.tealAccent,
                        endColor: Colors.teal,
                      ),
                      buildActionCard(
                        icon: Icons.local_hospital,
                        label: "See Ambulance & Staff",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/patient-ambulance-staff',
                          );
                        },
                        width: itemWidth,
                        startColor: Colors.orangeAccent,
                        endColor: Colors.deepOrange,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: responsiveHeight(20)),
            ],
          ),
        ),
      ),
    );
  }
}
