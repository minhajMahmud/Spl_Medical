import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or ID is required';
    }
    return null; // no other checks
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null; // no length check
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double horizontalPadding;
    if (screenWidth < 600) {
      horizontalPadding = 20.0; // মোবাইল
    } else {
      horizontalPadding = screenWidth * 0.3; // ওয়েব/ট্যাব
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 30,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                // Icon with shadow
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.local_hospital,
                    size: 60,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 20),
                // Title
                Text(
                  'Dishari',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.blue.shade700,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 30),

                // ID/Email Field
                TextFormField(
                  //input validation er jonne textformfield use kora hoise
                  controller: _idController,
                  obscureText: false,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Enter your ID or Email',
                    hintText: 'ASH****M',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _validateEmail,
                ),

                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Enter Your Password',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final input = _idController.text.trim().toLowerCase();

                        String? route;
                        String? role;
                        if (input == 'admin@gmail.com') {
                          route = '/admin-dashboard';
                          role = 'ADMIN';
                        } else if (input == 'patient@gmail.com') {
                          route = '/patient-dashboard';
                          role = 'PATIENT';
                        } else if (input == 'dispenser@gmail.com') {
                          route = '/dispenser-dashboard';
                          role = 'DISPENSER';
                        } else if (input == 'doctor@gmail.com') {
                          route = '/doctor-dashboard';
                          role = 'DOCTOR';
                        } else if (input == 'lab@gmail.com') {
                          route = '/lab-dashboard';
                          role = 'LABSTAFF';
                        }

                        if (route != null) {
                          // Persist session info for profile pages
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('user_id', input);
                            if (role != null) {
                              await prefs.setString('role', role);
                            }
                          } catch (_) {
                            // If storing fails, continue navigation but warn
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Warning: Failed to persist session',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          // Navigate to dashboard
                          if (!mounted) return;
                          Navigator.pushNamed(context, route);
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  'Invalid Input',
                                  textAlign: TextAlign.center,
                                ),
                                content: const Text(
                                  'Please enter (admin/doctor/lab/patient/\ndispenser)@gmail.com and any password',
                                  style: TextStyle(color: Colors.red),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: Colors.blue.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 16,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Forget Password Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Forget Password?'),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Click here'),
                    ),
                  ],
                ),

                // SignUp Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Not yet registered?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/patient-signup');
                      },
                      child: const Text('SignUp'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
