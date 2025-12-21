import 'package:flutter/material.dart';
import 'prescription_page.dart'; // Ensure this exists

class PatientRecordsPage extends StatefulWidget {
  const PatientRecordsPage({super.key});

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _patients = [
      {
        'id': 'P2024001',
        'name': 'Md Sabbir Ahamed',
        'department': 'IIT',
        'session': '2021-2022',
        'bloodGroup': 'B+',
        'allergies': 'Dust, Dal',
        'lastVisit': '2024-01-15',
      },
      {
        'id': 'P2024002',
        'name': 'Fatama Khatun',
        'department': 'Pharmacy',
        'session': '2021-2022',
        'bloodGroup': 'O+',
        'allergies': 'None',
        'lastVisit': '2024-01-14',
      },
      {
        'id': 'P2024003',
        'name': 'Meraj',
        'department': 'EEE',
        'session': '2021-2022',
        'bloodGroup': 'A+',
        'allergies': 'Peanuts',
        'lastVisit': '2024-01-13',
      },
    ];
    _filteredPatients = _patients;
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPatients);
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _patients.where((patient) {
        return patient['id'].toLowerCase().contains(query) ||
            patient['name'].toLowerCase().contains(query) ||
            patient['department'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showCreateNewPatientDialog(String input) {
    final TextEditingController nameController = TextEditingController(
      text: input,
    );
    final TextEditingController ageController = TextEditingController();
    String id = 'P${DateTime.now().year}${_patients.length + 1}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Record Found"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Create a new patient record below.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Patient Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Age",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _patients.add({
                'id': id,
                'name': nameController.text,
                'age': ageController.text,
                'department': 'N/A',
                'session': 'N/A',
                'bloodGroup': 'N/A',
                'allergies': 'N/A',
                'lastVisit': DateTime.now().toString().split(' ')[0],
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "New record created for ${nameController.text}",
                  ),
                ),
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrescriptionPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              "Create & Go to Prescription",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PatientDetailsSheet(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Patient Record",
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Patient ID, Name or Department...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          if (_filteredPatients.isEmpty && query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.person_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    'No Record Found for "$query"',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text("Create New Patient Record"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                    ),
                    onPressed: () => _showCreateNewPatientDialog(query),
                  ),
                ],
              ),
            ),
          if (_filteredPatients.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = _filteredPatients[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      title: Text(patient['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${patient['id']}'),
                          Text(
                            '${patient['department']} - ${patient['session']}',
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _viewPatientDetails(patient),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class PatientDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsSheet({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, size: 30, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${patient['id']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Department', patient['department']),
          _buildInfoRow('Session', patient['session']),
          _buildInfoRow('Blood Group', patient['bloodGroup']),
          _buildInfoRow('Allergies', patient['allergies']),
          _buildInfoRow('Last Visit', patient['lastVisit']),
          const SizedBox(height: 24),
          const Text(
            'Medical History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.medical_services, color: Colors.green),
                  title: Text('Fever & Cold'),
                  subtitle: Text(
                    'Prescribed: Paracetamol, Antibiotics\nDate: 2024-01-15',
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.medical_services, color: Colors.orange),
                  title: Text('Stomach Infection'),
                  subtitle: Text(
                    'Prescribed: Antacids, Antibiotics\nDate: 2023-12-10',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrescriptionPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Create Prescription',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
