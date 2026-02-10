import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSectionTitle extends StatelessWidget {
  final String title;

  const AppSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
