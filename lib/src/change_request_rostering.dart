import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeRequestRostering extends StatefulWidget {
  final String userRole; // 'doctor', 'lab_staff', 'dispenser'
  final String userName;

  const ChangeRequestRostering({
    super.key,
    required this.userRole,
    required this.userName,
  });

  @override
  State<ChangeRequestRostering> createState() => _ChangeRequestRosteringState();
}

class _ChangeRequestRosteringState extends State<ChangeRequestRostering> {
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _shiftChangeRequests = [];
  bool _isLoading = false;
  bool _isLoadingRequests = false;
  String _userId = '';
  String? _errorMessage;
  String? _requestsErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedulesFromDatabase();
    _loadMyRequests();
  }

  Future<void> _loadSchedulesFromDatabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ?? '';

      if (_userId.isEmpty) {
        throw Exception('User not logged in. Please login again.');
      }

      // Fetch rosters from database for this user
      // Filter by approved_by = 'admin@gmail.com' and status = 'SCHEDULED'
      final rosters = await client.adminEndpoints.getRosters(
        staffId: _userId,
        fromDate: null,
        toDate: null,
      );

      // Convert rosters to shift format and filter by admin approval
      final List<Map<String, dynamic>> approvedShifts = [];

      for (final roster in rosters) {
        final approvedBy = roster['approvedBy']?.toString() ?? '';
        final status = roster['status']?.toString() ?? '';

        // Only show schedules approved by admin@gmail.com
        if (approvedBy == 'admin@gmail.com' &&
            status.toUpperCase() == 'SCHEDULED') {
          approvedShifts.add({
            'id': roster['rosterId'],
            'type': roster['shiftType'] ?? 'Regular',
            'time': roster['timeRange'] ?? 'Not specified',
            'date': roster['shiftDate']?.toString().split(' ')[0] ?? 'N/A',
            'assignedStaff': widget.userName,
            'staffRole': widget.userRole,
            'status': status.toLowerCase(),
            'approvedBy': approvedBy,
          });
        }
      }

      setState(() {
        _shifts = approvedShifts;
        _isLoading = false;
        _errorMessage = null;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Error loading schedules'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadSchedulesFromDatabase,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Connection error. Please check your internet connection.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection error. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadSchedulesFromDatabase,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMyRequests() async {
    setState(() {
      _isLoadingRequests = true;
      _requestsErrorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      if (userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final requests = await client.adminEndpoints.getMyChangeRequests(userId);

      setState(() {
        _shiftChangeRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
        _requestsErrorMessage = 'Failed to load requests: $e';
      });
    }
  }

  Future<void> _requestShiftChange(String shiftId, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      final result = await client.adminEndpoints.submitChangeRequest(
        rosterId: shiftId,
        staffId: userId,
        reason: reason,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Request submitted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Reload requests to show the new one
        _loadMyRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showShiftChangeDialog(Map<String, dynamic> shift) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Shift Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${_getRoleDisplayName(widget.userRole)}'),
            Text('Shift: ${shift['type']}'),
            Text('Date: ${shift['date']}'),
            Text('Time: ${shift['time']}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for change',
                border: OutlineInputBorder(),
                hintText: 'e.g., Medical appointment, family emergency',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              Navigator.pop(context);
              await _requestShiftChange(
                shift['id'],
                reasonController.text.trim(),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'doctor':
        return 'Doctor';
      case 'lab_staff':
        return 'Lab Staff';
      case 'dispenser':
        return 'Dispenser';
      default:
        return 'Staff';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'doctor':
        return Colors.blue;
      case 'lab_staff':
        return Colors.green;
      case 'dispenser':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services;
      case 'lab_staff':
        return Icons.science;
      case 'dispenser':
        return Icons.medication;
      default:
        return Icons.person;
    }
  }

  Color _getShiftColor(String shiftType) {
    switch (shiftType) {
      case 'Morning':
        return Colors.orange.shade100;
      case 'Afternoon':
        return Colors.blue.shade100;
      case 'Night':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue.shade100;
      case 'confirmed':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      case 'completed':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRequestStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getRoleDisplayName(widget.userRole)} Schedule'),
        foregroundColor: _getRoleColor(widget.userRole),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedulesFromDatabase,
            tooltip: 'Refresh schedules',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Material(
              color: _getRoleColor(widget.userRole).withOpacity(0.1),
              child: TabBar(
                labelColor: _getRoleColor(widget.userRole),
                unselectedLabelColor: Colors.grey,
                indicatorColor: _getRoleColor(widget.userRole),
                tabs: const [
                  Tab(icon: Icon(Icons.schedule), text: 'My Schedule'),
                  Tab(icon: Icon(Icons.pending_actions), text: 'My Requests'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // My Schedule Tab
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error Loading Schedules',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadSchedulesFromDatabase,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getRoleColor(
                                      widget.userRole,
                                    ),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _shifts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No approved schedules found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Schedules approved by admin@gmail.com will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _shifts.length,
                          itemBuilder: (context, index) {
                            final shift = _shifts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getShiftColor(
                                    shift['type'],
                                  ),
                                  child: Icon(
                                    _getRoleIcon(widget.userRole),
                                    color: _getRoleColor(widget.userRole),
                                  ),
                                ),
                                title: Text(
                                  '${shift['type']} Shift',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date: ${shift['date']}'),
                                    Text('Time: ${shift['time']}'),
                                    if (shift['approvedBy'] != null)
                                      Text(
                                        'Approved by: ${shift['approvedBy']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(
                                            shift['status']
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  _getStatusColor(
                                                        shift['status'],
                                                      ).computeLuminance() >
                                                      0.5
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                          ),
                                          backgroundColor: _getStatusColor(
                                            shift['status'],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(
                                            _getRoleDisplayName(
                                              widget.userRole,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: _getRoleColor(
                                            widget.userRole,
                                          ).withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: shift['status'] == 'scheduled'
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: _getRoleColor(widget.userRole),
                                        ),
                                        onPressed: () =>
                                            _showShiftChangeDialog(shift),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),

                  // My Requests Tab
                  _isLoadingRequests
                      ? const Center(child: CircularProgressIndicator())
                      : _requestsErrorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error Loading Requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _requestsErrorMessage!,
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadMyRequests,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _shiftChangeRequests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pending_actions,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No shift change requests',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _shiftChangeRequests.length,
                          itemBuilder: (context, index) {
                            final request = _shiftChangeRequests[index];
                            final status = (request['status'] ?? 'pending')
                                .toString()
                                .toLowerCase();
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getRequestStatusIcon(status),
                                          color: _getRequestStatusColor(status),
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${request['shiftType']} Shift',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'Date: ${request['shiftDate']}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            status.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor:
                                              _getRequestStatusColor(status),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    const Text(
                                      'Reason:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request['reason'] ?? 'No reason provided',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Time: ${request['timeRange'] ?? 'Not specified'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Requested: ${_formatDateTime(request['requestDate'] ?? '')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (request['requestId'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Request ID: #${request['requestId']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
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
