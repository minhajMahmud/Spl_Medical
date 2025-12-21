import 'package:flutter/material.dart';
import 'dart:async'; // Timer ব্যবহারের জন্য
import 'package:dishari/src/universal_login.dart';
import 'package:flutter/services.dart';

class PatientSignupPage extends StatefulWidget {
  const PatientSignupPage({super.key});

  @override
  State<PatientSignupPage> createState() => _PatientSignupPageState();
}

class _PatientSignupPageState extends State<PatientSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final Color kPrimaryColor = const Color(0xFF00796B); // Deep Teal
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  // Password criteria state
  bool _pwHasMinLength = false;
  bool _pwHasUpperAndLower = false;
  bool _pwHasNumber = false;
  bool _pwHasSpecial = false;

  // --- OTP TIMER STATE ---
  int _countdownSeconds = 120; // 2 minutes
  Timer? _timer;
  bool _canResend = false;
  // -----------------------

  // --- Controllers ---
  TextEditingController? _nameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  TextEditingController? _passwordController;
  TextEditingController? _confirmPasswordController;
  TextEditingController? _bloodGroupController;
  TextEditingController? _allergiesController;
  TextEditingController? _otpController;

  String _patientType = 'STUDENT';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _allergiesController = TextEditingController();
    _otpController = TextEditingController();
    // live update of password criteria
    _passwordController!.addListener(_passwordCriteria);
  }

  void _passwordCriteria() {
    final value = _passwordController!.text;
    final hasMin = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasNum = RegExp(r'\d').hasMatch(value);
    final hasSpec = RegExp(r'[!@#\$%]').hasMatch(value);

    final upperAndLower = hasUpper && hasLower;

    if (hasMin != _pwHasMinLength ||
        upperAndLower != _pwHasUpperAndLower ||
        hasNum != _pwHasNumber ||
        hasSpec != _pwHasSpecial) {
      setState(() {
        _pwHasMinLength = hasMin;
        _pwHasUpperAndLower = upperAndLower;
        _pwHasNumber = hasNum;
        _pwHasSpecial = hasSpec;
      });
    }
  }

  // --- VALIDATORS ---
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 4) return 'Name must be at least 4 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a valid email';
    final email = value.trim();
    // Simple email format check
    final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}");
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';

    // Enforce allowed domains (keep existing institution domains)
    if (!email.endsWith('@student.nstu.edu.bd') &&
        !email.endsWith('@staff.nstu.edu.bd') &&
        !email.endsWith('@gmail.com')) {
      return 'Use a valid institution email domain.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter phone number';
    final phone = value.trim();
    // User should enter only 11 digits; UI shows +88 prefix.
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final phoneRegex = RegExp(r'^\d{11}$');
    if (!phoneRegex.hasMatch(phoneDigits)) {
      return 'Enter 11 digits (e.g. 01XXXXXXXXX). +88 shown as prefix';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return 'Include at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value))
      return 'Include at least one lowercase letter';
    if (!RegExp(r'\d').hasMatch(value)) return 'Include at least one number';
    // Require at least one of the following special characters: ! @ # $ %
    if (!RegExp(r'[!@#\$%]').hasMatch(value))
      return 'Include at least one special character from !@#\$%';
    return null;
  }

  // Blood groups list
  final List<String> _bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];
  String? _validateBloodGroup(String? value) {
    if (value == null || value.isEmpty) return 'Please select your blood group';
    return null;
  }

  // --- TIMER FUNCTIONS ---
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer({required Function(int) onUpdate}) {
    _countdownSeconds = 120; // Reset to 2 minutes
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownSeconds < 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _countdownSeconds--;
        });
        onUpdate(_countdownSeconds);
      }
    });
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    _passwordController?.dispose();
    _confirmPasswordController?.dispose();
    _bloodGroupController?.dispose();
    _allergiesController?.dispose();
    _otpController?.dispose();
    _timer?.cancel(); // 🔑 TIMER MUST BE CANCELLED
    super.dispose();
  }

  // Custom Input Decoration for better look
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimaryColor.withAlpha(179)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor.withAlpha(77)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor.withAlpha(26)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }

  // --- OTP DIALOG (Uses StatefulBuilder for Countdown) ---
  void _showOtpDialog() {
    bool dialogTimerStarted = false; // ensure timer starts only once per dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // StatefulBuilder ব্যবহার করা হয়েছে যাতে কাউন্টডাউন চলাকালীন ডায়ালগ আপডেট হতে পারে
        return AlertDialog(
          title: const Text('Verify Email'),
          content: StatefulBuilder(
            builder: (BuildContext dialogContext, StateSetter setStateDialog) {
              // Start timer only once for this dialog instance
              if (!dialogTimerStarted) {
                dialogTimerStarted = true;
                _startTimer(
                  onUpdate: (seconds) {
                    // update only the dialog UI
                    try {
                      setStateDialog(() {});
                    } catch (_) {}
                  },
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A 6-digit OTP has been sent to ${_emailController!.text}.',
                  ),
                  const SizedBox(height: 15),

                  // 🔑 COUNTDOWN DISPLAY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time remaining:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        _formatTime(_countdownSeconds),
                        style: TextStyle(
                          color: _canResend ? Colors.red : kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Enter OTP', Icons.vpn_key),
                    maxLength: 6,
                    validator: (value) =>
                        value!.length != 6 ? 'OTP must be 6 digits' : null,
                  ),

                  // Resend Button
                  TextButton(
                    onPressed: _canResend ? _resendOtp : null,
                    child: Text(
                      _canResend
                          ? 'RESEND OTP'
                          : 'Resend available in ${_formatTime(_countdownSeconds)}',
                      style: TextStyle(
                        color: _canResend ? kPrimaryColor : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cancel timer and reset dialog-related states so next open is clean
                _timer?.cancel(); // Cancel timer on manual close
                if (_isLoading) {
                  setState(() {
                    _isLoading = false;
                  });
                }
                setState(() {
                  _canResend = false;
                  _countdownSeconds = 120; // reset for next time
                });
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: kPrimaryColor)),
            ),
            ElevatedButton(
              onPressed: _verifyOtpAndCreateAccount,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: const Text(
                'VERIFY',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- VERIFY OTP AND CREATE ACCOUNT (Serverpod Call) ---
  Future<void> _verifyOtpAndCreateAccount() async {
    if (_otpController!.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP.')),
      );
      return;
    }

    Navigator.of(context).pop();
    _timer?.cancel(); // Cancel timer once verified/submitted
    setState(() {
      _isLoading = true;
    });

    try {
      //  final result = await client.auth.verifyOtp(
      //   _emailController!.text,
      //   _otpController!.text,
      //   _otpToken ?? '', // pass JWT token returned from register/resend
      //   _passwordController!.text,
      //   _nameController!.text,
      //   _patientType.toUpperCase(), // role
      //   phoneToSend, // normalized phone with +88
      //   _bloodGroupController!.text, // NEW - blood group
      //   _allergiesController!.text, // NEW - allergies
      // );

      if (!mounted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // if (result == 'Account created successfully') {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text(
      //           'Account created successfully! Redirecting to login.',
      //         ),
      //       ),
      //     );
      //     Navigator.pushReplacement(
      //       context,
      // //       MaterialPageRoute(builder: (context) => const HomePage()),
      //     );
      //   }
      // } else {
      //   if (mounted) {
      //     // ScaffoldMessenger.of(context).showSnackBar(
      //     //   SnackBar(content: Text('Verification Failed: $result')),
      //     // );
      //   }
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred during verification. Error: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _otpController!.clear();
      });
    }
  }

  // --- RESEND OTP LOGIC ---
  void _resendOtp() {
    _submitForm(isResend: true);
    // Timer is restarted within _submitForm on success
  }

  // --- UPDATED: SUBMIT FORM (Bypass backend, send sample OTP) ---
  void _submitForm({bool isResend = false}) async {
    // Check validation only on initial submission, not resend
    if (!isResend && (!_formKey.currentState!.validate() || _isLoading)) return;

    if (!isResend &&
        _passwordController!.text != _confirmPasswordController!.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    // Close any previous dialog if this is a resend
    if (isResend && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isLoading = true;
      _canResend = false;
    });

    // Clear the current timer to prevent conflicts
    _timer?.cancel();

    try {
      // Bypass backend: simulate a JWT token and show OTP dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP sent successfully to ${_emailController!.text}. Please check your inbox.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        _showOtpDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Check server connection: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // ... Header ...
              Text(
                'Create Patient Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Register with your institution details.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name', Icons.person),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 15),

                    // Email (with specific domain validation)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        'Email Address (e.g., sabbir@student.nstu.edu.bd)',
                        Icons.email,
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 15),

                    // Phone Number: show +88 prefix; user types 11 digits only
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 11,
                      decoration: _inputDecoration(
                        'Phone Number',
                        Icons.phone,
                      ).copyWith(prefixText: '+88 ', counterText: ''),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 15),

                    // Patient Type dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _patientType,
                      decoration: _inputDecoration(
                        'User Role',
                        Icons.person_search,
                      ),
                      items: ['STUDENT', 'TEACHER', 'STAFF']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type[0] + type.substring(1).toLowerCase(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _patientType = val ?? 'STUDENT';
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // Blood Group
                    DropdownButtonFormField<String>(
                      initialValue: _bloodGroupController!.text.isEmpty
                          ? null
                          : _bloodGroupController!.text,
                      decoration: _inputDecoration(
                        'Blood Group',
                        Icons.bloodtype,
                      ),
                      items: _bloodGroups
                          .map(
                            (bg) =>
                                DropdownMenuItem(value: bg, child: Text(bg)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _bloodGroupController!.text = val ?? '';
                        });
                      },
                      validator: _validateBloodGroup,
                    ),
                    const SizedBox(height: 15),

                    // Allergies
                    TextFormField(
                      controller: _allergiesController,
                      decoration: _inputDecoration(
                        'Allergies (Optional)',
                        Icons.warning,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field (stronger validation)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputDecoration('Password', Icons.lock)
                          .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: kPrimaryColor.withAlpha(179),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                      validator: _validatePassword,
                    ),

                    // Removed the horizontal chips here to move them below Confirm Password
                    const SizedBox(height: 12),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputDecoration(
                        'Confirm Password',
                        Icons.lock_reset,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController!.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // --- PASSWORD REQUIREMENTS LIST (vertical) ---
                    // This shows each requirement as a separate row after the Confirm Password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCriteriaRow(
                          _pwHasMinLength,
                          'At least 8 characters',
                        ),
                        const SizedBox(height: 6),
                        _buildCriteriaRow(
                          _pwHasUpperAndLower,
                          'Contains uppercase and lowercase',
                        ),
                        const SizedBox(height: 6),
                        _buildCriteriaRow(
                          _pwHasNumber,
                          'Contains at least one number',
                        ),
                        const SizedBox(height: 6),
                        _buildCriteriaRow(
                          _pwHasSpecial,
                          'Contains a special character (!@#\$%)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIGN UP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Already registered?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already Registered?',
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    },
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helper for vertical list rows
  Widget _buildCriteriaRow(bool ok, String label) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: ok ? Colors.green.shade800 : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
