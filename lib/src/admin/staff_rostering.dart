import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';

class StaffRostering extends StatefulWidget {
  const StaffRostering({super.key});

  @override
  State<StaffRostering> createState() => _StaffRosteringState();
}

class _StaffRosteringState extends State<StaffRostering>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF00796B); // Deep Teal
  bool _isCurrentWeek = true; // State to track which week is active

  List<Map<String, dynamic>> _currentWeekRoster = [];
  List<Map<String, dynamic>> _nextWeekRoster = [];
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
    });
    await Future.wait([_fetchStaff(), _fetchRosters()]);
    // If empty, initialize with placeholders to keep UI consistent
    if (_currentWeekRoster.isEmpty) {
      _currentWeekRoster = [
        {"day": "Monday", "role_1": "N/A", "role_2": "N/A"},
        {"day": "Tuesday", "role_1": "N/A", "role_2": "N/A"},
        {"day": "Wednesday", "role_1": "N/A", "role_2": "N/A"},
        {"day": "Thursday", "role_1": "N/A", "role_2": "N/A"},
        {"day": "Friday", "role_1": "N/A", "role_2": "N/A"},
      ];
    }
    if (_nextWeekRoster.isEmpty) {
      _nextWeekRoster = List.from(_currentWeekRoster.map((e) => Map.from(e)));
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchStaff() async {
    try {
      final res = await client.adminEndpoints.listStaff(200);
      setState(() {
        _staffList = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Failed to fetch staff: $e');
    }
  }

  Future<void> _fetchRosters() async {
    try {
      final res = await client.adminEndpoints.getRosters();
      final rows = List<Map<String, dynamic>>.from(res);
      // Map rows into week views (simple mapping by day for example)
      // For simplicity, keep existing placeholders; a more complete mapping requires date parsing.
      debugPrint('Loaded rosters: ${rows.length}');
    } catch (e) {
      debugPrint('Failed to fetch rosters: $e');
    }
  }

  // --- Actions ---

  void _handleRequest(dynamic req, bool approve) async {
    // Accept dynamic to handle Map<String,String> or Map<String,dynamic> from different call sites
    setState(() {
      _requests.remove(req);
    });

    final name = (req is Map ? (req['name'] ?? '') : '').toString();
    final day = (req is Map ? (req['day'] ?? '') : '').toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$name request for $day has been ${approve ? 'approved' : 'rejected'}",
        ),
        backgroundColor: approve ? Colors.green : Colors.red,
      ),
    );

    // Optionally save audit log
    await client.adminEndpoints.addAuditLog(
      'log_${DateTime.now().millisecondsSinceEpoch}',
      'system',
      'Roster request ${approve ? 'approved' : 'rejected'} for $name',
    );
  }

  void _openRosterEditor(
    List<Map<String, dynamic>> roster, {
    required bool isNewSchedule,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isNewSchedule
              ? "Edit Next Week Schedule"
              : "Edit Current Week Schedule",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: roster.length,
            itemBuilder: (context, index) {
              final dayRoster = roster[index];
              final TextEditingController role1Controller =
                  TextEditingController(text: dayRoster['role_1']);
              final TextEditingController role2Controller =
                  TextEditingController(text: dayRoster['role_2']);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayRoster['day']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: role1Controller,
                        decoration: const InputDecoration(
                          labelText: "Doctor / Staff (Day Shift)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: role2Controller,
                        decoration: const InputDecoration(
                          labelText: "Doctor / Staff (Night Shift)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(
                            Icons.save,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "Save Day",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            setState(() {
                              dayRoster['role_1'] = role1Controller.text;
                              dayRoster['role_2'] = role2Controller.text;
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${dayRoster['day']} updated successfully ✅",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // save roster to backend with a generated id
                            final rosterId =
                                'rost_${DateTime.now().millisecondsSinceEpoch}';
                            await client.adminEndpoints.saveRoster(
                              rosterId: rosterId,
                              staffId: role1Controller.text,
                              shiftType: 'MORNING',
                              shiftDate: DateTime.now(),
                              timeRange: '09:00-17:00',
                              status: 'SCHEDULED',
                            );

                            // Conflict check
                            if (_checkConflict(role1Controller.text, roster)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "⚠️ CONFLICT DETECTED: Staff is overscheduled!",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  bool _checkConflict(String staffName, List<Map<String, dynamic>> roster) {
    int count = 0;
    for (var dayRoster in roster) {
      final r1 = (dayRoster['role_1'] ?? '').toString();
      final r2 = (dayRoster['role_2'] ?? '').toString();
      if (r1.contains(staffName) || r2.contains(staffName)) {
        count++;
      }
    }
    return count > 1;
  }

  Widget _buildWeekToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ToggleButtons(
        isSelected: [_isCurrentWeek, !_isCurrentWeek],
        onPressed: (index) {
          setState(() {
            _isCurrentWeek = index == 0;
          });
        },
        constraints: BoxConstraints.expand(
          width: (MediaQuery.of(context).size.width - 32) / 2,
          height: 40,
        ),
        color: primaryColor,
        selectedColor: Colors.white,
        fillColor: primaryColor,
        borderRadius: BorderRadius.circular(10),
        borderWidth: 0,
        borderColor: Colors.transparent,
        children: const [
          Text("Current Week", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("Next Week", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRosterView() {
    final activeRoster = _isCurrentWeek ? _currentWeekRoster : _nextWeekRoster;
    return ListView.builder(
      itemCount: activeRoster.length,
      itemBuilder: (context, index) {
        final dayRoster = activeRoster[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayRoster['day']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.person, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dayRoster['role_1']!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const VerticalDivider(),
                    const Icon(Icons.person_pin, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dayRoster['role_2']!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsView() {
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          "✅ No Pending Leave/Shift Requests.",
          style: TextStyle(color: primaryColor),
        ),
      );
    }
    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.pending_actions, color: Colors.orange),
            title: Text(
              req['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Day: ${req['day']}\nReason: ${req['reason']}"),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    _handleRequest(req as Map<String, dynamic>, true);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {
                    _handleRequest(req as Map<String, dynamic>, false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildWeekToggle(),
          PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: "Roster View", icon: Icon(Icons.calendar_view_week)),
                Tab(text: "Requests", icon: Icon(Icons.list_alt)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildRosterView(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildRequestsView(),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Button for Roster Management
      floatingActionButton: Builder(
        builder: (context) {
          if (_isCurrentWeek) {
            return FloatingActionButton.extended(
              onPressed: () => _openRosterEditor(
                _currentWeekRoster
                    .map((e) => e.map((k, v) => MapEntry(k, v.toString())))
                    .toList(),
                isNewSchedule: false,
              ),
              label: const Text(
                "Edit Current Week Roster",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.edit_calendar, color: Colors.white),
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            );
          } else {
            return FloatingActionButton.extended(
              onPressed: () => _openRosterEditor(
                _nextWeekRoster
                    .map((e) => e.map((k, v) => MapEntry(k, v.toString())))
                    .toList(),
                isNewSchedule: true,
              ),
              label: const Text(
                "Edit Next Week Roster",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.edit_calendar, color: Colors.white),
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            );
          }
        },
      ),
    );
  }
}
