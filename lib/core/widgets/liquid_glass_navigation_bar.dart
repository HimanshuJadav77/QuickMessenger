import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, Colors;
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/liquid_glass_tokens.dart';

class LiquidGlassNavigationBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
  final Widget? customWidget;

  const LiquidGlassNavigationBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
    this.customWidget,
  });
}

/// WhatsApp-style floating Liquid Glass navigation dock (LGBottomBar).
///
/// Features:
/// - Floating capsule dock with real-time [BackdropFilter] blur (sigma 24)
/// - Active tab glowing pill capsule indicator
/// - Unread badge support on tab icons
/// - Specular glass highlight reflection and border
typedef LGBottomBar = LiquidGlassNavigationBar;

class LiquidGlassNavigationBar extends StatelessWidget {
  final List<LiquidGlassNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? accentColor;

  const LiquidGlassNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.accentPurple;

    return Container(
      margin: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: bottomPadding > 0 ? bottomPadding + 6 : 18,
      ),
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.12),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(8, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              color: isDark
                  ? const Color(0xB318181A)
                  : const Color(0xB3F6F6F9),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.bounceInOut,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: isSelected
                            ? accent.withValues(alpha: isDark ? 0.08 : 0.05)
                            : Colors.transparent,
                        border: isSelected
                            ? Border.all(
                                color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                                width: 0.5,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              item.customWidget != null
                                  ? IgnorePointer(child: item.customWidget!)
                                  : AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 150),
                                      transitionBuilder: (child, anim) => ScaleTransition(
                                        scale: Tween<double>(begin: 0.30, end: 1.0).animate(anim),
                                        child: child,
                                      ),
                                      child: Icon(
                                        isSelected ? item.activeIcon : item.icon,
                                        key: ValueKey<bool>(isSelected),
                                        color: isSelected
                                            ? accent
                                            : AppColors.textSecondary(isDark),
                                        size: 25,
                                      ),
                                    ),
                              if (item.badgeCount != null && item.badgeCount! > 0)
                                Positioned(
                                  top: -3,
                                  right: -10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark ? Colors.black : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: LiquidGlassTokens.animationDuration,
                            style: AppTypography.caption.copyWith(
                              color: isSelected
                                  ? accent
                                  : AppColors.textSecondary(isDark),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 10.5,
                              height: 1.1,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
