import 'package:flutter/material.dart';
import 'row_data.dart';
import 'key_value_line.dart';
import 'status_badge.dart';

class DetailsCard extends StatelessWidget {
  final List<RowData> rows;
  final String statusText;
  final Color statusBg;
  final Color statusFg;

  const DetailsCard({
    super.key,
    required this.rows,
    required this.statusText,
    required this.statusBg,
    required this.statusFg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes da Consulta',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Informação principal e estado',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                StatusBadge(text: statusText, bg: statusBg, fg: statusFg),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            for (int i = 0; i < rows.length; i++) ...[
              KeyValueLine(label: rows[i].label, value: rows[i].value),
              if (i != rows.length - 1) const Divider(height: 1),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
