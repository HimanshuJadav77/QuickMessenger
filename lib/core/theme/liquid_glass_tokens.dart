import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized tokens for the Liquid Glass design system.
/// This defines the visual hierarchy (Levels 0-4) and adaptive tints.
class LiquidGlassTokens {
  LiquidGlassTokens._();

  // --- Animation ---
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeOutCubic;

  // --- Corner Radius ---
  static const BorderRadius radiusLevel1 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLevel2 = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusLevel3 = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusLevel4 = BorderRadius.all(Radius.circular(32));

  // --- Blur Logic ---
  // Avoid excessive blur.
  static double getBlur(int level) {
    switch (level) {
      case 0: return 0.0;
      case 1: return 12.0; // Subtle glass
      case 2: return 20.0; // AppBar / Navigation
      case 3: return 24.0; // Popup / Action Sheet
      case 4: return 32.0; // Dialog / Modal
      default: return 0.0;
    }
  }

  static ImageFilter getFilter(int level) {
    final blur = getBlur(level);
    return ImageFilter.blur(sigmaX: blur, sigmaY: blur);
  }

  // --- Adaptive Tints ---
  // Light Theme: subtle dark/black translucent glass + white highlight
  // Dark Theme (OLED): subtle white translucent glass + white highlight

  static Color getFillColor(int level, bool isDark) {
    if (level == 0) return Colors.transparent;
    
    if (isDark) {
      // OLED Dark theme: Translucent white glass
      switch (level) {
        case 1: return Colors.white.withValues(alpha: 0.04);
        case 2: return Colors.white.withValues(alpha: 0.06);
        case 3: return Colors.white.withValues(alpha: 0.08);
        case 4: return Colors.white.withValues(alpha: 0.10);
        default: return Colors.transparent;
      }
    } else {
      // Light theme: Translucent dark glass
      switch (level) {
        case 1: return Colors.black.withValues(alpha: 0.02);
        case 2: return Colors.black.withValues(alpha: 0.04);
        case 3: return Colors.black.withValues(alpha: 0.06);
        case 4: return Colors.black.withValues(alpha: 0.08);
        default: return Colors.transparent;
      }
    }
  }

  static Color getBorderColor(int level, bool isDark) {
    if (level == 0) return Colors.transparent;

    // Both themes get a subtle white/light border for that glass edge specular reflection
    if (isDark) {
      return Colors.white.withValues(alpha: 0.10 + (level * 0.02));
    } else {
      return Colors.black.withValues(alpha: 0.05 + (level * 0.02));
    }
  }

  static Color getHighlightColor(int level, bool isDark) {
    if (level == 0) return Colors.transparent;
    // Inner highlight is always white for the specular glass effect
    return Colors.white.withValues(alpha: isDark ? 0.08 : 0.40);
  }

  static List<BoxShadow> getShadow(int level, bool isDark) {
    if (level == 0) return [];

    final opacity = isDark ? 0.40 : 0.10;
    
    switch (level) {
      case 1:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: opacity * 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: opacity),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: opacity * 1.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: opacity * 2.0),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ];
      default:
        return [];
    }
  }
}

