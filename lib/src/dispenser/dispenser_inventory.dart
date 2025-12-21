import 'package:flutter/material.dart';

class MedicineInventory {
  final String id;
  final String name;
  final String category;
  int currentStock;
  int minThreshold;
  DateTime? expiryDate;
  String manufacturer;
  DateTime addedDate;

  MedicineInventory({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minThreshold,
    this.expiryDate,
    required this.manufacturer,
    required this.addedDate,
  });
}

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  final List<MedicineInventory> _inventory = [
    MedicineInventory(
      id: 'M001',
      name: 'Paracetamol',
      category: 'Analgesic',
      currentStock: 150,
      minThreshold: 50,
      expiryDate: DateTime(2025, 12, 31),
      manufacturer: 'Square Pharmaceuticals',
      addedDate: DateTime(2025, 10, 8),
    ),
    MedicineInventory(
      id: 'M002',
      name: 'Amoxicillin',
      category: 'Antibiotic',
      currentStock: 80,
      minThreshold: 30,
      expiryDate: DateTime(2025, 10, 15),
      manufacturer: 'Beximco Pharma',
      addedDate: DateTime(2025, 10, 9),
    ),
    MedicineInventory(
      id: 'M003',
      name: 'Cetirizine',
      category: 'Antihistamine',
      currentStock: 25,
      minThreshold: 20,
      expiryDate: DateTime(2025, 8, 20),
      manufacturer: 'ACI Limited',
      addedDate: DateTime(2025, 10, 10),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: Column(
        children: [
          // 🔸 LOW STOCK ALERT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Low Stock Alert:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_inventory.where((item) => item.currentStock <= item.minThreshold).length} items',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 28),
                  ],
                ),
              ),
            ),
          ),

          // 🔸 INVENTORY COUNT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Total Medicines: ${_inventory.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 🔸 MEDICINE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final item = _inventory[index];
                final isLowStock = item.currentStock <= item.minThreshold;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLowStock ? Colors.red : Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: isLowStock ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.red : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${item.id} • ${item.category}'),
                          Text('Manufacturer: ${item.manufacturer}'),
                          Text(
                            'Stock: ${item.currentStock} (Min: ${item.minThreshold})',
                            style: TextStyle(
                              color: isLowStock ? Colors.red : Colors.black,
                              fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (item.expiryDate != null)
                            Text('Expiry: ${item.expiryDate!.toString().split(' ')[0]}'),
                          const SizedBox(height: 4),
                          Text(
                            '🕒 Added: ${item.addedDate.day}/${item.addedDate.month}/${item.addedDate.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔸 RESTOCK BUTTON AND ICON
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          isLowStock ? Icons.warning : Icons.check_circle,
                          color: isLowStock ? Colors.orange : Colors.green,
                          size: 24,
                        ),
                        const SizedBox(height: 4),

                        ElevatedButton(
                          onPressed: () {
                            final restockController = TextEditingController();

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                    'Restock ${item.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Current Stock: ${item.currentStock}'),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: restockController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Quantity to Add *',
                                          border: OutlineInputBorder(),
                                          hintText: 'Enter quantity',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '* Enter the quantity to add to current stock',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final quantity = int.tryParse(restockController.text) ?? 0;

                                        if (quantity <= 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please enter a valid quantity'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          item.currentStock += quantity;
                                        });

                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '✅ ${item.name} restocked! Added $quantity units. New stock: ${item.currentStock}',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Restock'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: const Size(0, 0),
                          ),
                          child: const Text(
                            'Restock',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
