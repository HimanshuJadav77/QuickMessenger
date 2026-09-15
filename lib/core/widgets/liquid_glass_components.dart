import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'liquid_glass_container.dart';

export 'liquid_glass_app_bar.dart';
export 'liquid_glass_navigation_bar.dart';
export 'liquid_glass_container.dart';
export 'glass_card.dart';
export 'glass_button.dart';
export 'lg_context_menu.dart';

typedef LGPanel = LiquidGlassContainer;

/// Liquid Glass Circular Icon Button.
class LGIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final Color? iconColor;
  final String? tooltip;

  const LGIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 38.0,
    this.color,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.52,
            color: iconColor ?? accent,
          ),
        ),
      ),
    );
  }
}

/// WhatsApp iOS Liquid Glass Search Field with AI halo option.
class LGSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onAiTap;
  final bool showAiRing;

  const LGSearchField({
    super.key,
    required this.controller,
    this.placeholder = 'Ask Meta AI or Search',
    this.onChanged,
    this.onClear,
    this.onAiTap,
    this.showAiRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark ? const Color(0xCC1E1E22) : const Color(0xE6EEEEF2),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.search,
            size: 18,
            color: AppColors.textMuted(isDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted(isDark),
                fontFamily: '.SF Pro Text',
              ),
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary(isDark),
                fontFamily: '.SF Pro Text',
              ),
              decoration: null,
              padding: EdgeInsets.zero,
              onChanged: onChanged,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onClear?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 18,
                  color: AppColors.textMuted(isDark),
                ),
              ),
            )
          else if (showAiRing)
            GestureDetector(
              onTap: onAiTap,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFF007AFF),
                      Color(0xFF3B82F6),
                      Color(0xFF10B981),
                      Color(0xFFF59E0B),
                      Color(0xFFEC4899),
                      Color(0xFF007AFF),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFEEEEF2),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
