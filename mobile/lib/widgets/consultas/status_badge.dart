import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const StatusBadge({super.key, required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.30)),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
