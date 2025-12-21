import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientProfilePage extends StatefulWidget {
  // Make userId optional: the page will try to load the id from SharedPreferences
  // if it is not passed by the caller. This keeps backward compatibility.
  final String? userId;
  const PatientProfilePage({super.key, this.userId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _allergiesController;
  String? _initialName;
  String? _initialPhone;
  String? _initialAllergies;

  // Profile image
  Uint8List? _profileImageBytes;
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();

  // Track state
  bool _isChanged = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _resolvedUserId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _allergiesController = TextEditingController();

    _loadProfileData();

    _nameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _allergiesController.addListener(_checkChanges);
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Resolve user id: prefer provided, otherwise try stored 'user_id'
      _resolvedUserId = widget.userId;
      if (_resolvedUserId == null || _resolvedUserId!.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final storedId = prefs.getString('user_id');
          if (storedId != null && storedId.isNotEmpty) {
            _resolvedUserId = storedId;
          }
        } catch (e) {
          // ignore prefs error; _resolvedUserId stays null
        }
      }

      if (_resolvedUserId == null || _resolvedUserId!.isEmpty) {
        _showDialog('Error', 'No user id available. Please sign in again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final profile = await client.patient.getPatientProfile(_resolvedUserId!);

      if (profile != null) {
        // ✅ Set initial values here (AFTER fetching profile)
        _initialName = profile.name;
        _initialPhone = profile.phone;
        _initialAllergies = profile.allergies;

        setState(() {
          _nameController.text = profile.name;
          _emailController.text = profile.email;
          _phoneController.text = profile.phone;
          _bloodGroupController.text = profile.bloodGroup;
          _allergiesController.text = profile.allergies;
          _profileImageBase64 = profile.profilePictureUrl;
          _isLoading = false;
        });
      } else {
        _showDialog('Error', 'Profile not found for user: ${widget.userId}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showDialog('Error', 'Failed to load profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkChanges() {
    final changed =
        _nameController.text != _initialName ||
        _phoneController.text != _initialPhone ||
        _allergiesController.text != _initialAllergies ||
        (_profileImageBytes != null); // only if new image selected

    if (changed != _isChanged) {
      setState(() => _isChanged = changed);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        if (bytes.length > 1024 * 1024) {
          _showDialog(
            'Image Too Large',
            'Please select an image smaller than 1MB',
          );
          return;
        }

        setState(() {
          _profileImageBytes = bytes;
        });
        _checkChanges();
      }
    } catch (e) {
      _showDialog('Error', 'Failed to pick image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_isChanged) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? base64Image;

      if (_profileImageBytes != null) {
        base64Image =
            'data:image/jpeg;base64,${base64Encode(_profileImageBytes!)}';
      }

      // Ensure we have a resolved user id to send to the API
      String? uid = _resolvedUserId;
      if (uid == null || uid.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          uid = prefs.getString('user_id');
        } catch (e) {
          // ignore
        }
      }

      if (uid == null || uid.isEmpty) {
        _showDialog('Error', 'No user id available. Cannot save profile.');
        return;
      }

      final result = await client.patient.updatePatientProfile(
        uid,
        _nameController.text,
        _phoneController.text,
        _allergiesController.text,
        base64Image,
      );

      if (result.contains('successfully')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.green),
        );

        _profileImageBytes = null;
        await _loadProfileData();
        setState(() {
          _isChanged = false;
        });
      } else {
        _showDialog('Error', result);
      }
    } catch (e) {
      _showDialog('Error', 'Failed to save profile: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    Uint8List? bytes;

    if (_profileImageBytes != null) {
      bytes = _profileImageBytes;
    } else if (_profileImageBase64 != null &&
        _profileImageBase64!.startsWith('data:image/')) {
      try {
        final base64String = _profileImageBase64!.split(',').last;
        bytes = base64.decode(base64String);
      } catch (_) {}
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes == null
          ? const Icon(Icons.person, size: 60, color: Colors.black54)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double responsiveWidth(double w) => size.width * w / 375;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Profile"),
        foregroundColor: Colors.blue,
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsiveWidth(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildProfileImage(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_profileImageBase64 != null &&
                              _profileImageBase64!.isNotEmpty)
                          ? ''
                          : 'No profile image set',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            (_profileImageBase64 != null &&
                                _profileImageBase64!.isNotEmpty)
                            ? Colors.green
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField(
                      _emailController,
                      'Email',
                      Icons.mail,
                      readOnly: true,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      _phoneController,
                      'Phone Number',
                      Icons.phone,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      _bloodGroupController,
                      'Blood Group',
                      Icons.bloodtype,
                      readOnly: true,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      _allergiesController,
                      'Allergies (if any)',
                      Icons.health_and_safety,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: size.width * 0.6,
                      height: 50,
                      child: _isSaving
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _isChanged ? _saveProfile : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                disabledBackgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }
}
