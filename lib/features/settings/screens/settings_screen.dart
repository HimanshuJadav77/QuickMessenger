// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode, Brightness, Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/theme/theme_provider.dart';
import 'package:quick_messenger/core/widgets/app_screen_header.dart';
import 'package:quick_messenger/core/widgets/app_switch.dart';
import 'package:quick_messenger/core/widgets/glass_dialog.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/core/services/auth_service.dart';
import 'package:quick_messenger/core/services/drive_service.dart';
import 'package:quick_messenger/core/services/media_cache_service.dart';
import 'package:quick_messenger/features/settings/screens/blocked_users_screen.dart';
import 'package:quick_messenger/features/settings/screens/about_screen.dart';
import 'package:quick_messenger/features/auth/screens/auth_gate_screen.dart';
import 'package:quick_messenger/features/profile/screens/profile_screen.dart';

/// WhatsApp iOS "You" / Settings Screen.
///
/// Features:
/// - Top action row with Large Bold Title: "You"
/// - Profile Hero card with live [UserAvatar], username, bio, and quick edit
/// - Clean [CupertinoListTile] items with [CupertinoSwitch] for Dark Mode & Privacy
/// - Blocked users, About, and Log Out with Liquid Glass dialogs
/// - Bottom clearance for floating navigation dock
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(currentUserIdProvider);
    final accent = AppColors.textPrimary(isDark);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(isDark),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Top Header Row ──
            AppScreenHeader(
              title: 'You',
              actions: [
                AppHeaderIconButton(
                  icon: CupertinoIcons.pencil,
                  isPrimary: true,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const MyProfile()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Profile Hero Card ──
            Builder(
              builder: (context) {
                final authUser = FirebaseAuth.instance.currentUser;
                final fallbackUid = authUser?.uid ?? '';
                final effectiveUserId = currentUserId.isNotEmpty ? currentUserId : fallbackUid;
                final fallbackName = (authUser?.displayName?.isNotEmpty == true)
                    ? authUser!.displayName!
                    : 'You';
                final fallbackPhoto = authUser?.photoURL ?? '';

                Widget buildCard(String username, String userImage, String about) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const MyProfile()),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xB31C1C1E)
                            : const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.75,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.22 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            username: username,
                            seed: effectiveUserId,
                            imageUrl: userImage,
                            radius: AppAvatarSize.settingsHero,
                            showOnlineBadge: true,
                            isOnline: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDark),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  about,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 18,
                            color: AppColors.textMuted(isDark),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (effectiveUserId.isEmpty) {
                  return buildCard(fallbackName, fallbackPhoto, 'Available');
                }

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("Users")
                      .doc(effectiveUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() ?? {};
                    final rawUsername = (data["username"] ?? '').toString();
                    final username = rawUsername.isNotEmpty ? rawUsername : fallbackName;
                    final rawUserImage = (data["userimageurl"] ?? data["imageurl"] ?? '').toString();
                    final userImage = rawUserImage.isNotEmpty ? rawUserImage : fallbackPhoto;
                    final about = (data["about"] ?? 'Available').toString();

                    return buildCard(username, userImage, about);
                  },
                );
              },
            ),

            const SizedBox(height: 8),

            // ── Appearance Section (CupertinoSwitch) ──
            CupertinoListSection.insetGrouped(
              margin:
                  EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              backgroundColor: AppColors.background(isDark),
              header: const Text('Appearance'),
              children: [
                CupertinoListTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDark
                          ? CupertinoIcons.moon_fill
                          : CupertinoIcons.sun_max_fill,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  title: const Text('Dark Mode'),
                  trailing: AppSwitch(
                    value: isDark,
                    onChanged: (enabled) {
                      ref.read(themeStateProvider.notifier).setThemeMode(
                            enabled ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ),
              ],
            ),

            // ── Privacy Visibility Section (CupertinoSwitch) ──
            if (currentUserId.isNotEmpty)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(currentUserId)
                    .collection("privacy")
                    .doc("mode")
                    .snapshots(),
                builder: (context, snapshot) {
                  final privacy = snapshot.data?.data()?["privacy"] ?? 'public';
                  final isPrivate = privacy == 'private';

                  return CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 6),
                    backgroundColor: AppColors.background(isDark),
                    header: const Text('Privacy'),
                    children: [
                      CupertinoListTile(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer(isDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            CupertinoIcons.lock_shield_fill,
                            color: accent,
                            size: 22,
                          ),
                        ),
                        title: const Text('Private Account'),
                        subtitle: Text(
                          isPrivate
                              ? 'Only approved followers can see details'
                              : 'Anyone can view your profile',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        trailing: AppSwitch(
                          value: isPrivate,
                          onChanged: (val) {
                            final newMode = val ? 'private' : 'public';
                            _showPrivacyConfirmation(
                                context, newMode, currentUserId);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

            // ── Google Drive & Storage Section ──
            _StorageSection(isDark: isDark, accent: accent),

            // ── Safety & About Section ──
            CupertinoListSection.insetGrouped(
              margin:
                  EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              backgroundColor: AppColors.background(isDark),
              header: const Text('Safety & About'),
              children: [
                CupertinoListTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_badge_minus,
                      color: CupertinoColors.systemRed,
                      size: 22,
                    ),
                  ),
                  title: const Text('Blocked Users'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (_) => const BlockedUsersScreen()),
                    );
                  },
                ),
                CupertinoListTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.info_circle_fill,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  title: const Text('About'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),

            // ── Account / Danger Zone ──
            CupertinoListSection.insetGrouped(
              margin:
                  EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              backgroundColor: AppColors.background(isDark),
              header: const Text('Account'),
              children: [
                CupertinoListTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.square_arrow_right,
                      color: CupertinoColors.systemRed,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 110), // clearance for floating bottom bar
          ],
        ),
      ),
    );
  }

  void _showPrivacyConfirmation(
    BuildContext context,
    String value,
    String currentUserId,
  ) {
    final modeText = value == 'public' ? 'Public' : 'Private';
    GlassDialog.showConfirmation(
      context: context,
      title: 'Profile Visibility',
      message:
          'Are you sure you want to set your profile visibility to $modeText?',
      confirmLabel: 'Set to $modeText',
      onConfirm: () async {
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUserId)
            .collection("privacy")
            .doc("mode")
            .set({"privacy": value});
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    GlassDialog.showConfirmation(
      context: context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      isDestructive: true,
      onConfirm: () async {
        await AuthService.instance.signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (_) => const LogReg()),
            (_) => false,
          );
        }
      },
    );
  }
}

