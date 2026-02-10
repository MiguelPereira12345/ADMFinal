import 'package:flutter/material.dart';
import '../app/app_card.dart';
import 'dependents_table.dart';
import 'dependents_mobile_list.dart';

class DependentsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onView;

  const DependentsCard({super.key, required this.items, required this.onView});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          if (isWide) {
            return DependentsTable(items: items, onView: onView);
          }
          return DependentsMobileList(items: items, onView: onView);
        },
      ),
    );
  }
}
