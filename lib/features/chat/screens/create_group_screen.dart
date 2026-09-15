import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_snackbar.dart';
import '../providers/chat_provider.dart';

/// iOS-native group creation.
///
/// Name + description in a [CupertinoListSection], member multi-select with
/// checkmarks, creates via [GroupsNotifier] (SQLite + socket) so the group
/// appears in the chat list immediately.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() =>
      _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<Map<String, dynamic>> _selectedMembers = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnackBar(context, 'Please enter a group name.');
      return;
    }
    if (_selectedMembers.isEmpty) {
      showSnackBar(context, 'Please select at least one member.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final groupId = 'group_${const Uuid().v4()}';
      await ref.read(groupsProvider.notifier).createGroup(
            groupId: groupId,
            name: name,
            description: _descController.text.trim(),
            imageUrl: '',
            members: _selectedMembers,
          );
      if (mounted) {
        showSnackBar(context, 'Group "$name" created.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Failed to create group: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('New Group'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        trailing: _isCreating
            ? const CupertinoActivityIndicator(radius: 10)
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _createGroup,
                child: Text(
                  'Create',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
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
          children: [
            SizedBox(height: AppSpacing.sm),
            CupertinoListSection.insetGrouped(
              backgroundColor: AppColors.background(isDark),
              header: const Text('DETAILS'),
              margin:
                  EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              children: [
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'Group name',
                    textInputAction: TextInputAction.next,
                    padding: EdgeInsets.zero,
                    decoration: null,
                  ),
                ),
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: _descController,
                    placeholder: 'Description (optional)',
                    textInputAction: TextInputAction.done,
                    padding: EdgeInsets.zero,
                    decoration: null,
                  ),
                ),
              ],
            ),
            if (_selectedMembers.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md,
                    AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                child: Text(
                  'SELECTED (${_selectedMembers.length})'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(isDark),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                height: 76,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  itemCount: _selectedMembers.length,
                  itemBuilder: (context, index) {
                    final member = _selectedMembers[index];
                    final username =
                        (member['username'] ?? 'User').toString();
                    return Padding(
                      padding:
                          EdgeInsets.only(right: AppSpacing.sm),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(
                                      alpha: 0.15),
                                ),
                                child: Center(
                                  child: Text(
                                    username.isNotEmpty
                                        ? username[0]
                                            .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary(
                                        isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedMembers
                                      .removeAt(index)),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      CupertinoColors.systemRed,
                                ),
                                child: const Icon(
                                  CupertinoIcons.clear,
                                  size: 12,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md,
                  AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: Text(
                'ADD MEMBERS'.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(isDark),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUserId)
                  .collection('following')
                  .where('following', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                        child: CupertinoActivityIndicator()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'Follow people first to add them to groups.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                AppColors.textMuted(isDark)),
                      ),
                    ),
                  );
                }

                return CupertinoListSection.insetGrouped(
                  backgroundColor:
                      AppColors.background(isDark),
                  margin: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  children: docs.map((doc) {
                    final targetUid = doc.id;
                    return FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('Users')
                          .doc(targetUid)
                          .get(),
                      builder: (context, userSnap) {
                        final userData =
                            userSnap.data?.data();
                        if (userData == null) {
                          return const SizedBox.shrink();
                        }
                        final username =
                            (userData['username'] ?? 'User')
                                .toString();
                        final email =
                            (userData['email'] ?? '').toString();
                        final imageUrl =
                            (userData['userimageurl'] ?? '')
                                .toString();
                        final isSelected = _selectedMembers.any(
                            (m) => m['uid'] == targetUid);

                        return CupertinoListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: imageUrl.isEmpty
                                  ? accent.withValues(alpha: 0.15)
                                  : null,
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          imageUrl),
                                      fit: BoxFit.cover,
                                      onError: (_, __) {},
                                    )
                                  : null,
                            ),
                            child: imageUrl.isEmpty
                                ? Center(
                                    child: Text(
                                      username.isNotEmpty
                                          ? username[0]
                                              .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(username),
                          subtitle: email.isEmpty
                              ? null
                              : Text(
                                  email,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                          trailing: Icon(
                            isSelected
                                ? CupertinoIcons
                                    .check_mark_circled_solid
                                : CupertinoIcons.circle,
                            color: isSelected
                                ? accent
                                : AppColors.textMuted(isDark),
                            size: 24,
                          ),
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedMembers.removeWhere(
                                  (m) =>
                                      m['uid'] ==
                                      targetUid);
                            } else {
                              _selectedMembers.add({
                                'uid': targetUid,
                                'username': username,
                                'imageurl': imageUrl,
                              });
                            }
                          }),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
