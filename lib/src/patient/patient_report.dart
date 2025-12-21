import 'package:flutter/material.dart';

class PatientReports extends StatefulWidget {
  const PatientReports({super.key});

  @override
  State<PatientReports> createState() => _PatientReportsState();
}

class _PatientReportsState extends State<PatientReports> {
  final Color kPrimaryColor = const Color(0xFF00796B); // Deep Teal

  final List<Map<String, String?>> reports = const [
    {"date": "2025-10-23", "type": "Hb%", "notes": null},
    {"date": "2025-10-23", "type": "CBC", "notes": null},
    {
      "date": "2025-10-23",
      "type": "Lipid Profile (CHO,TG,HDL,LDL)",
      "notes": null,
    },
    {"date": "2025-10-23", "type": "Serum Bilirubin Total", "notes": null},
    {"date": "2025-10-23", "type": "SGPT", "notes": null},
    {"date": "2025-10-23", "type": "SGOT", "notes": null},
    {"date": "2025-10-23", "type": "Serum Creatinine", "notes": null},
    {"date": "2025-10-23", "type": "Glucose (Single Sample)", "notes": null},
    {"date": "2025-10-23", "type": "Serum Uric Acid", "notes": null},
    {"date": "2025-10-23", "type": "Serum Calcium", "notes": null},
    {"date": "2025-10-23", "type": "HbA1C", "notes": null},
    {"date": "2025-10-23", "type": "Blood Grouping & Rh Factor", "notes": null},
    {"date": "2025-10-23", "type": "CRP (Titre)", "notes": null},
    {"date": "2025-10-23", "type": "RA", "notes": null},
    {"date": "2025-10-23", "type": "ASO", "notes": null},
    {"date": "2025-10-23", "type": "Widal", "notes": null},
    {"date": "2025-10-23", "type": "Febrile Antigen", "notes": null},
    {"date": "2025-10-23", "type": "HBsAg (ICT)", "notes": null},
    {"date": "2025-10-23", "type": "Syphilis/TPHA (ICT)", "notes": null},
    {"date": "2025-10-23", "type": "Dengue Ns1", "notes": null},
    {"date": "2025-10-23", "type": "Dengue IgG/IgM", "notes": null},
    {"date": "2025-10-23", "type": "Malaria Parasite", "notes": null},
    {"date": "2025-10-23", "type": "Pregnancy Test (ICT)", "notes": null},
    {"date": "2025-10-23", "type": "Urine R/M/E", "notes": null},
    {"date": "2025-10-23", "type": "Dope Test (5 Parameters)", "notes": null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Reports",
          style: TextStyle(color: Colors.blueAccent),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: reports.length, // <-- show all reports
        itemBuilder: (context, index) {
          final report = reports[index]; // <-- no need to filter

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report["type"]!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: kPrimaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            report["date"]!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 20, thickness: 1),
                  Text(
                    "Notes: ${report["notes"]}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Downloading ${report["type"]} from ${report["date"]}...",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        "Download",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
