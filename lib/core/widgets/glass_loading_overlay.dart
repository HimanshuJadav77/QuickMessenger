import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Full-screen glass loading overlay with backdrop blur.
class GlassLoadingOverlay extends StatelessWidget {
  final String message;
  final bool isLoading;
  final Widget child;

  const GlassLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = "Loading...",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.glassFill(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.glassBorder(isDark),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              message,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary(isDark),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}



