import 'package:flutter/material.dart';

/// Centralized typography tokens for QuickMessenger.
/// Text styles define ONLY structure (size, weight, height, spacing).
/// Colors are applied at the call site via Theme or AppColors for theme awareness.
class AppTypography {
  AppTypography._();

  // ── Display Large ────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ── Display / Large Title ────────────────────────────────────────
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ── Heading Large ────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  // ── Heading Medium ───────────────────────────────────────────────
  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ── Title ────────────────────────────────────────────────────────
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ── Body Large ───────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // ── Body Medium (default body text) ──────────────────────────────
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // ── Body Small ───────────────────────────────────────────────────
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // ── Caption ──────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // ── Navigation Label ─────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

