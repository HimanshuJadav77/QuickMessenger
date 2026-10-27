import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
typedef LGBottomBar = LiquidGlassNavigationBar;

class LiquidGlassNavigationBar extends StatefulWidget {
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
  State<LiquidGlassNavigationBar> createState() =>
      _LiquidGlassNavigationBarState();
}

class _LiquidGlassNavigationBarState extends State<LiquidGlassNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _fromIndex = 0;
  int _targetIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _targetIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant LiquidGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _fromIndex = oldWidget.currentIndex;
      _targetIndex = widget.currentIndex;
      final distance = (_targetIndex - _fromIndex).abs();
      // Distance-proportioned duration: rapid for adjacent, elegant for distant transitions
      final ms = 220 + (distance * 30);
      _controller.duration = Duration(milliseconds: ms);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = AppColors.isDarkMode(context);
    final accent = widget.accentColor ?? (isDark ? Colors.white : Colors.black);

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
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              color: isDark ? const Color(0xB3141416) : const Color(0xD9FFFFFF),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.10),
                width: 0.75,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.50),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / widget.items.length;
                return Stack(
                  children: [
                    // Fluid Liquid Glass sliding pill indicator with organic stretch
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        final t = _animation.value;
                        final fromCenter =
                            (tabWidth * _fromIndex) + (tabWidth / 2);
                        final targetCenter =
                            (tabWidth * _targetIndex) + (tabWidth / 2);
                        final distance = (_targetIndex - _fromIndex).abs();

                        // Gentle fluid stretch in flight: peaks halfway through the transit
                        final stretchAmount = (distance * 4.0).clamp(0.0, 16.0);
                        final stretch = math.sin(t * math.pi) * stretchAmount;

                        final currentCenter =
                            fromCenter + (targetCenter - fromCenter) * t;
                        final currentWidth = (tabWidth - 4) + stretch;
                        final currentLeft = currentCenter - (currentWidth / 2);

                        return Positioned(
                          left: currentLeft,
                          top: 4,
                          bottom: 4,
                          width: currentWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.black.withValues(alpha: 0.08),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.20),
                                width: 0.75,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(widget.items.length, (index) {
                        final item = widget.items[index];
                        final isSelected = widget.currentIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onTap(index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      item.customWidget != null
                                          ? IgnorePointer(
                                              child: item.customWidget!)
                                          : AnimatedScale(
                                              scale: isSelected ? 1.05 : 1.0,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              curve: Curves.easeOutCubic,
                                              child: Icon(
                                                isSelected
                                                    ? item.activeIcon
                                                    : item.icon,
                                                key: ValueKey<bool>(isSelected),
                                                color: isSelected
                                                    ? accent
                                                    : AppColors.textSecondary(
                                                        isDark),
                                                size: 24,
                                              ),
                                            ),
                                      if (item.badgeCount != null &&
                                          item.badgeCount! > 0)
                                        Positioned(
                                          top: -3,
                                          right: -10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.black
                                                    : Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Center(
                                              child: Text(
                                                item.badgeCount! > 99
                                                    ? '99+'
                                                    : '${item.badgeCount}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.black
                                                      : Colors.white,
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
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    style: AppTypography.caption.copyWith(
                                      color: isSelected
                                          ? accent
                                          : AppColors.textSecondary(isDark),
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
