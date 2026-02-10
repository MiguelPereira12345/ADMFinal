import 'package:flutter/material.dart';

class SelectField extends StatelessWidget {
  final bool enabled;
  final String value;
  final VoidCallback? onTap;
  final InputDecoration decoration;

  const SelectField({
    super.key,
    required this.enabled,
    required this.value,
    required this.onTap,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final display = value.isEmpty ? '—' : value;
    final effectiveOnTap = enabled ? onTap : null;

    return InkWell(
      onTap: effectiveOnTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: decoration.copyWith(
          enabled: enabled,
          suffixIcon: const Icon(Icons.keyboard_arrow_down),
        ),
        child: Text(
          display,
          style: textStyle?.copyWith(
            color: enabled ? null : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
