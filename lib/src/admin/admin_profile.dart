import 'dart:convert';

import 'package:backend_client/backend_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final Color primaryColor = const Color(0xFF00796B); // Deep Teal

  // State variables for Notification Settings (SRS Requirement)
  bool _lowStockAlerts = true;
  bool _rosteringRequestAlerts = true;

  // Theme mode
  bool _isDarkMode = true;

  // NEW: Controllers and obscure toggles for change-password dialog
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Profile data
  String _resolvedUserId = '';
  String _displayName = '';
  String _displayEmail = '';
  String _displayPhone = '';
  String _displayProfilePicture = '';
  String _displaySpecialization = '';
  String _displayQualification = '';
  String _displayJoiningDate = '';

  // Edit profile controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _specializationCtrl = TextEditingController();
  final TextEditingController _qualificationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadProfile();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('user_id');

      if (uid == null || uid.isEmpty) {
        // Session expired - redirect to login
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      _resolvedUserId = uid;
      final jsonData = await client.adminEndpoints.getAdminProfile(uid);

      if (jsonData == null || jsonData.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile not found. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Decode JSON response
      final profile = jsonDecode(jsonData) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _displayName = (profile['name'] ?? '').toString();
        _displayEmail = (profile['email'] ?? '').toString();
        _displayPhone = (profile['phone'] ?? '').toString();
        _displayProfilePicture = (profile['profilePictureUrl'] ?? '')
            .toString();
        _displaySpecialization = (profile['specialization'] ?? '').toString();
        _displayQualification = (profile['qualification'] ?? '').toString();
        _displayJoiningDate = (profile['joiningDate'] ?? '').toString();
      });
    } catch (e) {
      if (!mounted) return;

      // Clean up error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Call changePassword endpoint
  Future<String> _callChangePassword(String current, String next) async {
    try {
      if (_resolvedUserId.isEmpty) {
        return 'Session expired. Please log in again.';
      }

      final res = await client.adminEndpoints.changePassword(
        _resolvedUserId,
        current,
        next,
      );
      return res;
    } catch (e) {
      // Clean up error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }
      return errorMsg;
    }
  }

  // --- Utility Functions for Actions ---

  Future<void> _uploadProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Check size (limit to 500KB)
      if (bytes.length > 500 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image too large. Please select an image under 500KB',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert to base64
      final base64Image = base64Encode(bytes);

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Upload to backend
      final result = await client.adminEndpoints.updateAdminProfile(
        _resolvedUserId,
        _displayName,
        _displayPhone,
        base64Image,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result == 'OK') {
        setState(() {
          _displayProfilePicture = base64Image;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Close loading dialog if open
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    _nameCtrl.text = _displayName;
    _phoneCtrl.text = _displayPhone;
    _specializationCtrl.text = _displaySpecialization;
    _qualificationCtrl.text = _displayQualification;

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 500,
                constraints: const BoxConstraints(maxHeight: 650),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Update your personal information',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personal Information Section
                            const Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 20,
                                  color: Color(0xFF7C3AED),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: '+880 1234 567 890',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Professional Information Section
                            const Row(
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 20,
                                  color: Color(0xFF7C3AED),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Professional Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _specializationCtrl,
                              decoration: InputDecoration(
                                labelText: 'Specialization',
                                hintText: 'e.g., System Administration',
                                prefixIcon: const Icon(Icons.work),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _qualificationCtrl,
                              decoration: InputDecoration(
                                labelText: 'Qualification',
                                hintText: 'e.g., MSc in Computer Science',
                                prefixIcon: const Icon(Icons.school),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Footer Actions
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setDialogState(() => isSaving = true);
                                      try {
                                        final result = await client
                                            .adminEndpoints
                                            .updateStaffProfile(
                                              _resolvedUserId,
                                              specialization:
                                                  _specializationCtrl.text
                                                      .trim(),
                                              qualification: _qualificationCtrl
                                                  .text
                                                  .trim(),
                                              joiningDate: null,
                                            );

                                        if (result == 'OK') {
                                          await client.adminEndpoints
                                              .updateAdminProfile(
                                                _resolvedUserId,
                                                _nameCtrl.text.trim(),
                                                _phoneCtrl.text.trim(),
                                                null,
                                              );

                                          setState(() {
                                            _displayName = _nameCtrl.text
                                                .trim();
                                            _displayPhone = _phoneCtrl.text
                                                .trim();
                                            _displaySpecialization =
                                                _specializationCtrl.text.trim();
                                            _displayQualification =
                                                _qualificationCtrl.text.trim();
                                          });

                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Profile updated successfully',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          setDialogState(
                                            () => isSaving = false,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Update failed: $result',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() => isSaving = false);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    // Use StatefulBuilder so the dialog can react to password input changes
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Helper checks for criteria
            final newPass = _newPasswordCtrl.text;
            bool hasMinLen() => newPass.length >= 6;
            bool hasUpperLower() =>
                newPass.contains(RegExp(r'[A-Z]')) &&
                newPass.contains(RegExp(r'[a-z]'));
            bool hasNumber() => newPass.contains(RegExp(r'[0-9]'));
            bool hasSpecial() => newPass.contains(RegExp(r'[!@#\$%\^&*]'));

            final Color neutralColor = Colors.black54;

            Widget crit(String text, bool ok) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.circle_outlined,
                    color: ok ? Colors.green : neutralColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(color: ok ? Colors.green : neutralColor),
                  ),
                ],
              ),
            );

            // evaluate whether update should be enabled: all criteria met and confirm matches and current filled
            final cur = _currentPasswordCtrl.text.trim();
            final np = _newPasswordCtrl.text;
            final cp = _confirmPasswordCtrl.text;
            final bool allCriteria =
                hasMinLen() && hasUpperLower() && hasNumber() && hasSpecial();
            final bool enableUpdate =
                cur.isNotEmpty && allCriteria && (np == cp);

            bool _isChanging = false;

            return AlertDialog(
              title: const Text("Change Password"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current Password (underline style)
                    TextField(
                      controller: _currentPasswordCtrl,
                      obscureText: _obscureCurrent,
                      enabled: !_isChanging,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setStateDialog(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // New Password (underline style)
                    TextField(
                      controller: _newPasswordCtrl,
                      obscureText: _obscureNew,
                      enabled: !_isChanging,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setStateDialog(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password (underline style)
                    TextField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      enabled: !_isChanging,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setStateDialog(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        crit('At least 6 characters', hasMinLen()),
                        crit(
                          'Contains uppercase and lowercase',
                          hasUpperLower(),
                        ),
                        crit('Contains at least one number', hasNumber()),
                        crit(
                          'Contains special character (!@#\$%)',
                          hasSpecial(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                StatefulBuilder(
                  builder: (context2, setStateInner) {
                    // local changing flag to show progress on the button
                    bool localChanging = false;
                    return ElevatedButton(
                      onPressed: (enableUpdate && !localChanging)
                          ? () async {
                              setStateDialog(() => localChanging = true);
                              setStateDialog(() => _isChanging = true);
                              try {
                                final res = await _callChangePassword(
                                  _currentPasswordCtrl.text.trim(),
                                  _newPasswordCtrl.text,
                                );
                                if (res == 'OK') {
                                  Navigator.pop(context);
                                  _currentPasswordCtrl.clear();
                                  _newPasswordCtrl.clear();
                                  _confirmPasswordCtrl.clear();
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password changed'),
                                      ),
                                    );
                                } else {
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Password change failed: $res',
                                        ),
                                      ),
                                    );
                                }
                              } catch (e) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password change error: $e',
                                      ),
                                    ),
                                  );
                              } finally {
                                setStateDialog(() => localChanging = false);
                                setStateDialog(() => _isChanging = false);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (enableUpdate && !localChanging)
                            ? primaryColor
                            : Colors.grey,
                      ),
                      child: localChanging
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Update",
                              style: TextStyle(color: Colors.white),
                            ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _initiateDatabaseAction(String action) {
    // Dummy action for Database/Logs
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$action initiated... (Dummy Action)")),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder to manage dialog's internal state (toggles)
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Notification Settings"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text("Inventory Low Stock Alerts"),
                    subtitle: Text(_lowStockAlerts ? "ON" : "OFF"),
                    value: _lowStockAlerts,
                    onChanged: (bool value) {
                      setStateDialog(() {
                        _lowStockAlerts = value; // Update dialog state
                      });
                      setState(() {
                        _lowStockAlerts = value; // Update main widget state
                      });
                    },
                    // use activeThumbColor to avoid deprecated activeColor
                    activeThumbColor: primaryColor,
                  ),
                  SwitchListTile(
                    title: const Text("Staff Rostering Requests"),
                    subtitle: Text(_rosteringRequestAlerts ? "ON" : "OFF"),
                    value: _rosteringRequestAlerts,
                    onChanged: (bool value) {
                      setStateDialog(() {
                        _rosteringRequestAlerts = value; // Update dialog state
                      });
                      setState(() {
                        _rosteringRequestAlerts =
                            value; // Update main widget state
                      });
                    },
                    activeThumbColor: primaryColor,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to convert stored profile picture string (base64 or URL) to ImageProvider
  ImageProvider<Object>? _imageProviderFromString(String? data) {
    if (data == null || data.isEmpty) return null;
    // try base64
    try {
      final bytes = base64Decode(data);
      return MemoryImage(bytes);
    } catch (_) {}
    // fallback to network image
    try {
      return NetworkImage(data);
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF1A1F2E) : Colors.grey.shade50;
    final cardColor = _isDarkMode ? const Color(0xFF252B3D) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = _isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF7C3AED),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'System Configuration',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: subtextColor),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Profile Card
                  Expanded(
                    flex: 1,
                    child: _buildProfileCard(
                      cardColor,
                      textColor,
                      subtextColor,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right side - Settings Sections
                  Expanded(
                    flex: 2,
                    child: _buildSettingsSections(
                      cardColor,
                      textColor,
                      subtextColor,
                      _isDarkMode,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(cardColor, textColor, subtextColor),
                const SizedBox(height: 24),
                _buildSettingsSections(
                  cardColor,
                  textColor,
                  subtextColor,
                  _isDarkMode,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileCard(
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                  backgroundImage: _imageProviderFromString(
                    _displayProfilePicture,
                  ),
                  child: _displayProfilePicture.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF7C3AED),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _uploadProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _displayName.isNotEmpty ? _displayName : "Admin User",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "System Administrator",
              style: TextStyle(fontSize: 14, color: const Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 32),
            _buildInfoRow(
              Icons.email,
              _displayEmail.isNotEmpty ? _displayEmail : "admin@medadmin.com",
              textColor,
              subtextColor,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.phone,
              _displayPhone.isNotEmpty ? _displayPhone : "+880 1234 567 890",
              textColor,
              subtextColor,
            ),
            if (_displaySpecialization.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.work,
                _displaySpecialization,
                textColor,
                subtextColor,
              ),
            ],
            if (_displayQualification.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.school,
                _displayQualification,
                textColor,
                subtextColor,
              ),
            ],
            if (_displayJoiningDate.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.calendar_today,
                'Joined: ${_displayJoiningDate.split('T')[0]}',
                textColor,
                subtextColor,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: subtextColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: subtextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSections(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Settings Section
        _buildSectionCard(
          cardColor,
          textColor,
          subtextColor,
          isDarkMode,
          'Account Settings',
          Icons.person,
          [
            _buildSettingTile(
              Icons.notifications,
              'Notifications',
              'Push & email alerts',
              cardColor,
              textColor,
              subtextColor,
              onTap: _showNotificationSettings,
              trailing: Switch(
                value: _lowStockAlerts || _rosteringRequestAlerts,
                onChanged: (value) => _showNotificationSettings(),
                activeColor: const Color(0xFF7C3AED),
              ),
            ),
            _buildSettingTile(
              Icons.lock,
              'Change Password',
              'Update your credentials',
              cardColor,
              textColor,
              subtextColor,
              onTap: _showChangePasswordDialog,
            ),
            _buildSettingTile(
              Icons.palette,
              'Appearance',
              _isDarkMode ? 'Dark mode' : 'Light mode',
              cardColor,
              textColor,
              subtextColor,
              onTap: () => _saveThemePreference(!_isDarkMode),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _saveThemePreference,
                activeColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // System Controls Section
        _buildSectionCard(
          cardColor,
          textColor,
          subtextColor,
          _isDarkMode,
          'System Controls',
          Icons.settings,
          [
            _buildSettingTile(
              Icons.storage,
              'Database Backup',
              'Last backup: 2 hours ago',
              cardColor,
              textColor,
              subtextColor,
              onTap: () => _initiateDatabaseAction("Viewing Database Status"),
              trailing: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Sign Out Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logged out successfully!")),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900.withOpacity(0.2),
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDarkMode,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF7C3AED), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle,
    Color cardColor,
    Color textColor,
    Color subtextColor, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: subtextColor),
          ],
        ),
      ),
    );
  }
}
