import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final Color primaryGold;
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.primaryGold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = (plan['titulo'] ?? plan['nome'] ?? plan['name'] ?? 'Plano')
        .toString();
    final doctor =
        (plan['doctor'] ?? plan['medico'] ?? plan['responsavel'] ?? '')
            .toString();
    final status = (plan['status'] ?? plan['estado'] ?? '').toString();
    // Assuming status logic for different colors
    final isPending = status.toLowerCase().contains('pen');
    final isConfirmed =
        status.toLowerCase().contains('con') ||
        status.toLowerCase().contains('ati');

    final statusBg = isPending
        ? const Color(0xFFFFF8E1)
        : (isConfirmed ? const Color(0xFFE8F5E9) : Colors.grey.shade50);
    final statusText = isPending
        ? const Color(0xFFF57C00)
        : (isConfirmed ? const Color(0xFF2E7D32) : Colors.grey.shade700);
    final statusBorder = isPending
        ? const Color(0xFFFFE0B2)
        : (isConfirmed ? const Color(0xFFA5D6A7) : Colors.grey.shade200);

    // Info string similar to date/time or sessions
    final info = (plan['sessoes'] ?? plan['sessions'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (status.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.black26,
                      size: 20,
                    ),
                  ],
                ),
                if (info.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    info,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (doctor.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Profissional: $doctor',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
