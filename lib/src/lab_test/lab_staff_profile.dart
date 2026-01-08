import 'dart:convert';
import 'dart:io';

import 'package:backend_client/backend_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../change_request_rostering.dart';

class LabTesterProfile extends StatefulWidget {
  const LabTesterProfile({super.key});

  @override
  State<LabTesterProfile> createState() => _LabTesterProfileState();
}

class _LabTesterProfileState extends State<LabTesterProfile> {
  // =====================
  // THEME
  // =====================
  bool _isDarkMode = true;

  // =====================
  // PROFILE DATA
  // =====================
  String _userId = '';
  String name = '';
  String email = '';
  String phone = '';
  String department = '';
  String joinedDate = '';
  String qualification = '';
  String _profilePictureBase64 = '';

  File? _profileImage;
  bool _isLoading = false;
  String? _errorMessage;

  // =====================
  // STAFF EDIT CONTROLS
  // =====================
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedJoiningDate;

  // =====================
  // PASSWORD FORM
  // =====================
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isChangingPassword = false;
  bool _showEditPanel = false;
  bool _isSavingInline = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _editSectionKey = GlobalKey();

  // =====================
  // INIT
  // =====================
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

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _departmentController.dispose();
    _qualificationController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =====================
  // LOAD PROFILE
  // =====================
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('user_id');

      if (uid == null || uid.isEmpty) {
        // User not logged in - redirect to login page
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'You are not logged in. Please log in to view your profile.';
          _isLoading = false;
        });

        // Show message and redirect after a delay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        // Redirect to login after showing the message
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      _userId = uid;
      final jsonData = await client.adminEndpoints.getAdminProfile(uid);

      if (jsonData == null || jsonData.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Profile not found. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      // Decode JSON response
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        name = data['name']?.toString() ?? '';
        email = data['email']?.toString() ?? '';
        phone = data['phone']?.toString() ?? '';
        department = data['specialization']?.toString() ?? '';
        final joiningDateRaw = data['joining_date'];
        if (joiningDateRaw is DateTime) {
          joinedDate = joiningDateRaw.toIso8601String().split('T').first;
          _selectedJoiningDate = joiningDateRaw;
        } else if (joiningDateRaw != null) {
          joinedDate = joiningDateRaw.toString();
          try {
            _selectedJoiningDate = DateTime.parse(joinedDate);
          } catch (_) {}
        }
        qualification = data['qualification']?.toString() ?? '';
        _profilePictureBase64 = data['profile_picture_url']?.toString() ?? '';
        _isLoading = false;
        _nameController.text = name;
        _departmentController.text = department;
        _qualificationController.text = qualification;
      });
    } catch (e) {
      if (!mounted) return;

      // Clean up error message - remove "Exception:" prefix
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // =====================
  // PICK IMAGE & UPLOAD
  // =====================
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file == null) return;

      final imageFile = File(file.path);
      final bytes = await imageFile.readAsBytes();

      if (bytes.length > 50 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large (max 50KB)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final base64Image = base64Encode(bytes);
      final result = await client.adminEndpoints.updateAdminProfile(
        _userId,
        name,
        phone,
        base64Image,
      );

      if (!mounted) return;
      if (result == 'OK') {
        setState(() {
          _profileImage = imageFile;
          _profilePictureBase64 = base64Image;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Clean up error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  // =====================
  // CHANGE PASSWORD
  // =====================
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      if (_userId.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.orange,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      final result = await client.adminEndpoints.changePassword(
        _userId,
        _oldPassword.text,
        _newPassword.text,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result == 'OK') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _oldPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      // Clean up error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  // =====================
  // SAVE STAFF DETAILS (specialization/qualification/joining_date)
  // =====================
  Future<bool> _saveStaffDetails() async {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: Colors.orange,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      return false;
    }

    try {
      final nm = _nameController.text.trim();
      final spec = _departmentController.text.trim();
      final qual = _qualificationController.text.trim();

      // Staff should update their own profile using the patient endpoint
      final res = await client.patient.updatePatientProfile(
        _userId,
        nm.isEmpty ? name : nm,
        phone,
        '', // allergies not applicable for staff
        null, // profilePictureData
      );

      if (res.contains('successfully')) {
        if (!mounted) return false;
        setState(() {
          name = nm.isEmpty ? name : nm;
          department = spec.isEmpty ? department : spec;
          qualification = qual.isEmpty ? qualification : qual;
          // keep existing joinedDate string if _selectedJoiningDate is null
          if (_selectedJoiningDate != null) {
            joinedDate = _selectedJoiningDate!
                .toIso8601String()
                .split('T')
                .first;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff details updated'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      }
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }

    return false;
  }

  // =====================
  // LOGOUT
  // =====================
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      if (!mounted) return;

      // Clean up error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _loadProfile,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color(0xFF1A1F2E)
          : const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF252B3D) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode ? Colors.black45 : Colors.black12,
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 28, bottom: 24),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF16C0AB), Color(0xFF0BA18C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 46,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.22,
                                      ),
                                      backgroundImage: (() {
                                        ImageProvider<Object>? img;
                                        if (_profileImage != null) {
                                          img = FileImage(_profileImage!);
                                        } else if (_profilePictureBase64
                                            .isNotEmpty) {
                                          try {
                                            final comma = _profilePictureBase64
                                                .indexOf(',');
                                            final pure = comma > 0
                                                ? _profilePictureBase64
                                                      .substring(comma + 1)
                                                : _profilePictureBase64;
                                            final bytes = base64Decode(pure);
                                            img = MemoryImage(bytes);
                                          } catch (_) {}
                                        }
                                        return img;
                                      })(),
                                      child:
                                          (_profileImage == null &&
                                              _profilePictureBase64.isEmpty)
                                          ? const Icon(
                                              Icons.person,
                                              size: 46,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: _pickProfileImage,
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Color(0xFF0BA18C),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      name.isEmpty ? '—' : name,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                department.isEmpty
                                    ? 'Laboratory Technologist'
                                    : department,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: _toggleEditPanel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _detailRow(
                            Icons.badge_outlined,
                            'Department',
                            department.isEmpty
                                ? 'Laboratory Technologist'
                                : department,
                          ),
                          _detailRow(
                            Icons.school_outlined,
                            'Qualification',
                            qualification.isEmpty ? '—' : qualification,
                          ),
                          _detailRow(
                            Icons.calendar_today_outlined,
                            'Joined',
                            _displayJoinedDate(),
                          ),
                          _detailRow(
                            Icons.email_outlined,
                            'Email',
                            email.isEmpty ? '—' : email,
                          ),
                          _detailRow(
                            Icons.phone_forwarded_outlined,
                            'Phone',
                            phone.isEmpty ? '—' : phone,
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _showEditPanel
                                ? _InlineEditSection(
                                    key: _editSectionKey,
                                    nameController: _nameController,
                                    departmentController: _departmentController,
                                    qualificationController:
                                        _qualificationController,
                                    displayJoinedDate: _displayJoinedDate(),
                                    onPickDate: _pickDate,
                                    onSave: _handleSaveInline,
                                    isSaving: _isSavingInline,
                                    onClose: () =>
                                        setState(() => _showEditPanel = false),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.schedule,
                                  label: 'My Schedule',
                                  onPressed: name.isEmpty
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ChangeRequestRostering(
                                                    userRole: 'lab_staff',
                                                    userName: name,
                                                  ),
                                            ),
                                          );
                                        },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  icon: _isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  label: _isDarkMode ? 'Light' : 'Dark',
                                  onPressed: () =>
                                      _saveThemePreference(!_isDarkMode),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.vpn_key_outlined,
                                  label: 'Change Password',
                                  onPressed: _userId.isEmpty
                                      ? null
                                      : () => _showPasswordDialog(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.logout),
                              label: const Text(
                                'Log Out',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              onPressed: _logout,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================
  // INLINE EDIT CONTROLS
  // =====================
  void _toggleEditPanel() {
    setState(() => _showEditPanel = !_showEditPanel);

    if (_showEditPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _editSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedJoiningDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedJoiningDate = picked);
    }
  }

  Future<void> _handleSaveInline() async {
    setState(() => _isSavingInline = true);
    final success = await _saveStaffDetails();
    if (mounted) {
      setState(() {
        _isSavingInline = false;
        if (success) _showEditPanel = false;
      });
    }
  }

  // =====================
  // PASSWORD DIALOG
  // =====================
  void _showPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isChangingPassword,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient Header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED),
                        const Color(0xFF6D28D9),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update your account password securely',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current Password Field
                        TextFormField(
                          controller: _oldPassword,
                          obscureText: true,
                          enabled: !_isChangingPassword,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF7C3AED),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 2,
                              ),
                            ),
                            hintText: 'Enter your current password',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // New Password Field
                        TextFormField(
                          controller: _newPassword,
                          obscureText: true,
                          enabled: !_isChangingPassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 6) return 'Min 6 characters';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(
                              Icons.lock_reset,
                              color: Color(0xFF7C3AED),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 2,
                              ),
                            ),
                            hintText: 'Enter a strong password',
                            helperText: 'At least 6 characters',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: true,
                          enabled: !_isChangingPassword,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(
                              Icons.verified_user,
                              color: Color(0xFF7C3AED),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF7C3AED),
                                width: 2,
                              ),
                            ),
                            hintText: 'Confirm your new password',
                          ),
                        ),
                        if (_isChangingPassword) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isChangingPassword
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isChangingPassword ? null : _changePassword,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Update Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayJoinedDate() {
    DateTime? date;
    if (_selectedJoiningDate != null) {
      date = _selectedJoiningDate;
    } else if (joinedDate.isNotEmpty) {
      try {
        date = DateTime.parse(joinedDate);
      } catch (_) {}
    }

    if (date == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString();
    final month = months[date.month - 1];
    final year = date.year.toString();
    return '$month $day, $year';
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0BA18C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xFF0BA18C)),
        foregroundColor: const Color(0xFF0BA18C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }
}

