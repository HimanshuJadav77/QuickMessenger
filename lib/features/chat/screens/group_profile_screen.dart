import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/glass_action_sheet.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/features/chat/models/group_model.dart';
import 'package:quick_messenger/features/chat/providers/chat_provider.dart';

/// iOS-native group profile, local-first.
///
/// Reads group + members from SQLite via [ChatRepository.getGroupProfile] —
/// works offline and immediately after creation, no server round-trip.
class GroupProfileScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const GroupProfileScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  void _confirmDeleteGroup(BuildContext context, WidgetRef ref, String groupId, String name) {
    LGActionSheet.showConfirmation(
      context: context,
      title: 'Delete "$name"?',
      message: 'This group will be deleted for all members and cannot be undone.',
      confirmTitle: 'Delete Group',
      isDestructive: true,
      onConfirm: () async {
        await ref.read(groupsProvider.notifier).deleteGroup(groupId);
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }

  void _confirmExitGroup(BuildContext context, WidgetRef ref, String groupId, String name) {
    LGActionSheet.showConfirmation(
      context: context,
      title: 'Exit "$name"?',
      message: 'You will no longer be a member of this group.',
      confirmTitle: 'Exit Group',
      isDestructive: true,
      onConfirm: () async {
        await ref.read(groupsProvider.notifier).leaveGroup(groupId);
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final repo = ref.watch(chatRepositoryProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(groupName),
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
        child: FutureBuilder<Map<String, dynamic>?>(
          future: repo.getGroupProfile(groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CupertinoActivityIndicator());
            }

            final profile = snapshot.data;
            final GroupModel? group =
                profile?['group'] as GroupModel?;
            final List members =
                (profile?['members'] as List?) ?? [];
            final desc = (group?.description ?? '').isNotEmpty
                ? group!.description
                : 'No description';
            final memberCount =
                members.isNotEmpty ? members.length : (group?.memberCount ?? 1);
            final isOwner = (group?.createdBy == repo.currentUserId) || (group?.myRole == 'owner');

            return ListView(
              children: [
                SizedBox(height: AppSpacing.md),
                Center(
                  child: UserAvatar(
                    username: group?.name ?? groupName,
                    imageUrl: group?.imageUrl,
                    radius: 46,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    group?.name ?? groupName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$memberCount members',
                    style: TextStyle(
                        color: AppColors.textSecondary(isDark)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color:
                          AppColors.surfaceContainer(isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      desc,
                      style: TextStyle(
                          color:
                              AppColors.textPrimary(isDark)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                  child: Text(
                    'MEMBERS'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted(isDark),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (members.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        group == null
                            ? 'Group not found locally yet.'
                            : 'No member rows cached yet.',
                        style: TextStyle(
                            color:
                                AppColors.textMuted(isDark)),
                      ),
                    ),
                  )
                else
                  CupertinoListSection.insetGrouped(
                    backgroundColor:
                        AppColors.background(isDark),
                    margin: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    children: members.map((m) {
                      final map = Map<String, dynamic>.from(
                          m as Map);
                      final username =
                          (map['username'] ?? map['display_name'] ?? 'Member')
                              .toString();
                      final imageUrl =
                          (map['image_url'] ?? '').toString();
                      final role =
                          (map['role'] ?? 'member').toString();
                      final isMe = (map['uid'] ?? '').toString() ==
                          repo.currentUserId;

                      final Color roleColor = switch (role) {
                        'owner' =>
                          CupertinoColors.systemOrange,
                        'admin' => accent,
                        _ => AppColors.textMuted(isDark),
                      };                      return CupertinoListTile(
                        leading: UserAvatar(
                          username: username,
                          imageUrl: imageUrl,
                          radius: 20,
                        ),
                        title: Text(isMe
                            ? 'You ($username)'
                            : username),
                        trailing: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(
                                alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                // ── Destructive Action Section (Delete or Exit Group) ──
                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.background(isDark),
                  margin: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  children: [
                    if (isOwner)
                      CupertinoListTile(
                        leading: const Icon(
                          CupertinoIcons.trash_fill,
                          color: CupertinoColors.destructiveRed,
                          size: 20,
                        ),
                        title: const Text(
                          'Delete Group',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () => _confirmDeleteGroup(
                          context,
                          ref,
                          groupId,
                          group?.name ?? groupName,
                        ),
                      )
                    else
                      CupertinoListTile(
                        leading: const Icon(
                          CupertinoIcons.square_arrow_right,
                          color: CupertinoColors.destructiveRed,
                          size: 20,
                        ),
                        title: const Text(
                          'Exit Group',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () => _confirmExitGroup(
                          context,
                          ref,
                          groupId,
                          group?.name ?? groupName,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}
