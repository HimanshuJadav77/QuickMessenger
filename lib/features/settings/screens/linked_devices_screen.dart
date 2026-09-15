import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// iOS-native linked devices.
class LinkedDevicesScreen extends StatelessWidget {
  const LinkedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Linked Devices'),
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
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .doc(currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CupertinoActivityIndicator());
            }

            final data = snapshot.data?.data() ?? {};
            final rawTokens = data['fcmToken'];
            final tokenCount = rawTokens is List ? rawTokens.length : 1;

            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                  child: Text(
                    'ACTIVE SESSIONS'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted(isDark),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.background(isDark),
                  margin: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  children: [
                    CupertinoListTile(
                      leading: Icon(
                          CupertinoIcons.device_phone_portrait,
                          color: accent),
                      title: const Text('This device'),
                      subtitle: const Text(
                          'Active now • QuickMessenger'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                CupertinoColors.systemGreen,
                          ),
                        ),
                      ),
                    ),
                    if (tokenCount > 1)
                      CupertinoListTile(
                        leading: Icon(
                            CupertinoIcons.device_phone_portrait,
                            color: accent),
                        title: Text(
                            '$tokenCount registered devices'),
                        subtitle: const Text(
                            'Push notifications enabled'),
                        trailing: Icon(
                            CupertinoIcons.checkmark_circle,
                            color: accent),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Sessions are created automatically when you sign in on a device. Signing out removes the session.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted(isDark),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
