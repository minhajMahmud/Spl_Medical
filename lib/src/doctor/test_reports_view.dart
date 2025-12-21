import 'package:flutter/material.dart';

class TestReportsViewPage extends StatefulWidget {
  const TestReportsViewPage({super.key});

  @override
  State<TestReportsViewPage> createState() => _TestReportsViewPageState();
}

class _TestReportsViewPageState extends State<TestReportsViewPage> {
  final List<Map<String, dynamic>> _uploadedTests = [
    {
      'id': 'TR001',
      'patientName': 'Md Sabbir Ahamed',
      'patientId': 'P2024001',
      'testType': 'Blood Test',
      'uploadDate': '2024-01-20',
      'fileUrl': 'path/to/file.pdf',
      'status': 'pending', // pending, reviewed, deleted
    },
  ];

  void _viewTestReport(Map<String, dynamic> testReport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Test Report - ${testReport['testType']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient: ${testReport['patientName']}"),
            Text("ID: ${testReport['patientId']}"),
            Text("Upload Date: ${testReport['uploadDate']}"),
            SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text("(Actual file would be displayed here)")],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _deleteTestReport(testReport['id']);
              Navigator.pop(context);
            },
            child: Text("Delete Report", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              _markAsReviewed(testReport['id']);
              Navigator.pop(context);
            },
            child: Text("Mark as Reviewed"),
          ),
        ],
      ),
    );
  }

  void _deleteTestReport(String testId) {
    setState(() {
      _uploadedTests.removeWhere((test) => test['id'] == testId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Test report deleted successfully")));
  }

  void _markAsReviewed(String testId) {
    setState(() {
      var test = _uploadedTests.firstWhere((t) => t['id'] == testId);
      test['status'] = 'reviewed';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Test report marked as reviewed")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Test Reports"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _uploadedTests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 16),
                  Text(
                    'No test reports uploaded yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _uploadedTests.length,
              itemBuilder: (context, index) {
                final test = _uploadedTests[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      Icons.upload_file,
                      color: _getStatusColor(test['status']),
                    ),
                    title: Text(test['testType']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(test['patientName']),
                        Text("Uploaded: ${test['uploadDate']}"),
                        Text("Status: ${test['status']}"),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () => _viewTestReport(test),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.green;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
