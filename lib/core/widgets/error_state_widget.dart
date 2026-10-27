import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_container.dart';

class ErrorStateWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
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
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 56,
                color: AppColors.error,
              ),
              AppSpacing.gapMd,
              Text(
                'Something went wrong',
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.textPrimary(isDark),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapSm,
              Text(
                errorMessage,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary(isDark),
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                AppSpacing.gapLg,
                CupertinoButton(
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onPressed: onRetry,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.refresh,
                        size: 16,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Try Again',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
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
