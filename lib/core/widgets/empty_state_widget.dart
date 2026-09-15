import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_container.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.chat_bubble_outline_rounded,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Center(
        child: LiquidGlassContainer(
          padding: const EdgeInsets.all(28.0),
          customRadius: BorderRadius.circular(24),
          level: 1,
          
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.textMuted(isDark)),
              AppSpacing.gapMd,
              Text(title, style: AppTypography.headingMedium, textAlign: TextAlign.center),
              if (subtitle != null) ...[
                AppSpacing.gapSm,
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary(isDark)),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onActionPressed != null && actionLabel != null) ...[
                AppSpacing.gapLg,
                ElevatedButton(
                  onPressed: onActionPressed,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


