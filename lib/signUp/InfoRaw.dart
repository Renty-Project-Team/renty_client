import 'package:flutter/material.dart';
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
