import 'package:flutter/cupertino.dart';

/// Standardized theme-aware switch widget for QuickMessenger.
/// Ensures high-contrast track and thumb visibility against dark surfaces and light cards.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? trackColor;
  final Color? thumbColor;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.trackColor,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = activeColor ?? CupertinoTheme.of(context).primaryColor;

    final effectiveThumbColor = thumbColor ??
        (value && accent.computeLuminance() > 0.65
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFFFFFFF));

    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: accent,
      inactiveTrackColor: trackColor ??
          (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA)),
      thumbColor: effectiveThumbColor,
    );
  }
}
