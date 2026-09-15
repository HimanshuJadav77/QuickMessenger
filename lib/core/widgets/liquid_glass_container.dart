import 'package:flutter/material.dart';
import '../theme/liquid_glass_tokens.dart';

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final int level;
  final Color? accentTint;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? customRadius;
  final BoxShape shape;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.level = 1,
    this.accentTint,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.customRadius,
    this.shape = BoxShape.rectangle,
  });

  BorderRadius? _getRadius() {
    if (shape == BoxShape.circle) return null;
    if (customRadius != null) return customRadius;
    switch (level) {
      case 1:
        return LiquidGlassTokens.radiusLevel1;
      case 2:
        return LiquidGlassTokens.radiusLevel2;
      case 3:
        return LiquidGlassTokens.radiusLevel3;
      case 4:
        return LiquidGlassTokens.radiusLevel4;
      default:
        return LiquidGlassTokens.radiusLevel1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (level == 0) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = _getRadius();

    Color fillColor = LiquidGlassTokens.getFillColor(level, isDark);
    if (accentTint != null) {
      fillColor = Color.alphaBlend(accentTint!.withValues(alpha: 0.1), fillColor);
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: radius,
        boxShadow: LiquidGlassTokens.getShadow(level, isDark),
      ),
      child: ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: LiquidGlassTokens.getFilter(level),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: radius,
              color: fillColor,
              border: Border.all(
                color: LiquidGlassTokens.getBorderColor(level, isDark),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LiquidGlassTokens.getHighlightColor(level, isDark),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

