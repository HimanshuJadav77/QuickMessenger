import 'dart:ui' as dart_ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class GlassDialog {
  /// Frosted liquid glass confirmation dialog with haptic feedback
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    VoidCallback? onConfirm,
  }) {
    HapticFeedback.mediumImpact();
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentPurple;

    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CupertinoAlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF636366),
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  cancelLabel,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF3C3C43),
                  ),
                ),
              ),
              CupertinoDialogAction(
                isDestructiveAction: isDestructive,
                onPressed: () {
                  Navigator.pop(ctx, true);
                  if (onConfirm != null) onConfirm();
                },
                child: Text(
                  confirmLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? CupertinoColors.destructiveRed : accent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Frosted liquid glass alert/info dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'OK',
    VoidCallback? onDismiss,
  }) {
    HapticFeedback.lightImpact();
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentPurple;

    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CupertinoAlertDialog(
            title: title.isNotEmpty
                ? Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  )
                : null,
            content: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF636366),
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (onDismiss != null) onDismiss();
                },
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
