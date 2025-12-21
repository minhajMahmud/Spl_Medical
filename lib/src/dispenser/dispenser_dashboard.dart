import 'package:flutter/material.dart';
import 'dispenser_medicine_item.dart';
import 'dispenser_profile.dart';
import 'dispenser_logs.dart';
import 'dispenser_inventory.dart';

class Prescription {
  final String id;
  final String patientName;
  final String patientId;
  final String doctorName;
  final DateTime date;
  final String diagnosis;
  final List<Medicine> medicines;
  final String status;

  Prescription({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.doctorName,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    this.status = 'pending',
  });
}

class DispenseLog {
  final String id;
  final String dispenserId;
  final String dispenserName;
  final DateTime time;
  final String prescriptionId;
  final String patientId;
  final List<Map<String, dynamic>> items;

  DispenseLog({
    required this.id,
    required this.dispenserId,
    required this.dispenserName,
    required this.time,
    required this.prescriptionId,
    required this.patientId,
    required this.items,
  });
}

class DispenserDashboard extends StatefulWidget {
  const DispenserDashboard({super.key});

  @override
  State<DispenserDashboard> createState() => _DispenserDashboardState();
}

class _DispenserDashboardState extends State<DispenserDashboard> {
  final _searchController = TextEditingController();
  Prescription? _currentPrescription;
  bool _isLoading = false;
  int _selectedIndex = 0;
  String _searchQuery = '';
  final List<int> _navigationHistory = [0]; // Track tab navigation

