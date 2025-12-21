import 'package:flutter/material.dart';

// 1. Define a class to hold the data for each medicine row
class Medicine {
  TextEditingController nameController = TextEditingController();
  TextEditingController dosageController = TextEditingController();
  TextEditingController durationController = TextEditingController();

  Medicine();

  Medicine.withData(String name, String dosage, String duration) {
    nameController.text = name;
    dosageController.text = dosage;
    durationController.text = duration;
  }
}

class PrescriptionPage extends StatefulWidget {
  const PrescriptionPage({super.key});

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  // Controllers for all fields
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _complainController = TextEditingController();
  final TextEditingController _examinationController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  final TextEditingController _testsController = TextEditingController();

  List<Medicine> _medicineRows = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _initializeMedicineRows(7);
  }

  void _initializeMedicineRows(int count) {
    _medicineRows = [];
    for (int i = 0; i < count; i++) {
      _medicineRows.add(Medicine());
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _complainController.dispose();
    _examinationController.dispose();
    _adviceController.dispose();
    _testsController.dispose();
    for (var medicine in _medicineRows) {
      medicine.nameController.dispose();
      medicine.dosageController.dispose();
      medicine.durationController.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(3000),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _addMedicineRow() {
    setState(() {
      _medicineRows.add(Medicine());
    });
  }

  Map<String, dynamic> getPrescriptionData() {
    final date = selectedDate ?? DateTime.now();
    final List<Map<String, String>> medicines = _medicineRows
        .map(
          (m) => {
            'name': m.nameController.text.trim(),
            'dosage': m.dosageController.text.trim(),
            'duration': m.durationController.text.trim(),
          },
        )
        .where((m) => m.values.any((value) => value.isNotEmpty))
        .toList();

    return {
      'university': 'Noakhali Science and Technology University',
      'roll': _rollController.text.trim(),
      'name': _nameController.text.trim(),
      'age': _ageController.text.trim(),
      'gender': _genderController.text.trim(),
      'date': date.toIso8601String(),
      'complaints': _complainController.text.trim(),
      'examination': _examinationController.text.trim(),
      'medicines': medicines,
      'advice': _adviceController.text.trim(),
      'tests': _testsController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'doctorSignature': "Doctor's Signature",
    };
  }

  void savePrescription() {
    final prescriptionData = getPrescriptionData();
    print('Prescription Data for Database: $prescriptionData');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prescription Saved Successfully")),
    );
  }

  void clearForm() {
    for (var medicine in _medicineRows) {
      // Dispose old controllers
      medicine.nameController.dispose();
      medicine.dosageController.dispose();
      medicine.durationController.dispose();
    }

    setState(() {
      _rollController.clear();
      _nameController.clear();
      _ageController.clear();
      _genderController.clear();
      _complainController.clear();
      _examinationController.clear();
      _adviceController.clear();
      _testsController.clear();
      selectedDate = DateTime.now();
      _initializeMedicineRows(10); // Re-initialize with fresh controllers
    });
  }

  // 1. 🎯 FIX: Removed the Expanded widget from here.
  // It caused nested Expanded issues when used inside another Expanded in the ListView.
  Widget _buildMedicineInputField(
    TextEditingController controller,
    String hint,
  ) {
    // Use IntrinsicHeight to force the Row to resize to the height of the tallest cell
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          // Allow text to wrap and increase cell height
          maxLines: null,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            isDense: true,
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use LayoutBuilder to dynamically determine the height based on available vertical space,
    // or keep a static percentage for simplicity if contentHeight is critical.
    final contentHeight = MediaQuery.of(context).size.height * 0.99;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescription"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _addMedicineRow,
            icon: const Icon(Icons.add, color: Colors.blue),
            tooltip: 'Add Medicine Row',
          ),
          IconButton(
            onPressed: clearForm,
            icon: const Icon(Icons.clear_all, color: Colors.red),
            tooltip: 'Clear Form',
          ),
          ElevatedButton.icon(
            onPressed: savePrescription,
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text(
              'Print & Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade500,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // University Logo
                  Image.asset(
                    'assets/images/nstu_logo.jpg',
                    height: screenWidth * 0.08,
                    width: screenWidth * 0.078,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.local_hospital, size: 40),
                  ),
                  const SizedBox(width: 8),

                  // University Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "মেডিকেল সেন্টার",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "নোয়াখালী বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয়",
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        "Noakhali Science and Technology University",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade400, thickness: 1),
            // Patient Info Section (No changes needed here)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Row 1: Patient Name + Date
                  Row(
                    children: [
                      const Text(
                        'Patient Name:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.only(bottom: 4),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Date:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(
                                text:
                                    "${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}",
                              ),
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                contentPadding: EdgeInsets.only(bottom: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 🔹 Row 2: Roll + Age + Gender
                  Row(
                    children: [
                      const Text(
                        'Roll:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _rollController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.only(bottom: 4),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Age:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.only(bottom: 4),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Gender:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _genderController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.only(bottom: 4),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade400, thickness: 1),
            const SizedBox(height: 8),

            // Medicine Form Fields
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              height: contentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Column: C/C, O/E, Adv, Test
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // C/C, O/E, Adv, Test sections (No changes needed)
                        const Text("C/C:", style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: TextField(
                            controller: _complainController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Write here...",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const Text("O/E:", style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: TextField(
                            controller: _examinationController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Write here...",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const Text("Adv:", style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: TextField(
                            controller: _adviceController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Write here...",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const Text("Inv:", style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: TextField(
                            controller: _testsController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Write here...",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  const VerticalDivider(
                    color: Colors.black,
                    thickness: 1,
                    width: 20,
                  ),

                  // Right Column: Rx (3-Column Layout)
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Rx:", style: TextStyle(fontSize: 16)),

                        Expanded(
                          child: ListView.builder(
                            itemCount: _medicineRows.length,
                            itemBuilder: (context, index) {
                              final medicine = _medicineRows[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Align fields to the top
                                children: [
                                  // Medicine Name - Flex: 5
                                  Expanded(
                                    flex: 5,
                                    child: _buildMedicineInputField(
                                      medicine.nameController,
                                      "Name",
                                    ),
                                  ),
                                  // Dosage - Flex: 2
                                  Expanded(
                                    flex: 2,
                                    child: _buildMedicineInputField(
                                      medicine.dosageController,
                                      "Dosage",
                                    ),
                                  ),
                                  // Duration - Flex: 1
                                  Expanded(
                                    flex: 2,
                                    child: _buildMedicineInputField(
                                      medicine.durationController,
                                      "Duration",
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Button to manually add a row
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _addMedicineRow,
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text("Add Medicine"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Signature Section
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Optional small signature input
                  SizedBox(
                    width: 120,
                    child: TextField(
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: "Signature",
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Signature line
                  Container(width: 130, height: 1, color: Colors.black),
                  const SizedBox(height: 5),

                  // Label
                  const Text(
                    "Doctor's Signature",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
