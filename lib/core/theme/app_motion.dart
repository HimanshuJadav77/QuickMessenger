import 'package:flutter/material.dart';

/// Centralized motion/animation tokens for QuickMessenger.
/// All animations MUST use these tokens instead of raw durations/curves.
class AppMotion {
  AppMotion._();

  // ── Durations ──────────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration moderate = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration typingIndicator = Duration(milliseconds: 1200);

  // ── Micro-interaction Durations ───────────────────────────────────
  static const Duration microFast = Duration(milliseconds: 50);
  static const Duration microStandard = Duration(milliseconds: 100);
  static const Duration microModerate = Duration(milliseconds: 200);
  static const Duration microSlow = Duration(milliseconds: 300);

  // ── Curves ─────────────────────────────────────────────────────────
  static const Curve linear = Curves.linear;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve easeOutQuart = Curves.easeOutQuart;
  static const Curve spring = Curves.elasticOut;
  static const Curve easeOutExpo = Curves.easeOutExpo;

  // ── Presets ────────────────────────────────────────────────────────
  static const Duration pressDuration = fast;
  static const Curve pressCurve = easeOutCubic;

  static const Duration tapDuration = standard;
  static const Curve tapCurve = easeOutCubic;

  static const Duration navigationDuration = moderate;
  static const Curve navigationCurve = easeOutQuart;

  static const Duration entranceDuration = moderate;
  static const Curve entranceCurve = easeOutBack;

  static const Duration modalDuration = standard;
  static const Curve modalCurve = easeOutCubic;

  static const Duration typingDuration = typingIndicator;
  static const Curve typingCurve = linear;

  // ── Micro-interaction Presets ──────────────────────────────────────
  static const Duration messageEntranceDuration = microStandard;
  static const Curve messageEntranceCurve = easeOutBack;

  static const Duration reactionAnimationDuration = microStandard;
  static const Curve reactionAnimationCurve = spring;

  static const Duration pressFeedbackDuration = microFast;
  static const Curve pressFeedbackCurve = easeOutExpo;

  static const Duration hapticLightDuration = Duration(milliseconds: 10);
  static const Duration hapticMediumDuration = Duration(milliseconds: 20);
  static const Duration hapticHeavyDuration = Duration(milliseconds: 40);

  static const Duration messageDeleteDuration = microModerate;
  static const Curve messageDeleteCurve = easeOutQuart;

  static const Duration typingIndicatorPulseDuration = Duration(milliseconds: 600);
  static const Curve typingIndicatorPulseCurve = easeInOut;
}
