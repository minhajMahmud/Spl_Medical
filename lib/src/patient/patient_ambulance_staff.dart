import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PatientAmbulanceStaff extends StatefulWidget {
  const PatientAmbulanceStaff({super.key});

  @override
  State<PatientAmbulanceStaff> createState() => _PatientAmbulanceStaffState();
}

class _PatientAmbulanceStaffState extends State<PatientAmbulanceStaff> {
  final Color kPrimaryColor = const Color(0xFF00796B);

  final String ambulanceContact1 = "+৮৮-০১৩৩৩১৯৯০৮৫ || +88-01333199085";
  final String ambulanceContact2 = "+৮৮-০১৭৭৬৫০৩৪৬৯ || +88-01776503469";

  final List<Map<String, String>> staffList = [
    {
      "name": "Dr. Mohammed Mafizul Islam",
      "designation": "Chief Medical officer (Administrative Charge)",
      "contact": "+88-01734956003",
    },
    {
      "name": "Dr. Esmat Ara Parvin",
      "designation": "Deputy Chief Medical officer (Current Charge)",
      "contact": "+88-01764341056",
    },
    {
      "name": "Dr. Shahjabin sharna",
      "designation": "Medical officer (Residence)",
      "contact": "+88-01728776208",
    },
    {
      "name": "Dr. Md. Rubel Sarder (Abdullah)",
      "designation": "Medical officer (Study Leave)",
      "contact": "+88-01729552944",
    },
    {
      "name": "Dr. Wakil Ahmed",
      "designation": "Medical officer",
      "contact": "+88-01751032351",
    },
    {
      "name": "Dr. Most. Mousumi Akther",
      "designation": "Medical officer (Maternity Leave)",
      "contact": "+88-01751692556",
    },
    {
      "name": "Mrs. Nomita Rani Dey",
      "designation": "Nurse",
      "contact": "+88-01865538596",
    },
    {
      "name": "Mr. Muhammad Jahidur Rahman",
      "designation": "Medical assistant",
      "contact": "+88-001712327649",
    },
    {
      "name": "Mrs. Najnin Akter",
      "designation": "Medical attendant",
      "contact": "+88-01887512822",
    },
    {"name": "Mrs. Salma Akter", "designation": "Care taker", "contact": "N/A"},
    {
      "name": "Mrs. Razia Akter",
      "designation": "Computer operator",
      "contact": "N/A",
    },
  ];

  Future<void> _makePhoneCall(String phoneNumber, String displayName) async {
    if (kIsWeb) {
      _showWebCallAlert(phoneNumber, displayName);
    } else {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch dialer for $phoneNumber")),
        );
      }
    }
  }

  void _showWebCallAlert(String phoneNumber, String displayName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.phone_disabled, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text("Call Not Available"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cannot make calls from web browser.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              "Phone: $phoneNumber",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Please use this number on your mobile device.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          ElevatedButton(
            onPressed: () {
              _copyToClipboard(phoneNumber, displayName);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text(
              "Copy Number",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String phoneNumber, String displayName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied $phoneNumber to clipboard"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _extractCleanNumber(String contact) {
    if (contact.contains("||")) {
      List<String> parts = contact.split("||");
      if (parts.length > 1) return parts[1].trim();
    }
    return contact.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Widget _buildStaffTile(Map<String, String> staff) {
    String cleanNumber = _extractCleanNumber(staff["contact"]!);
    bool hasNumber = staff["contact"] != "N/A";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor.withOpacity(0.1),
          child: Icon(Icons.person_outline, color: Colors.blueGrey),
        ),
        title: Text(
          staff["name"]!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${staff["designation"]!}\nContact: ${staff["contact"]!}",
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        isThreeLine: true,
        trailing: hasNumber
            ? IconButton(
                icon: Icon(
                  kIsWeb ? Icons.phone_disabled : Icons.call,
                  color: kPrimaryColor,
                ),
                onPressed: () {
                  if (kIsWeb) {
                    _showWebCallAlert(
                      staff["contact"]!,
                      "${staff["name"]!} - ${staff["designation"]!}",
                    );
                  } else {
                    _makePhoneCall(cleanNumber, staff["name"]!);
                  }
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Ambulance & Staff Contact",
          style: TextStyle(color: Colors.blueAccent),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ambulance Section
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                "🚨 Emergency Ambulance Contact",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: const Text(
                  "Ambulance Line 1",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  ambulanceContact1,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: IconButton(
                  icon: Icon(
                    kIsWeb ? Icons.phone_disabled : Icons.call,
                    color: Colors.red.shade700,
                  ),
                  onPressed: () {
                    if (kIsWeb) {
                      _showWebCallAlert(ambulanceContact1, "Ambulance Line 1");
                    } else {
                      _makePhoneCall("+8801333199085", "Ambulance Line 1");
                    }
                  },
                ),
              ),
            ),
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: const Text(
                  "Ambulance Line 2 (Backup)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  ambulanceContact2,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: IconButton(
                  icon: Icon(
                    kIsWeb ? Icons.phone_disabled : Icons.call,
                    color: Colors.red.shade700,
                  ),
                  onPressed: () {
                    if (kIsWeb) {
                      _showWebCallAlert(ambulanceContact2, "Ambulance Line 2");
                    } else {
                      _makePhoneCall("+8801776503469", "Ambulance Line 2");
                    }
                  },
                ),
              ),
            ),

            if (kIsWeb)
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Note: Direct calling is not available in web browsers. "
                          "Please use the phone numbers displayed or copy them to use on your mobile device.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Staff Section
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                "👨‍⚕️ Medical Staff",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Staff Tiles
            ...staffList.map(_buildStaffTile).toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
