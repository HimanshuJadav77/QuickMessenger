import 'package:flutter/material.dart';
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
              const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
              AppSpacing.gapMd,
              Text('Something went wrong', style: AppTypography.headingMedium),
              AppSpacing.gapSm,
              Text(
                errorMessage,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary(isDark)),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                AppSpacing.gapLg,
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


