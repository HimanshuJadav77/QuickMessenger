import 'package:flutter/material.dart';

/// Centralized color tokens for the entire QuickMessenger application.
/// All screens MUST use these tokens instead of raw Colors.* values.
class AppColors {
  AppColors._();

  // ── Brand: Single Signature Accent iOS Sapphire Blue ─────────────
  static const Color accentBlue = Color(0xFF007AFF); // Signature iOS Sapphire Blue
  static const Color accentPurple = accentBlue; // Alias for seamless compatibility
  static const Color primary = accentBlue;
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color primaryLight = Color(0xFF4DA3FF);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // ── Status indicators ────────────────────────────────────────────
  static const Color onlineIndicator = Color(0xFF22C55E);
  static const Color offlineIndicator = Color(0xFF94A3B8);

  // ── Message bubbles ──────────────────────────────────────────────
  static const Color senderBubble = accentPurple;
  static const Color senderText = Color(0xFFFFFFFF);

  // ── Light theme tokens ───────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightReceiverBubble = Color(0xFFE2E8F0);
  static const Color lightReceiverText = Color(0xFF0F172A);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFCBD5E1);

  // ── Dark OLED theme tokens ───────────────────────────────────────
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkReceiverBubble = Color(0xFF1E293B);
  static const Color darkReceiverText = Color(0xFFE2E8F0);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);

  // ── Adaptive helpers (pass isDark from Theme.of(context).brightness) ──

  static Color background(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color surface(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  static Color surfaceVariant(bool isDark) =>
      isDark ? darkSurfaceVariant : lightSurfaceVariant;

  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(bool isDark) =>
      isDark ? darkTextMuted : lightTextMuted;

  static Color receiverBubble(bool isDark) =>
      isDark ? darkReceiverBubble : lightReceiverBubble;

  static Color receiverText(bool isDark) =>
      isDark ? darkReceiverText : lightReceiverText;

  static Color border(bool isDark) =>
      isDark ? darkBorder : lightBorder;

  static Color divider(bool isDark) =>
      isDark ? darkDivider : lightDivider;

  // ── Glassmorphism tokens ─────────────────────────────────────────
  static Color glassBorder(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08);

  static Color glassFill(bool isDark) =>
      isDark ? Colors.black.withValues(alpha: 0.70) : Colors.white.withValues(alpha: 0.80);

  static Color glassFillSubtle(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.25);

  static Color glassHighlight(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.40);

  // ── Semantic Color Aliases (for consistent theming) ──────────────
  /// Primary action color - derives from user's accent selection
  static Color primaryAction(Color accent) => accent;

  /// Text/icon on primary action surfaces
  static const Color onPrimaryAction = Colors.white;

  /// Secondary action color - subtle variant of accent
  static Color secondaryAction(Color accent, bool isDark) =>
      accent.withValues(alpha: isDark ? 0.15 : 0.12);

  /// Text/icon on secondary action surfaces
  static Color onSecondaryAction(Color accent, bool isDark) =>
      isDark ? accent.withValues(alpha: 0.9) : accent;

  /// Surface container for cards, tiles, inputs
  static Color surfaceContainer(bool isDark) =>
      isDark ? darkSurfaceVariant : lightSurfaceVariant;

  /// Surface container highest for modals, sheets
  static Color surfaceContainerHighest(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  /// Outline color for borders, dividers
  static Color outline(bool isDark) =>
      isDark ? darkBorder : lightBorder;

  /// Outline variant for subtle borders
  static Color outlineVariant(bool isDark) =>
      isDark ? darkDivider : lightDivider;

  /// Inverse surface for modals over dark content
  static Color inverseSurface(bool isDark) =>
      isDark ? lightSurface : darkSurface;

  /// Inverse primary for text on inverse surfaces
  static Color inversePrimary(Color accent, bool isDark) =>
      isDark ? accent : accent;

  // ── Interactive State Colors ─────────────────────────────────────
  /// Hover/pressed state for buttons, tiles
  static Color hover(Color accent, bool isDark) =>
      accent.withValues(alpha: isDark ? 0.12 : 0.08);

  /// Pressed state for buttons, tiles
  static Color pressed(Color accent, bool isDark) =>
      accent.withValues(alpha: isDark ? 0.18 : 0.12);

  /// Focus ring color
  static Color focus(Color accent) => accent;

  /// Disabled state color
  static Color disabled(bool isDark) =>
      isDark ? darkTextMuted : lightTextMuted;

  // ── Branded gradient ─────────────────────────────────────────────
  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A8A),
      Color(0xFF3B82F6),
      Color(0xFF0F172A),
    ],
  );
}

