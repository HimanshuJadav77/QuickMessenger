import 'package:flutter/material.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_container.dart';

/// A card component with glassmorphism, adaptive to dark/light theme.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
        return GestureDetector(onTap: onTap, child: LiquidGlassContainer(
      padding: padding ?? const EdgeInsets.all(16.0),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      customRadius: borderRadius ?? BorderRadius.circular(12),
      
      level: 1,
      
      
      child: child,
    ));
  }
}




