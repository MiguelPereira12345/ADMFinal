import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String displayString(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();

String? firstString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

String? formatDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  // If it's already ISO like, parse it
  final s = raw.trim();
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  return DateFormat('yyyy-MM-dd').format(dt);
}

String formatDateTime(DateTime d) {
  return DateFormat('yyyy-MM-dd').format(d);
}

String formatTimeOfDay(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String? formatDatePt(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  DateTime? dt = DateTime.tryParse(s);
  dt ??= DateTime.tryParse(s.replaceFirst(' ', 'T'));
  if (dt == null) return s;
  return DateFormat('dd/MM/yyyy').format(dt);
}

String? formatHour(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s)) {
    return s.substring(0, 5);
  }
  if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return s;
  return s;
}

String? formatDurationMinutes(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return ' min';
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  final n = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
  if (n == null) return s;
  return ' min';
}
