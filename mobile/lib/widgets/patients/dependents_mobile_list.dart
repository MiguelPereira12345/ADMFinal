import 'package:flutter/material.dart';
import 'dependent_row.dart';

class DependentsMobileList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onView;
  const DependentsMobileList({super.key, required this.items, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 18),
          DependentRow(item: items[i], onView: onView),
        ],
      ],
    );
  }
}
