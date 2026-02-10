import 'package:flutter/material.dart';
import 'widgets/app/app_colors.dart';
import 'widgets/app/app_scaffold.dart';
import 'widgets/app/app_card.dart';

/// Simplified contact page: shows only clinic information.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // Clinic information (could be moved to a model or localization)
  static const String clinicName = 'Clinimolelos';
  static const String openingHours = 'Seg–Sex: 9:00–19:00\nSáb: 9:00–19:00';
  static const String address =
      'Av. Dr. Adriano Figueiredo 158, 3460-009 Tondela';
  static const String phone = '+351 232 823 220';
  static const String email = 'contacto@clinicadentaria.pt';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Contactar Clínica',
      leading: AppLeading.close,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: AppCard(
              borderRadius: 16,
              color: AppColors.beige,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular badge + title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryGold,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'm.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: AppColors.primaryGold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinicName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Clínica Dentária',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(
                    color: AppColors.primaryGold,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  _infoRow(
                    context,
                    icon: Icons.schedule,
                    label: 'Horário',
                    value: openingHours,
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    context,
                    icon: Icons.location_on,
                    label: 'Morada',
                    value: address,
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    context,
                    icon: Icons.phone,
                    label: 'Telefone',
                    value: phone,
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    context,
                    icon: Icons.email,
                    label: 'Email',
                    value: email,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable info row used by the card. Kept as a method to keep layout consistent.
  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
