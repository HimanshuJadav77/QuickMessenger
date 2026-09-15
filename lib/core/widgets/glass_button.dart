import 'package:quick_messenger/core/theme/app_typography.dart';
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_shadows.dart';
import '../theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlassButton extends ConsumerWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(themeStateProvider).accentColor;
    
    if (isOutlined) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white, width: 1.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.title.fontSize,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.buttonShadow(accentColor),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.title.fontSize,
            fontWeight: FontWeight.bold,
            color: textColor ?? accentColor,
          ),
        ),
      ),
    );
  }
}






