import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';

/// Standardized iOS Liquid Glass App Header for top-level tab screens.
///
/// Ensures:
/// - Screen title and action buttons sit on the EXACT SAME horizontal row.
/// - Centered vertically on the exact same baseline.
/// - Title is left-aligned with graceful truncation (no overlap).
/// - Action buttons are grouped neatly on the right with standard 38x38 touch targets.
class AppScreenHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const AppScreenHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions[i],
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Standardized circular action button for AppScreenHeader.
/// Adheres to 38x38 dimensions and consistent touch targets.
class AppHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const AppHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.backgroundColor,
    this.iconColor,
    this.size = 38.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    final bg = backgroundColor ??
        (isPrimary
            ? accent
            : (isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E5EA)));

    final fg = iconColor ??
        (isPrimary
            ? AppColors.onPrimary(isDark, bg)
            : AppColors.textPrimary(isDark));

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size(size, size),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: bg.withValues(alpha: isDark ? 0.35 : 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: fg,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
