import 'package:flutter/material.dart';
import 'prescription_page.dart';

class EmergencyCasesPage extends StatefulWidget {
  const EmergencyCasesPage({super.key});

  @override
  State<EmergencyCasesPage> createState() => _EmergencyCasesPageState();
}

class _EmergencyCasesPageState extends State<EmergencyCasesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'Unknown';

  final List<Map<String, dynamic>> _emergencyCases = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Cases'),
          foregroundColor: Colors.red,
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_alert), text: "New Case"),
              Tab(icon: Icon(Icons.history), text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ================= NEW CASE TAB ===================
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Patient Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 🔹 Name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name *',
                                prefixIcon: Icon(Icons.person),
                                border: UnderlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter patient name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // 🔹 Age + Gender
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Age *',
                                      prefixIcon: Icon(Icons.cake),
                                      border: UnderlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter age';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: const InputDecoration(
                                      labelText: 'Gender',
                                      border: UnderlineInputBorder(),
                                    ),
                                    items: ['Male', 'Female', 'Other']
                                        .map(
                                          (gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(gender),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 🔹 Phone
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone),
                                border: UnderlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),

                            // 🔹 Blood Group
                            DropdownButtonFormField<String>(
                              value: _selectedBloodGroup,
                              decoration: const InputDecoration(
                                labelText: 'Blood Group',
                                border: UnderlineInputBorder(),
                              ),
                              items:
                                  [
                                        'Unknown',
                                        'A+',
                                        'A-',
                                        'B+',
                                        'B-',
                                        'AB+',
                                        'AB-',
                                        'O+',
                                        'O-',
                                      ]
                                      .map(
                                        (bg) => DropdownMenuItem(
                                          value: bg,
                                          child: Text(bg),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBloodGroup = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final newCase = {
                              'name': _nameController.text,
                              'age': _ageController.text,
                              'gender': _selectedGender,
                              'phone': _phoneController.text,
                              'bloodGroup': _selectedBloodGroup,
                            };

                            setState(() {
                              _emergencyCases.insert(0, newCase);
                            });

                            _formKey.currentState!.reset();
                            _nameController.clear();
                            _ageController.clear();
                            _phoneController.clear();
                            _selectedGender = 'Male';
                            _selectedBloodGroup = 'Unknown';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrescriptionPage(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Prescription',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= CASE HISTORY TAB ===================
            _emergencyCases.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No previous emergency cases recorded',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _emergencyCases.length,
                    itemBuilder: (context, index) {
                      final caseData = _emergencyCases[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            caseData['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Age: ${caseData['age']} | Gender: ${caseData['gender']}',
                                ),
                                Text('Phone: ${caseData['phone']}'),
                                Text('Blood Group: ${caseData['bloodGroup']}'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
