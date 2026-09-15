import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_container.dart';

class GlassTile extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool enableHapticFeedback;

  const GlassTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding,
    this.enableHapticFeedback = true,
  });

  @override
  State<GlassTile> createState() => _GlassTileState();
}

class _GlassTileState extends State<GlassTile> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
      if (widget.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = false);
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: AppMotion.pressDuration,
      curve: AppMotion.pressCurve,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: LiquidGlassContainer(
          level: 1,
          accentTint: _isPressed ? (isDark ? Colors.white : Colors.black) : null,
          margin: widget.margin ?? EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              widget.leading,
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.title,
                    if (widget.subtitle != null) ...[
                      SizedBox(height: AppSpacing.xs),
                      widget.subtitle!,
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                SizedBox(width: AppSpacing.md),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool enableHapticFeedback;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.enableHapticFeedback = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      if (widget.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: AppMotion.pressDuration,
      curve: AppMotion.pressCurve,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: LiquidGlassContainer(
          level: 1,
          accentTint: _isPressed 
              ? (isDark ? Colors.white : Colors.black) 
              : widget.backgroundColor,
          margin: widget.margin,
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          customRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
