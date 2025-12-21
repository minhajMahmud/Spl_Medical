import 'package:flutter/material.dart';

class Alternative {
  final String id;
  final String name;
  final String dose;
  final int stock;

  Alternative({
    required this.id,
    required this.name,
    required this.dose,
    required this.stock,
  });
}

class AlternativeDialog extends StatefulWidget {
  final List<Alternative> alternatives;
  final void Function(Alternative) onSelect;

  const AlternativeDialog({
    super.key,
    required this.alternatives,
    required this.onSelect,
  });

  @override
  State<AlternativeDialog> createState() => _AlternativeDialogState();
}

class _AlternativeDialogState extends State<AlternativeDialog> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Select Alternative',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...widget.alternatives.map((a) {
            final selected = selectedId == a.id;
            return ListTile(
              leading: CircleAvatar(child: Text(a.name[0])),
              title: Text('${a.name} ${a.dose}'),
              subtitle: Text('Stock: ${a.stock}'),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => selectedId = a.id);
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: selectedId == null
                  ? null
                  : () {
                final chosen = widget.alternatives
                    .firstWhere((x) => x.id == selectedId);
                widget.onSelect(chosen);
                Navigator.of(context).pop();
              },
              child: const Text('Use Selected Alternative'),
            ),
          ),
        ],
      ),
    );
  }
}
