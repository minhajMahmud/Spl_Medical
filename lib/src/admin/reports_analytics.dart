import 'package:flutter/material.dart';

class ReportsAnalytics extends StatelessWidget {
  const ReportsAnalytics({super.key});

  final Color primaryColor = const Color(0xFF00796B); // Deep Teal

  // Sample data for reports
  final List<Map<String, dynamic>> prescriptionReports = const [
    {"period": "Today", "value": 128, "unit": "Prescriptions"},
    {"period": "This Week", "value": 560, "unit": "Prescriptions"},
    {"period": "This Month", "value": 2300, "unit": "Prescriptions"},
  ];

  final List<Map<String, dynamic>> diseaseTrends = const [
    {"disease": "Influenza", "monthlyCases": 128},
    {"disease": "Hypertension", "monthlyCases": 95},
    {"disease": "Diabetes", "monthlyCases": 80},
    {"disease": "COVID-19", "monthlyCases": 35},
  ];

  // Helper widget to simulate a visual data card
  Widget _buildReportCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to simulate a Bar Chart for Disease Trends
  Widget _buildTrendBar(String disease, int cases, double maxCases) {
    double ratio = cases / maxCases;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$disease: $cases Cases",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 10,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalPrescriptions = prescriptionReports.fold(
      0,
      (sum, item) => sum + (item['value'] as int),
    );
    final double maxCases = diseaseTrends
        .map((e) => e['monthlyCases'] as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Key Metrics Section ---
            const Text(
              "Key Metrics (Cumulative)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildReportCard(
                  "Total Prescriptions",
                  totalPrescriptions,
                  Icons.local_hospital_outlined,
                  primaryColor,
                ),
                _buildReportCard(
                  "Outside Patients",
                  21,
                  Icons.person_search_outlined,
                  Colors.orange,
                ),
                _buildReportCard(
                  "Medicines Dispensed",
                  10500,
                  Icons.inventory_outlined,
                  Colors.teal,
                ),
                _buildReportCard(
                  "Staff Active",
                  45,
                  Icons.groups_outlined,
                  Colors.blueGrey,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Prescription Activity Section ---
            Text(
              "Prescription Activity",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const Divider(),
            ...prescriptionReports.map(
              (report) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.receipt, color: primaryColor),
                  title: Text(
                    report['period'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "${report['value']} ${report['unit']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Disease Trends Section (Simulated Bar Chart) ---
            Text(
              "Top Monthly Disease Trends",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const Divider(),
            ...diseaseTrends.map(
              (disease) => _buildTrendBar(
                disease['disease'],
                disease['monthlyCases'],
                maxCases,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