class _InlineEditSection extends StatelessWidget {
  const _InlineEditSection({
    super.key,
    required this.nameController,
    required this.departmentController,
    required this.qualificationController,
    required this.displayJoinedDate,
    required this.onPickDate,
    required this.onSave,
    required this.onClose,
    required this.isSaving,
  });

  final TextEditingController nameController;
  final TextEditingController departmentController;
  final TextEditingController qualificationController;
  final String displayJoinedDate;
  final Future<void> Function() onSave;
  final VoidCallback onPickDate;
  final VoidCallback onClose;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB2E6DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF0BA18C)),
              const SizedBox(width: 8),
              const Text(
                'Edit Staff Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: isSaving ? null : onClose,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            enabled: !isSaving,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF7C3AED),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 2,
                ),
              ),
              hintText: 'Enter your full name',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: departmentController,
            enabled: !isSaving,
            decoration: InputDecoration(
              labelText: 'Department / Specialization',
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: Color(0xFF7C3AED),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: qualificationController,
            enabled: !isSaving,
            decoration: InputDecoration(
              labelText: 'Qualification',
              prefixIcon: const Icon(
                Icons.school_outlined,
                color: Color(0xFF7C3AED),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Joining Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(displayJoinedDate),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Pick'),
                onPressed: isSaving ? null : onPickDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0BA18C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Saving...' : 'Save'),
              onPressed: isSaving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}
