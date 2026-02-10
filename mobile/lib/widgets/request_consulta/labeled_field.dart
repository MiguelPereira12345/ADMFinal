import 'package:flutter/material.dart';
import 'field_label.dart';

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FieldLabel(label), const SizedBox(height: 8), child],
    );
  }
}
