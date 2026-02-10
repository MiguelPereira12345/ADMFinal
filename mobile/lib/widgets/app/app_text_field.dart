import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Color? fillColor;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: prefixIcon != null 
              ? Icon(prefixIcon, color: AppColors.textSecondary) 
              : null,
        ),
      ),
    );
  }
}
