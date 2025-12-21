import 'package:flutter/material.dart';

class PatientLabTestAvailability extends StatefulWidget {
  const PatientLabTestAvailability({super.key});

  @override
  State<PatientLabTestAvailability> createState() =>
      _PatientLabTestAvailabilityState();
}

class _PatientLabTestAvailabilityState
    extends State<PatientLabTestAvailability> {
  final Color kPrimaryColor = const Color(0xFF00796B);

  // ✅ Real lab test data from your image
  final List<Map<String, dynamic>> labTestsDB = [
    {"name": "Hb%", "student": 60, "family": 80},
    {"name": "CBC", "student": 200, "family": 230},
    {"name": "Lipid Profile (CHO,TG,HDL,LDL)", "student": 450, "family": 500},
    {
      "name": "Serum Bilirubin Total",
      "student": 120,
      "family": 150,
      "patient": 200,
    },
    {"name": "SGPT", "student": 130, "family": 150, "patient": 220},
    {"name": "SGOT", "student": 130, "family": 150, "patient": 220},
    {"name": "Serum Creatinine", "student": 100, "family": 120},
    {"name": "Glucose (Single Sample)", "student": 60, "family": 80},
    {"name": "Serum Uric Acid", "student": 120, "family": 150},
    {"name": "Serum Calcium", "student": 150, "family": 200, "patient": 250},
    {"name": "HbA1C", "student": 300, "family": 350, "patient": 500},
    {"name": "Blood Grouping & Rh Factor", "student": 100, "family": 120},
    {"name": "CRP (Titre)", "student": 150, "family": 180},
    {"name": "RA", "student": 150, "family": 180},
    {"name": "ASO", "student": 180, "family": 220},
    {"name": "Widal", "student": 150, "family": 200},
    {"name": "Febrile Antigen", "student": 300, "family": 400},
    {"name": "HBsAg (ICT)", "student": 120, "family": 150, "patient": 200},
    {"name": "Syphilis/TPHA (ICT)", "student": 100, "family": 120},
    {"name": "Dengue Ns1", "student": 200, "family": 220},
    {"name": "Dengue IgG/IgM", "student": 250, "family": 250},
    {"name": "Malaria Parasite", "student": 150, "family": 200},
    {"name": "Pregnancy Test (ICT)", "student": 80, "family": 100},
    {"name": "Urine R/M/E", "student": 60, "family": 80},
    {"name": "Dope Test (5 Parameters)", "student": 600, "family": 700},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Lab Test Costs",
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: labTestsDB.length,
        itemBuilder: (context, index) {
          final test = labTestsDB[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test name
                  Text(
                    "${index + 1}. ${test["name"]}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cost table row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Student: ${test["student"]}৳",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        "Family: ${test["family"]}৳",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${test["name"]} test selected for booking.",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_task, color: Colors.white),
                      label: const Text(
                        "Book Test ?",
                        style: TextStyle(color: Colors.white),
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
