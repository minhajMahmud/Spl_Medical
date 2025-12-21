import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:backend_client/backend_client.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  final Color primaryColor = const Color(0xFF00796B); // Deep Teal
  final Color lowStockColor = Colors.orange.shade700;
  final Color criticalStockColor = Colors.red.shade700;

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _loading = true);
    await Future.wait([_fetchMedicines(), _fetchLowStock()]);
    setState(() => _loading = false);
  }

  Future<void> _fetchMedicines() async {
    try {
      final result = await client.adminEndpoints.listMedicines();
      setState(() {
        _medicines = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      debugPrint('Failed to fetch medicines: $e');
    }
  }

  Future<void> _fetchLowStock() async {
    try {
      final result = await client.adminEndpoints.getLowStockItems();
      setState(() {
        _lowStockItems = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      debugPrint('Failed to fetch low stock items: $e');
    }
  }

  Future<void> _viewMedicine(Map<String, dynamic> medicine) async {
    final _batchIdController = TextEditingController();
    final _quantityController = TextEditingController();
    DateTime _selectedExpiryDate = DateTime.now().add(
      const Duration(days: 365),
    ); // Default to 1 year later

    // fetch batches
    List<Map<String, dynamic>> batches = [];
    try {
      batches = List<Map<String, dynamic>>.from(
        await client.adminEndpoints.getMedicineBatches(medicine['medicineId']),
      );
    } catch (e) {
      debugPrint('Failed to fetch batches: $e');
    }

    await showDialog(
      context: context,
      builder: (context) {
        String? _errorText;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                medicine['name'],
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Stock: ${medicine['totalStock'] ?? 0}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Earliest Expiry: ${medicine['earliestExpiry'] ?? '-'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Divider(),

                    const Text(
                      "Current Batches:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...batches.map((batch) {
                      final expiry = batch['expiry'] != null
                          ? DateFormat(
                              'yy-MM',
                            ).format(DateTime.parse(batch['expiry']))
                          : '-';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "ID: ${batch['batchId']} | Stock: ${batch['stock']} | Expires: $expiry",
                        ),
                      );
                    }),

                    const Divider(),
                    const Text(
                      "Add New Batch:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    TextField(
                      controller: _batchIdController,
                      decoration: const InputDecoration(
                        labelText: "New Batch ID (e.g., NAPA-003)",
                      ),
                    ),

                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Quantity to Add",
                        errorText:
                            _errorText, // Show red error text if validation fails
                      ),
                    ),

                    ListTile(
                      title: const Text("Select Expiry Date:"),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedExpiryDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedExpiryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null && picked != _selectedExpiryDate) {
                          setStateDialog(() {
                            _selectedExpiryDate = picked;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final quantityText = _quantityController.text;
                        final batchId = _batchIdController.text.trim();
                        final quantity = int.tryParse(quantityText);

                        if (batchId.isEmpty ||
                            quantity == null ||
                            quantity <= 0) {
                          setStateDialog(() {
                            _errorText =
                                "Enter a valid Batch ID and positive Quantity.";
                          });
                          return;
                        }

                        // Call backend to add batch
                        final ok = await client.adminEndpoints.addMedicineBatch(
                          medicine['medicineId'],
                          batchId,
                          quantity,
                          _selectedExpiryDate,
                        );
                        if (ok == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${medicine['name']} - Batch $batchId added with $quantity.",
                              ),
                            ),
                          );
                          // refresh lists
                          await _fetchMedicines();
                          await _fetchLowStock();
                          Navigator.pop(context);
                        } else {
                          setStateDialog(() {
                            _errorText = 'Failed to add batch.';
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle, color: Colors.white),
                      label: const Text(
                        "Add New Batch",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
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

    _batchIdController.dispose();
    _quantityController.dispose();
  }

  void _showAddMedicineDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController minStockController = TextEditingController(
      text: "10",
    );

    bool _isNameValid = true;
    bool _ = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text("Add New Medicine"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Medicine Name",
                        errorText: _isNameValid ? null : "Required",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Minimum Stock",
                        errorText: null,
                      ),
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
                  onPressed: () async {
                    bool isValid = true;

                    if (nameController.text.isEmpty) {
                      isValid = false;
                      setStateDialog(() => _isNameValid = false);
                    } else {
                      setStateDialog(() => _isNameValid = true);
                    }

                    final minStock =
                        int.tryParse(minStockController.text) ?? 10;

                    if (!isValid) return;

                    Navigator.pop(context);

                    final id = await client.adminEndpoints.addMedicine(
                      nameController.text.trim(),
                      minStock,
                    );
                    if (id != -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Medicine added successfully"),
                        ),
                      );
                      await _fetchMedicines();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to add medicine")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                  ),
                  child: const Text(
                    "Add",
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

  @override
  Widget build(BuildContext context) {
    final lowStockItems = _lowStockItems;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (lowStockItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🔴 Low Stock Alerts (${lowStockItems.length})",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: criticalStockColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...lowStockItems.map((product) {
                            return Card(
                              color: lowStockColor.withOpacity(0.1),
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: lowStockColor),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.warning,
                                  color: lowStockColor,
                                ),
                                title: Text(
                                  product['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: lowStockColor,
                                  ),
                                ),
                                subtitle: Text(
                                  "Current Stock: ${product['totalStock']} . Threshold: ${product['minimumStock']}",
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () async {
                                  // find corresponding medicine in _medicines
                                  final med = _medicines.firstWhere(
                                    (m) =>
                                        m['medicineId'] ==
                                        product['medicineId'],
                                    orElse: () => product,
                                  );
                                  await _viewMedicine(med);
                                },
                              ),
                            );
                          }),
                          const Divider(height: 30),
                        ],
                      ),
                    ),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = _medicines[index];
                      final status = _getStockStatusFromTotals(product);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.08),
                            child: Icon(Icons.medication, color: primaryColor),
                          ),
                          title: Text(
                            product['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Stock: ${product['totalStock'] ?? 0} | Min: ${product['minimumStock'] ?? 0}',
                          ),
                          trailing: Text(
                            status['text'],
                            style: TextStyle(color: status['color']),
                          ),
                          onTap: () async => await _viewMedicine(product),
                        ),
                      );
                    }, childCount: _medicines.length),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineDialog,
        label: const Text(
          'Add Medicine',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Map<String, dynamic> _getStockStatusFromTotals(Map<String, dynamic> product) {
    final stock = (product['totalStock'] ?? 0) as int;
    final threshold = (product['minimumStock'] ?? 10) as int;
    if (stock <= 0) {
      return {'color': criticalStockColor, 'text': 'Out of Stock'};
    } else if (stock < threshold) {
      return {'color': lowStockColor, 'text': 'Low Stock Alert!'};
    }
    return {'color': primaryColor.withOpacity(0.7), 'text': 'In Stock'};
  }
}
