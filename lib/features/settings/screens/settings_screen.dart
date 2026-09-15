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
import 'package:quick_messenger/core/theme/app_typography.dart';
import 'package:quick_messenger/core/theme/theme_provider.dart';
import 'package:quick_messenger/core/widgets/glass_dialog.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
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
    final themeState = ref.watch(themeStateProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(isDark),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Top Header Actions (Matching Chats Page) ──
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // QR Code temporarily commented out as requested
                  /*
                  LGIconButton(
                    icon: CupertinoIcons.qrcode,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const MyProfile()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  */
                  LGIconButton(
                    icon: CupertinoIcons.pencil,
                    color: accent,
                    iconColor: Colors.white,
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
            ),

            // ── Large Title: "You" (34pt Bold) ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              child: Text(
                'You',
                style: AppTypography.displayLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Profile Hero Card ──
            if (currentUserId.isNotEmpty)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? {};
                  final username = (data["username"] ?? 'User').toString();
                  final userImage = (data["userimageurl"] ?? '').toString();
                  final about = (data["about"] ?? 'Available').toString();

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const MyProfile()),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
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
                            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            username: username,
                            imageUrl: userImage,
                            radius: 30,
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
                },
              ),

            const SizedBox(height: 8),

            // ── Appearance Section (CupertinoSwitch) ──
            CupertinoListSection.insetGrouped(
              backgroundColor: AppColors.background(isDark),
              header: const Text('Appearance'),
              children: [
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      themeState.mode == ThemeMode.dark
                          ? CupertinoIcons.moon_fill
                          : CupertinoIcons.sun_max_fill,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  title: const Text('Dark'),
                  trailing: CupertinoSwitch(
                    activeTrackColor: accent,
                    value: themeState.mode == ThemeMode.dark,
                    onChanged: (enabled) {
                      ref.read(themeStateProvider.notifier).setThemeMode(
                            enabled ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ),
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      CupertinoIcons.device_phone_portrait,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  title: const Text('System'),
                  trailing: CupertinoSwitch(
                    activeTrackColor: accent,
                    value: themeState.mode == ThemeMode.system,
                    onChanged: (enabled) {
                      ref.read(themeStateProvider.notifier).setThemeMode(
                            enabled ? ThemeMode.system : (isDark ? ThemeMode.dark : ThemeMode.light),
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
                    backgroundColor: AppColors.background(isDark),
                    header: const Text('Privacy'),
                    children: [
                      CupertinoListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemIndigo.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            CupertinoIcons.lock_shield_fill,
                            color: CupertinoColors.systemIndigo,
                            size: 20,
                          ),
                        ),
                        title: const Text('Private Account'),
                        subtitle: Text(
                          isPrivate ? 'Only approved followers can see details' : 'Anyone can view your profile',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        trailing: CupertinoSwitch(
                          activeTrackColor: accent,
                          value: isPrivate,
                          onChanged: (val) {
                            final newMode = val ? 'private' : 'public';
                            _showPrivacyConfirmation(context, newMode, currentUserId);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

            // ── Safety & About Section ──
            CupertinoListSection.insetGrouped(
              backgroundColor: AppColors.background(isDark),
              header: const Text('Safety & About'),
              children: [
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_badge_minus,
                      color: CupertinoColors.systemRed,
                      size: 20,
                    ),
                  ),
                  title: const Text('Blocked Users'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const BlockedUsersScreen()),
                    );
                  },
                ),
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      CupertinoIcons.info_circle_fill,
                      color: accent,
                      size: 20,
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
              backgroundColor: AppColors.background(isDark),
              header: const Text('Account'),
              children: [
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      CupertinoIcons.square_arrow_right,
                      color: CupertinoColors.systemRed,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: CupertinoColors.systemRed, fontWeight: FontWeight.w600),
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
      message: 'Are you sure you want to set your profile visibility to $modeText?',
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
        final uid = ref.read(currentUserIdProvider);
        if (uid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(uid)
              .update({"online": false});
        }
        await FirebaseAuth.instance.signOut();
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