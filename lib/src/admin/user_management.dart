import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:backend_client/backend_client.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  String selectedCategory = "All";
  final TextEditingController searchController = TextEditingController();
  final Color primaryColor = const Color(0xFF00796B);

  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  // Map UI role names to DB role enum values (lowercase used by endpoints)
  String _mapRoleToDb(String role) {
    switch (role) {
      case 'All':
        return 'ALL';
      case 'Doctor':
        return 'DOCTOR';
      case 'Dispenser':
        return 'DISPENSER';
      case 'Lab Staff':
        return 'LABSTAFF';
      case 'Patient':
        return 'STUDENT';
      case 'Admin':
        return 'ADMIN';
      default:
        return role.toLowerCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final role = _mapRoleToDb(selectedCategory);
      // If Patient is selected, fetch ALL from server and filter client-side to include student/teacher/staff.
      final fetchRole = selectedCategory == 'Patient' ? 'ALL' : role;
      // Call the endpoint. The client returns a typed list; treat it as List<dynamic>
      final result = await client.adminEndpoints.listUsersByRole(
        fetchRole,
        200,
      );
      final items = (result as List).cast<dynamic>();

      final list = <Map<String, dynamic>>[];
      for (final item in items) {
        // If it's already a Map, cast and use it.
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          // Normalize profile picture keys into profilePictureUrl
          final pic =
              (m['profilePictureUrl'] ??
              m['profile_picture_url'] ??
              m['profile_picture'] ??
              m['avatar'] ??
              m['picture'] ??
              m['picture_url']);
          if (pic != null) m['profilePictureUrl'] = pic.toString();
          list.add(m);
          continue;
        }

        // If the object has a toJson() method (typical for DTOs), call it.
        try {
          final dyn = item as dynamic;
          final json = dyn.toJson();
          if (json is Map) {
            final casted = Map<String, dynamic>.from(json);
            // remove protocol helper key if present
            casted.remove('__className__');
            // Normalize profile picture keys
            final pic2 =
                (casted['profilePictureUrl'] ??
                casted['profile_picture_url'] ??
                casted['profile_picture'] ??
                casted['avatar'] ??
                casted['picture'] ??
                casted['picture_url']);
            if (pic2 != null) casted['profilePictureUrl'] = pic2.toString();
            list.add(casted);
            continue;
          }
        } catch (e) {
          // ignore and try property access fallback
        }

        // Fallback: read common fields via dynamic property access
        try {
          final dyn = item as dynamic;
          list.add({
            'userId': dyn.userId?.toString() ?? '',
            'name': dyn.name ?? '',
            'email': dyn.email ?? '',
            'role': dyn.role ?? '',
            'phone': dyn.phone ?? '',
            'active': dyn.active == true,
            'profilePictureUrl':
                (dyn.profilePictureUrl ??
                        dyn.profile_picture_url ??
                        dyn.profile_picture ??
                        dyn.avatar ??
                        dyn.picture ??
                        dyn.picture_url)
                    ?.toString() ??
                '',
          });
          continue;
        } catch (e) {
          // If everything fails, skip this item
          debugPrint('Could not convert user item: $e');
        }
      }

      // If the UI selected 'Patient', show everyone except staff roles
      List<Map<String, dynamic>> resultList = list;
      if (selectedCategory == 'Patient') {
        // Include only patient-like roles: student, teacher, staff
        final include = {'student', 'teacher', 'staff'};
        resultList = list.where((u) {
          final r = (u['role'] ?? '').toString().toLowerCase();
          return include.contains(r);
        }).toList();
      }

      setState(() {
        _users = resultList;
      });
    } catch (e, st) {
      debugPrint('Failed to fetch users: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Icons.local_hospital;
      case 'dispenser':
        return Icons.medication;
      case 'labstaff':
        return Icons.science;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Widget _buildCategorySelector() {
    final categories = [
      'All',
      'Admin',
      'Doctor',
      'Dispenser',
      'Lab Staff',
      'Patient',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(category),
              selected: selectedCategory == category,
              selectedColor: primaryColor.withAlpha((0.8 * 255).round()),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: selectedCategory == category
                    ? Colors.white
                    : Colors.black87,
                fontWeight: selectedCategory == category
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected)
                  setState(() {
                    selectedCategory = category;
                    _fetchUsers();
                  });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase();
    final filtered = _users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return query.isEmpty || name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search User by Name or Email",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00796B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 10),
            _buildCategorySelector(),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        final profileUrl =
                            (user['profilePictureUrl'] ??
                                    user['profile_picture_url'] ??
                                    user['avatar'] ??
                                    user['picture'] ??
                                    user['picture_url'])
                                ?.toString() ??
                            '';
                        final role = (user['role'] ?? '').toString();
                        final isActive = (user['active'] == true);

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: primaryColor.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              child: (profileUrl.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        profileUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                _getIcon(role),
                                                color: primaryColor,
                                              );
                                            },
                                      ),
                                    )
                                  : Icon(_getIcon(role), color: primaryColor),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (context) {
                                    final phoneStr = (user['phone'] ?? '')
                                        .toString();
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          phoneStr,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.phone,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'Call',
                                          onPressed: phoneStr.isEmpty
                                              ? null
                                              : () => _launchPhone(phoneStr),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user['email'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.copy,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Copy email',
                                      onPressed: () {
                                        final email = (user['email'] ?? '')
                                            .toString();
                                        if (email.isNotEmpty) {
                                          Clipboard.setData(
                                            ClipboardData(text: email),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Email copied: $email',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Role: $role',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.blue,
                              ),
                              onSelected: (value) async {
                                if (value == 'toggle') {
                                  final uid =
                                      user['userId']?.toString() ??
                                      user['email']?.toString() ??
                                      '';
                                  final ok = await client.adminEndpoints
                                      .toggleUserActive(uid);
                                  if (ok == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isActive
                                              ? "${user['name']} deactivated"
                                              : "${user['name']} activated",
                                        ),
                                      ),
                                    );
                                    await _fetchUsers();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to update user status',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive ? Icons.lock_open : Icons.lock,
                                        color: isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isActive ? "Deactivate" : "Activate",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        label: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        String role = "Doctor";
        bool _isNameValid = true;
        bool _isEmailValid = true;
        bool _isPasswordValid = true;
        bool _isCreating = false;

        // simple email regex to validate format
        final emailRegex = RegExp(
          r"^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9.\-]+",
        );

        // local state that persists for the dialog's lifecycle
        bool _obscurePassword = true;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Helper to evaluate password criteria
            // Only require minimum 6 characters for password
            bool hasMinLen(String p) => p.length >= 6;
            String currentPassword() => passwordController.text;
            final pass = currentPassword();
            final passOk = hasMinLen(pass);

            return AlertDialog(
              title: const Text("Create New User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        errorText: _isNameValid
                            ? null
                            : "Name at least 4 characters",
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email/ID",
                        errorText: _isEmailValid ? null : "Enter a valid email",
                      ),
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (v) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: "Initial Password",
                        // replace lock icon with visibility toggle
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        errorText: _isPasswordValid
                            ? null
                            : "Password doesn't meet criteria",
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Only allow Admin, Doctor, Dispenser, Lab Staff
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      items: const [
                        DropdownMenuItem(value: "Admin", child: Text("Admin")),
                        DropdownMenuItem(
                          value: "Doctor",
                          child: Text("Doctor"),
                        ),
                        DropdownMenuItem(
                          value: "Dispenser",
                          child: Text("Dispenser"),
                        ),
                        DropdownMenuItem(
                          value: "Lab Staff",
                          child: Text("Lab Staff"),
                        ),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          role = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Select Role",
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Simple password hint: only minimum length required
                    Row(
                      children: [
                        Icon(
                          passOk
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: passOk ? Colors.green : Colors.black38,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Password must be at least 6 characters',
                          style: TextStyle(
                            color: passOk ? Colors.green : Colors.black54,
                          ),
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
                ElevatedButton(
                  onPressed: _isCreating
                      ? null
                      : () async {
                          bool isValid = true;
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final password = passwordController.text;

                          // Name validation: at least 4 characters
                          if (name.isEmpty || name.length < 4) {
                            isValid = false;
                            setStateDialog(() {
                              _isNameValid = false;
                            });
                          } else {
                            setStateDialog(() {
                              _isNameValid = true;
                            });
                          }

                          if (email.isEmpty || !emailRegex.hasMatch(email)) {
                            isValid = false;
                            setStateDialog(() {
                              _isEmailValid = false;
                            });
                          } else {
                            setStateDialog(() {
                              _isEmailValid = true;
                            });
                          }

                          // Password must be at least 6 characters
                          final passOkLocal = password.length >= 6;
                          if (!passOkLocal) {
                            isValid = false;
                            setStateDialog(() {
                              _isPasswordValid = false;
                            });
                          } else {
                            setStateDialog(() {
                              _isPasswordValid = true;
                            });
                          }

                          if (!isValid) return;

                          setStateDialog(() {
                            _isCreating = true;
                          });

                          final uid = email; // use email as uid
                          final dbRole = _mapRoleToDb(role);
                          try {
                            final res = await client.adminEndpoints
                                .createUserWithPassword(
                                  uid,
                                  name,
                                  email,
                                  password,
                                  dbRole,
                                  null,
                                );
                            if (res == 'OK') {
                              Navigator.pop(context);
                              await _fetchUsers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$role $name created successfully',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to create user: $res'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to create user'),
                              ),
                            );
                          } finally {
                            setStateDialog(() {
                              _isCreating = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text(
                    "Create",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling is not supported on web')),
      );
      return;
    }
    try {
      final ok = await launchUrl(uri);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error launching phone: $e')));
    }
  }
}
