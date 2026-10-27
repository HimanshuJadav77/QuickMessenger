import 'package:flutter/cupertino.dart';
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
    this.icon = CupertinoIcons.chat_bubble_2,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return Padding(
      padding: AppSpacing.paddingLg,
      child: Center(
        child: LiquidGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          customRadius: BorderRadius.circular(24),
          level: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: AppColors.textMuted(isDark)),
              AppSpacing.gapMd,
              Text(
                title,
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.textPrimary(isDark),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                AppSpacing.gapSm,
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary(isDark),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onActionPressed != null && actionLabel != null) ...[
                AppSpacing.gapLg,
                CupertinoButton(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onPressed: onActionPressed,
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: AppColors.onPrimary(isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