/// Google Drive media usage and local offline cache management section.
class _StorageSection extends StatefulWidget {
  final bool isDark;
  final Color accent;

  const _StorageSection({required this.isDark, required this.accent});

  @override
  State<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends State<_StorageSection> {
  int _driveBytes = 0;
  int _driveFiles = 0;
  int _localCacheBytes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loading = true);
    try {
      final driveUsage = await DriveService.instance.getStorageUsage();
      final localBytes = await MediaCacheService.instance.getCacheSize();
      if (mounted) {
        setState(() {
          _driveBytes = driveUsage['totalBytes'] as int? ?? 0;
          _driveFiles = driveUsage['fileCount'] as int? ?? 0;
          _localCacheBytes = localBytes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _clearLocalCache() {
    GlassDialog.showConfirmation(
      context: context,
      title: 'Clear Local Cache',
      message:
          'This will remove downloaded media files from your device storage. They can be re-downloaded from Google Drive at any time.',
      confirmLabel: 'Clear Cache',
      isDestructive: true,
      onConfirm: () async {
        await MediaCacheService.instance.clearCache();
        _loadMetrics();
      },
    );
  }

  void _deleteAllDriveMedia() {
    GlassDialog.showConfirmation(
      context: context,
      title: 'Delete Drive Media',
      message:
          'Are you sure you want to delete all files stored in your QuickMessenger Google Drive folder? This action cannot be undone.',
      confirmLabel: 'Delete All',
      isDestructive: true,
      onConfirm: () async {
        await DriveService.instance.deleteAllAppMedia();
        _loadMetrics();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      backgroundColor: AppColors.background(widget.isDark),
      header: const Text('Google Drive & Storage'),
      children: [
        CupertinoListTile(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer(isDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.cloud_fill,
              color: accent,
              size: 22,
            ),
          ),
          title: const Text('Google Drive Media'),
          subtitle: Text(
            _loading
                ? 'Calculating usage...'
                : '$_driveFiles files • ${_formatBytes(_driveBytes)}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(widget.isDark),
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loading ? null : _loadMetrics,
            child: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
          ),
        ),
        CupertinoListTile(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer(isDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.device_phone_portrait,
              color: accent,
              size: 22,
            ),
          ),
          title: const Text('Offline Local Cache'),
          subtitle: Text(
            _loading ? 'Calculating...' : _formatBytes(_localCacheBytes),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(widget.isDark),
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _localCacheBytes > 0 ? _clearLocalCache : null,
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 13,
                color: _localCacheBytes > 0
                    ? CupertinoColors.systemRed
                    : AppColors.textMuted(widget.isDark),
              ),
            ),
          ),
        ),
        CupertinoListTile(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.trash,
              color: CupertinoColors.systemRed,
              size: 22,
            ),
          ),
          title: const Text(
            'Delete All Drive Media',
            style: TextStyle(color: CupertinoColors.systemRed),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: _deleteAllDriveMedia,
        ),
      ],
    );
  }
}
