import 'package:flutter/material.dart';
import 'dispenser_alternative_dialog.dart';

class Medicine {
  final String id;
  final String name;
  final String dose;
  int prescribedQty;
  int stock;
  bool isOutOfStock;
  Alternative? selectedAlternative;
  int dispenseQty;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.prescribedQty,
    required this.stock,
    this.isOutOfStock = false,
    this.selectedAlternative,
    int? dispenseQty,
  }) : dispenseQty = dispenseQty ?? prescribedQty;
}

class MedicineItem extends StatefulWidget {
  final Medicine medicine;
  final void Function(Medicine) onChanged;

  const MedicineItem({super.key, required this.medicine, required this.onChanged});

  @override
  State<MedicineItem> createState() => _MedicineItemState();
}

class _MedicineItemState extends State<MedicineItem> {
  late Medicine med;

  @override
  void initState() {
    super.initState();
    med = widget.medicine;
  }

  void _openAlternativePicker() {
    final alts = [
      Alternative(id: 'a1', name: 'Levocetirizine', dose: '5mg', stock: 36),
      Alternative(id: 'a2', name: 'Fexofenadine', dose: '120mg', stock: 22),
      Alternative(id: 'a3', name: 'Loratadine', dose: '10mg', stock: 18),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => AlternativeDialog(
        alternatives: alts,
        onSelect: (alt) {
          setState(() {
            med.selectedAlternative = alt;
            med.dispenseQty = med.dispenseQty <= alt.stock ? med.dispenseQty : alt.stock;
          });
          widget.onChanged(med);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = med.selectedAlternative == null ? 'Original' : 'Alternative';
    final stockDisplay =
    med.selectedAlternative == null ? med.stock : med.selectedAlternative!.stock;
    final nameDisplay =
    med.selectedAlternative == null ? med.name : med.selectedAlternative!.name;

    // Clamp dispenseQty to valid range
    // final maxQty = stockDisplay > med.prescribedQty ? med.prescribedQty : stockDisplay;
    // final currentQty = med.dispenseQty > maxQty ? maxQty : med.dispenseQty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$nameDisplay ${med.dose}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    stockDisplay > 0 ? 'In Stock' : 'Out of Stock',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Prescribed: ${med.prescribedQty}  •  Stock: $stockDisplay'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Quantity to Dispense:'),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: med.dispenseQty.toString()),
                    onChanged: (val) {
                      final qty = int.tryParse(val) ?? 0;
                      // Clamp quantity between 0 and available stock or prescribed quantity
                      final maxQty = stockDisplay > med.prescribedQty ? med.prescribedQty : stockDisplay;
                      setState(() => med.dispenseQty = qty.clamp(0, maxQty));
                      widget.onChanged(med);
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: med.selectedAlternative == null
                          ? Colors.teal
                          : Colors.orange),
                  onPressed: _openAlternativePicker,
                  child: Text(
                      med.selectedAlternative == null ? 'Substitute' : 'Change'),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Chip(label: Text(label)),
            )
          ],
        ),
      ),
    );
  }
}
