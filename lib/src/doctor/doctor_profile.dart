import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'test_reports_view.dart';
import 'package:dishari/src/change_request_rostering.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Initial doctor data
  final String initialName = "Dr. Mohammad Rahman";
  final String initialEmail = "rahman@nstu.edu.bd";
  final String initialDoctorID = "DOC2024001";
  final String initialPhone = "+8801********";
  final String initialSpecialization = "Cardiology";
  final String initialLicenseNumber = "BMDC-12345";
  final String initialQualifications = "MBBS, MD (Cardiology), FCPS";
  final String initialShiftTiming = "Morning (9:00 AM - 3:00 PM)";

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _doctorIDController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specializationController;
  late final TextEditingController _licenseController;
  late final TextEditingController _qualificationsController;
  late final TextEditingController _shiftController;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
    _doctorIDController = TextEditingController(text: initialDoctorID);
    _phoneController = TextEditingController(text: initialPhone);
    _specializationController = TextEditingController(text: initialSpecialization);
    _licenseController = TextEditingController(text: initialLicenseNumber);
    _qualificationsController = TextEditingController(text: initialQualifications);
    _shiftController = TextEditingController(text: initialShiftTiming);

    _nameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _qualificationsController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final changed = _nameController.text != initialName ||
        _phoneController.text != initialPhone ||
        _qualificationsController.text != initialQualifications ||
        _profileImage != null;

    if (changed != _isChanged) {
      setState(() {
        _isChanged = changed;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      _checkChanges();
    }
  }

  void _showNotificationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Notifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.upload_file, color: Colors.green),
                    title: Text("New Test Report Uploaded"),
                    subtitle: Text("Patient: Md Sabbir Ahamed uploaded Blood Test report"),
                    trailing: IconButton(
                      icon: Icon(Icons.visibility),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TestReportsViewPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Password changed successfully!")),
              );
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // Navigate to rostering system
  void _navigateToRostering() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeRequestRostering(
          userRole: 'doctor',
          userName: _nameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Doctor Profile"),
        foregroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add, color: Colors.red),
            onPressed: (){
              _showNotificationsList();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25), // Changed to 25 padding for entire page
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Profile Image
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person, size: 60, color: Colors.black54)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "DR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Verified Professional
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Verified Professional",
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Personal Information Header
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Personal Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Full Name
              TextField(
                controller: _nameController,
                readOnly: false,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Email
              TextField(
                controller: _emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                ),
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 15),

              // Doctor ID
              TextField(
                controller: _doctorIDController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Doctor ID",
                  prefixIcon: const Icon(Icons.badge, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                ),
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 15),

              // Phone Number
              TextField(
                controller: _phoneController,
                readOnly: false,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Specialization
              TextField(
                controller: _specializationController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Specialization",
                  prefixIcon: const Icon(Icons.medical_services, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                ),
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 15),

              // License Number
              TextField(
                controller: _licenseController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "License Number",
                  prefixIcon: const Icon(Icons.assignment_ind, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                ),
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 15),

              // Qualifications
              TextField(
                controller: _qualificationsController,
                maxLines: 2,
                readOnly: false,
                decoration: InputDecoration(
                  labelText: "Qualifications",
                  prefixIcon: const Icon(Icons.school, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Schedule Information Header
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Schedule Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Shift Timing
              TextField(
                controller: _shiftController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Current Shift",
                  prefixIcon: const Icon(Icons.schedule, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                ),
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_reset, size: 20),
                      label: const Text("Change Password"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isChanged
                          ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profile updated successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {
                          _isChanged = false;
                        });
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Rostering Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToRostering,
                  icon: const Icon(Icons.schedule, color: Colors.white),
                  label: const Text(
                    "My Schedule",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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