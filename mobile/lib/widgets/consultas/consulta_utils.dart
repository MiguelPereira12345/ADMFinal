import 'package:flutter/material.dart';

({Color bg, Color fg}) statusBadge(String status) {
  final s = status.trim().toLowerCase();
  if (s.contains('confirm')) {
    return (bg: const Color(0xFFE7F8ED), fg: const Color(0xFF1B7F3A));
  }
  if (s.contains('pend')) {
    return (bg: const Color(0xFFFFF4D6), fg: const Color(0xFF8A6A00));
  }
  if (s.contains('cancel') || s.contains('rejeit') || s.contains('recus')) {
    return (bg: const Color(0xFFFFE8E8), fg: const Color(0xFFB42318));
  }
  // Default neutral.
  return (bg: const Color(0xFFEFF4FF), fg: const Color(0xFF2F5BEA));
}
