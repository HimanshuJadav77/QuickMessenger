import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// iOS-native about screen.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('About'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.lg),
          children: [
            SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  size: 46,
                  color: accent,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'QuickMessenger',
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'Version 2.4.0 (Build 240)',
                style: TextStyle(color: AppColors.textMuted(isDark)),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            CupertinoListSection.insetGrouped(
              backgroundColor: AppColors.background(isDark),
              margin: EdgeInsets.zero,
              children: [
                _row(context, isDark, CupertinoIcons.shield,
                    'Architecture', 'Local-first, Riverpod state'),
                _row(context, isDark, CupertinoIcons.bolt,
                    'Real-time transport', 'Socket.IO + FCM'),
                _row(context, isDark, CupertinoIcons.archivebox,
                    'Local persistence', 'SQLite, per-user keys'),
                _row(context, isDark, CupertinoIcons.lock,
                    'Authentication', 'Firebase secure token'),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                '© 2026 QuickMessenger Team. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted(isDark),
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static CupertinoListTile _row(BuildContext context, bool isDark,
      IconData icon, String title, String value) {
    return CupertinoListTile(
      leading: Icon(icon,
          color: CupertinoTheme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
