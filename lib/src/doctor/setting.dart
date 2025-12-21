import 'package:flutter/material.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool _notificationsEnabled = true; // default ON

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.blueAccent),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // 🔔 Notification toggle (manual code instead of function)
          SwitchListTile(
            title: const Text(
              "Notifications",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text("Turn app notifications on/off"),
            value: _notificationsEnabled,
            activeColor: Colors.blueAccent,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _notificationsEnabled
                        ? 'Notifications turned ON'
                        : 'Notifications turned OFF',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            secondary: const Icon(
              Icons.notifications_active,
              color: Colors.blueAccent,
            ),
          ),

          // 🚪 Logout button (manual code instead of function)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Logged out successfully"),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/', // তোমার HomePage route name
                          (route) => false, // আগের সব route মুছে দেয়
                        );
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
