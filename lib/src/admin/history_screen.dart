import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:backend_client/backend_client.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Color primaryColor = const Color(0xFF00796B); // Deep Teal
  List<Map<String, dynamic>> historyItems = [];
  bool _loading = false;
  int _limit = 50;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _loading = true; });
    try {
      final res = await client.adminEndpoints.getAuditLogs(_limit, _offset);
      setState(() {
        historyItems = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Failed to load audit logs: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit_note;
      case 'stock_in':
        return Icons.arrow_circle_up;
      case 'stock_out':
        return Icons.arrow_circle_down;
      case 'admin_action':
        return Icons.verified_user;
      default:
        return Icons.history;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'stock_in':
        return Colors.lightGreen;
      case 'stock_out':
        return Colors.red;
      case 'admin_action':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          final item = historyItems[index];
          final action = (item['action'] ?? '').toString();
          final type = action.contains('updated') ? 'update' : (action.contains('restocked') ? 'stock_in' : 'admin_action');
          final icon = _getActionIcon(type);
          final color = _getIconColor(type);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(
                item['userId'] ?? 'System', // User who made the change
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(item['action'] ?? '' , style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy-MM-dd | HH:mm').format(DateTime.parse(item['timestamp'] ?? DateTime.now().toString())),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}