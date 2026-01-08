import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class PatientReportUpload extends StatefulWidget {
  const PatientReportUpload({super.key});

  @override
  State<PatientReportUpload> createState() => _PatientReportUploadState();
}

class _PatientReportUploadState extends State<PatientReportUpload> {
  final _formKey = GlobalKey<FormState>();
  final Color kPrimaryColor = const Color(0xFF00796B); // Deep Teal

  // Controllers
  final TextEditingController _dateController = TextEditingController();
  String? _selectedType;
  PlatformFile? _selectedFile;

  // SRS Compliance: Allowed report types
  final List<String> _reportTypes = [
    "Blood Test",
    "Urine Test",
    "Liver Function Test",
    "Kidney Function Test",
    "Sugar Test",
    "Other",
  ];

  // Pick file
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "jpg", "jpeg", "png"],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        // On web, `path` can be null, so we store the PlatformFile directly
        _selectedFile = result.files.single;
      });
    }
  }

  // Pick date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Custom Input Decoration for better look
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Upload External Report",
          style: TextStyle(color: Colors.blueAccent),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Upload test results from external labs.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // 1. Report Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _inputDecoration("Report Type", Icons.science),
                hint: const Text("Select Report Type"),
                items: _reportTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a report type' : null,
              ),
              const SizedBox(height: 20),

              // 2. Date of Test
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration:
                    _inputDecoration(
                      "Date of Test",
                      Icons.calendar_month,
                    ).copyWith(
                      suffixIcon: Icon(
                        Icons.edit,
                        color: kPrimaryColor.withOpacity(0.7),
                      ),
                    ),
                validator: (value) =>
                    value!.isEmpty ? 'Please select the test date' : null,
              ),
              const SizedBox(height: 30),

              // 3. File Picker Area (Visually improved)
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: _selectedFile == null
                        ? kPrimaryColor.withOpacity(0.05)
                        : kPrimaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _selectedFile == null
                          ? Colors.blueGrey.shade200
                          : kPrimaryColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile == null
                            ? Icons.file_upload
                            : Icons.check_circle,
                        size: 50,
                        color: _selectedFile == null
                            ? Colors.blueGrey
                            : kPrimaryColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFile == null
                            ? "Tap to Select File (PDF/Image)"
                            : "File Selected:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedFile == null
                              ? Colors.blueGrey
                              : kPrimaryColor,
                        ),
                      ),
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            _selectedFile!.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 4. Upload Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _selectedFile != null) {
                      // SRS Compliance: Upload logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Report uploaded successfully!"),
                        ),
                      );
                      // TODO: Send data + file to DB
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select file and complete all fields",
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text(
                    "UPLOAD REPORT",
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
    );
  }
}
