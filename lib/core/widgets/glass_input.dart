// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_container.dart';

class GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool autofocus;

  const GlassInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LiquidGlassContainer(
      level: 1,
      customRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        keyboardType: keyboardType,
        autofocus: autofocus,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent, // Handled by container
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}





