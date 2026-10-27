import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

const String _themePrefKey = 'selected_app_theme_mode';
const String _accentColorPrefKey = 'selected_accent_color';

class ThemeState {
  final ThemeMode mode;
  final Color accentColor;

  ThemeState({required this.mode, required this.accentColor});

  ThemeState copyWith({ThemeMode? mode, Color? accentColor}) {
    return ThemeState(
      mode: mode ?? this.mode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeStateNotifier extends StateNotifier<ThemeState> {
  ThemeStateNotifier()
      : super(ThemeState(
            mode: ThemeMode.dark, accentColor: AppColors.accentWhite)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Mode
      final savedMode = prefs.getString(_themePrefKey);
      ThemeMode mode = ThemeMode.dark;
      if (savedMode == 'light') {
        mode = ThemeMode.light;
      } else {
        mode = ThemeMode.dark;
      }

      state = ThemeState(mode: mode, accentColor: AppColors.accentWhite);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final newMode = mode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(mode: newMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _themePrefKey, newMode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorPrefKey, color.toARGB32());
    } catch (_) {}
  }
}

final themeStateProvider =
    StateNotifierProvider<ThemeStateNotifier, ThemeState>((ref) {
  return ThemeStateNotifier();
});