  final List<DispenseLog> _dispenseLogs = [];
  final List<Prescription> _allPrescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    _allPrescriptions.addAll([
      Prescription(
        id: 'RX-001',
        patientName: 'Md Sabbir Ahamed',
        patientId: 'ASH2225005M',
        doctorName: 'Dr. Rahman',
        date: DateTime.now(),
        diagnosis: 'Fever and Cold',
        medicines: [
          Medicine(
            id: 'm1',
            name: 'Paracetamol',
            dose: '500mg - 1+0+1',
            prescribedQty: 20,
            stock: 15,
          ),
          Medicine(
            id: 'm2',
            name: 'Cough Syrup',
            dose: '10ml at night',
            prescribedQty: 1,
            stock: 8,
          ),
        ],
        status: 'pending',
      ),
      Prescription(
        id: 'RX-002',
        patientName: 'Fatima Begum',
        patientId: 'ASH2225006F',
        doctorName: 'Dr. Khan',
        date: DateTime.now().subtract(const Duration(days: 1)),
        diagnosis: 'Headache',
        medicines: [
          Medicine(
            id: 'm3',
            name: 'Ibuprofen',
            dose: '400mg - 0+0+1',
            prescribedQty: 10,
            stock: 25,
          ),
        ],
        status: 'completed',
      ),
      Prescription(
        id: 'RX-003',
        patientName: 'Rahim Ahmed',
        patientId: 'ASH2225007M',
        doctorName: 'Dr. Chowdhury',
        date: DateTime.now().subtract(const Duration(days: 2)),
        diagnosis: 'Allergy',
        medicines: [
          Medicine(
            id: 'm4',
            name: 'Cetirizine',
            dose: '10mg - 0+0+1',
            prescribedQty: 15,
            stock: 5,
          ),
        ],
        status: 'pending',
      ),
    ]);
  }

  List<Prescription> get _filteredPrescriptions {
    if (_searchQuery.isEmpty) return _allPrescriptions;
    return _allPrescriptions.where((prescription) {
      return prescription.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          prescription.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          prescription.patientId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _searchPrescription() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Prescription ID, Patient ID or Name')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _searchQuery = searchTerm;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _updateMedicine(Medicine updatedMed) {
    setState(() {
      if (_currentPrescription != null) {
        final index =
        _currentPrescription!.medicines.indexWhere((med) => med.id == updatedMed.id);
        if (index != -1) {
          _currentPrescription!.medicines[index] = updatedMed;
        }
      }
    });
  }

  void _dispensePrescription() {
    if (_currentPrescription == null) return;

    final dispensedItems = _currentPrescription!.medicines
        .where((med) => med.dispenseQty > 0)
        .map((med) {
      return {
        'id': med.id,
        'name': med.name,
        'dose': med.dose,
        'prescribedQty': med.prescribedQty,
        'dispenseQty': med.dispenseQty,
        'alternative': med.selectedAlternative?.name ?? 'N/A',
        'unitPrice': 10.0,
      };
    }).toList();

    if (dispensedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected for dispensing')),
      );
      return;
    }

    final newLog = DispenseLog(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      dispenserId: 'D-101',
      dispenserName: 'Dispenser User',
      time: DateTime.now(),
      prescriptionId: _currentPrescription!.id,
      patientId: _currentPrescription!.patientId,
      items: dispensedItems,
    );

    setState(() {
      _dispenseLogs.insert(0, newLog);
      final index = _allPrescriptions.indexWhere((p) => p.id == _currentPrescription!.id);
      if (index != -1) {
        _allPrescriptions[index] = Prescription(
          id: _currentPrescription!.id,
          patientName: _currentPrescription!.patientName,
          patientId: _currentPrescription!.patientId,
          doctorName: _currentPrescription!.doctorName,
          date: _currentPrescription!.date,
          diagnosis: _currentPrescription!.diagnosis,
          medicines: _currentPrescription!.medicines,
          status: 'completed',
        );
      }
      _currentPrescription = null;
      _searchController.clear();
      _searchQuery = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prescription dispensed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> _onWillPop() async {
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
          title: const Text("Exit App Confirmation",textAlign: TextAlign.center,),
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
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Prescription ID, Patient ID or Name',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
                    : null,
              ),
              onSubmitted: (_) => _searchPrescription(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchPrescription,
                icon: _isLoading
                    ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label:
                Text(_isLoading ? 'Searching...' : 'Search Prescriptions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionView() {
    if (_currentPrescription == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a prescription to begin dispensing',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prescription #${_currentPrescription!.id}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          _currentPrescription!.status.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor:
                        _currentPrescription!.status == 'completed'
                            ? Colors.green
                            : Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Patient: ${_currentPrescription!.patientName} (${_currentPrescription!.patientId})'),
                  Text('Doctor: ${_currentPrescription!.doctorName}'),
                  Text(
                      'Date: ${_currentPrescription!.date.toString().split(' ')[0]}'),
                  Text('Diagnosis: ${_currentPrescription!.diagnosis}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_currentPrescription!.status == 'pending') ...[
            const Text(
              'Medicines to Dispense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._currentPrescription!.medicines.map((med) {
              return MedicineItem(
                key: ValueKey(med.id),
                medicine: med,
                onChanged: _updateMedicine,
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _dispensePrescription,
                icon: const Icon(Icons.medication, color: Colors.white),
                label: const Text(
                  'Dispense Prescription',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'This prescription has been dispensed',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllPrescriptionsList() {
    final prescriptions = _filteredPrescriptions;
    if (prescriptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No prescriptions found',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = prescriptions[index];
        final isCompleted = prescription.status == 'completed';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.pending_actions,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
            title: Text('Prescription #${prescription.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient: ${prescription.patientName}'),
                Text('Doctor: ${prescription.doctorName}'),
                Text('Medicines: ${prescription.medicines.length} items'),
              ],
            ),
            trailing: Chip(
              label: Text(
                prescription.status.toUpperCase(),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: isCompleted ? Colors.green : Colors.blue,
            ),
            onTap: () {
              setState(() {
                _currentPrescription = prescription;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? 'Dispenser Dashboard'
                : _selectedIndex == 1
                ? 'Inventory Management'
                : 'Dispense History',
            style: const TextStyle(color: Colors.blueAccent),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueAccent,
          elevation: 0,
          actions: [
            if (_selectedIndex == 0) ...[
              IconButton(
                icon: const Icon(Icons.notifications,color: Colors.blueAccent,),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
            ],
            IconButton(
              icon: const Icon(Icons.person,color: Colors.blueAccent,),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DispenserProfile()),
                );
              },
            ),
          ],
        ),

        body: _selectedIndex == 0
            ? Column(
          children: [
            _buildSearchSection(),
            if (_currentPrescription != null)
              Expanded(child: _buildPrescriptionView())
            else
              Expanded(child: _buildAllPrescriptionsList()),
          ],
        )
            : _selectedIndex == 1
            ? const InventoryManagement()
            : DispenseLogsScreen(logs: _dispenseLogs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_navigationHistory.isEmpty ||
                _navigationHistory.last != index) {
              _navigationHistory.add(index);
            }
            setState(() => _selectedIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'Dispense',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
