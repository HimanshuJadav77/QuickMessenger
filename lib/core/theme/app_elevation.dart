import 'package:flutter/material.dart';
import 'app_shadows.dart';

/// Centralized elevation/shadow tokens for QuickMessenger.
/// Wraps AppShadows with semantic names.
class AppElevation {
  AppElevation._();

  static List<BoxShadow> level0(bool isDark) => [];

  static List<BoxShadow> level1(bool isDark) => AppShadows.cardShadow(isDark);

  static List<BoxShadow> level2(bool isDark) => AppShadows.glassShadow(isDark);

  static List<BoxShadow> level3(bool isDark) => AppShadows.navBarShadow(isDark);

  static List<BoxShadow> button(bool isDark, Color accent) => AppShadows.buttonShadow(accent);

  // ── Semantic aliases ──────────────────────────────────────────────
  static List<BoxShadow> none(bool isDark) => level0(isDark);
  static List<BoxShadow> card(bool isDark) => level1(isDark);
  static List<BoxShadow> glass(bool isDark) => level2(isDark);
  static List<BoxShadow> navBar(bool isDark) => level3(isDark);
  static List<BoxShadow> floatingButton(bool isDark, Color accent) => button(isDark, accent);
  static List<BoxShadow> modal(bool isDark) => AppShadows.modalShadow(isDark);
  static List<BoxShadow> sheet(bool isDark) => AppShadows.sheetShadow(isDark);
  static List<BoxShadow> dropdown(bool isDark) => AppShadows.dropdownShadow(isDark);
  static List<BoxShadow> fab(bool isDark) => AppShadows.fabShadow(isDark);
  static List<BoxShadow> tooltip(bool isDark) => AppShadows.tooltipShadow(isDark);
}
