import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_snackbar.dart';

/// iOS-native Blocked Users screen.
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() =>
      _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(currentUserIdProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Blocked Users'),
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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("block")
              .doc(currentUserId)
              .collection("blockedid")
              .where("blocked", isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.person_badge_minus,
                      size: 54,
                      color: AppColors.textMuted(isDark),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'No Blocked Users',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              );
            }

            final blockedDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: blockedDocs.length,
              itemBuilder: (context, index) {
                final blockedUserId = blockedDocs[index].id;

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("Users")
                      .doc(blockedUserId)
                      .snapshots(),
                  builder: (context, uSnapshot) {
                    if (uSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 60,
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    final userData = uSnapshot.data?.data();
                    if (userData == null) {
                      return const SizedBox.shrink();
                    }
                    final username =
                        (userData["username"] ?? 'Unknown').toString();
                    final imageUrl =
                        (userData["userimageurl"] ?? '').toString();

                    return CupertinoListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: imageUrl.isEmpty
                              ? CupertinoTheme.of(context).primaryColor
                              : null,
                          image: imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl.isEmpty
                            ? Center(
                                child: Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        username,
                        style:
                            TextStyle(color: AppColors.textPrimary(isDark)),
                      ),
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _confirmUnblock(
                          context,
                          blockedUserId,
                          username,
                          ref,
                        ),
                        child: Text(
                          'Unblock',
                          style: TextStyle(
                            color: CupertinoTheme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmUnblock(
    BuildContext context,
    String userId,
    String username,
    WidgetRef ref,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $username?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              final currentUserId = ref.read(currentUserIdProvider);
              if (currentUserId.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection("block")
                  .doc(currentUserId)
                  .collection("blockedid")
                  .doc(userId)
                  .set({"blocked": false});

              if (context.mounted) {
                showSnackBar(context, 'Unblocked $username');
              }
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
