import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show ScaffoldMessenger, SnackBar, Colors, OutlineInputBorder, TextStyle;
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_radius.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';

/// iOS-safe toast. Uses [ScaffoldMessenger] when a Material Scaffold exists,
/// otherwise falls back to a Cupertino overlay pill that auto-dismisses.
/// This keeps copy/delete feedback working inside [CupertinoApp].
void showSnackBar(BuildContext context, String text) {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 10,
        shape: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 2),
        content: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
    return;
  } catch (_) {
    // No ScaffoldMessenger (pure Cupertino) — fall through to overlay.
  }

  final isDark =
      CupertinoTheme.of(context).brightness == Brightness.dark;
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (ctx) => Positioned(
      bottom: MediaQuery.of(ctx).padding.bottom + 90,
      left: 40,
      right: 40,
      child: CupertinoPopupSurface(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.textPrimary(isDark).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.background(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), entry.remove);
}