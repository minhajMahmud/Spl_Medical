import 'package:flutter/material.dart';
import 'dispenser_dashboard.dart'; // This imports the DispenseLog class

class DispenseLogsScreen extends StatelessWidget {
  final List<DispenseLog> logs;

  const DispenseLogsScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: logs.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No dispensing history yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log #${log.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Prescription: ${log.prescriptionId}'),
                  Text('Patient: ${log.patientId}'),
                  Text('Dispenser: ${log.dispenserName}'),
                  Text('Time: ${log.time.toString().split('.')[0]}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Items Dispensed:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...log.items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      '• ${item['name']} - ${item['dispenseQty']} units',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}