import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/services/call_service.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/core/widgets/glass_dialog.dart';
import 'package:quick_messenger/core/database/local_database_helper.dart';
import 'package:quick_messenger/core/widgets/app_filter_chip.dart';
import 'package:quick_messenger/core/widgets/app_screen_header.dart';
import 'package:quick_messenger/core/services/user_profile_cache_service.dart';
import 'package:quick_messenger/features/chat/models/call_model.dart';
import 'package:quick_messenger/features/chat/screens/call_screen.dart';
import 'package:quick_messenger/features/chat/screens/following_chats_screen.dart';

class CallsTabScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNewCall;
  const CallsTabScreen({super.key, this.onNewCall});

  @override
  ConsumerState<CallsTabScreen> createState() => _CallsTabScreenState();
}

class _CallsTabScreenState extends ConsumerState<CallsTabScreen>
    with AutomaticKeepAliveClientMixin {
  int _segment = 0; // 0: All, 1: Missed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, String> _resolvedNames = {};
  Stream<QuerySnapshot<Map<String, dynamic>>>? _callsStream;
  String? _streamUserId;

  void _ensureStream(String currentUserId) {
    if (_streamUserId == currentUserId && _callsStream != null) return;
    _streamUserId = currentUserId;
    if (currentUserId.isNotEmpty) {
      _callsStream = FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("call_logs")
          .orderBy("timestamp", descending: true)
          .snapshots();
    } else {
      _callsStream = null;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resolveMissingUsername(String otherUserId) {
    if (_resolvedNames.containsKey(otherUserId)) return;
    _resolvedNames[otherUserId] = '';
    final currentUserId = ref.read(currentUserIdProvider);

    final syncProfile =
        UserProfileCacheService.instance.getProfileSync(otherUserId);
    if (syncProfile != null) {
      final name =
          (syncProfile['username'] ?? syncProfile['name'] ?? '').toString();
      if (name.isNotEmpty) {
        _resolvedNames[otherUserId] = name;
        return;
      }
    }

    UserProfileCacheService.instance
        .getProfile(currentUserId: currentUserId, targetUid: otherUserId)
        .then((profile) {
      if (profile != null && mounted) {
        final name =
            (profile['username'] ?? profile['name'] ?? '').toString();
        if (name.isNotEmpty) {
          setState(() {
            _resolvedNames[otherUserId] = name;
          });
        }
      }
    }).catchError((_) {});
  }

  Future<void> _deleteCallLog(String callId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUserId)
          .collection("call_logs")
          .doc(callId)
          .delete();
    } catch (e) {
      debugPrint("[CallsTab] Error deleting call log: $e");
    }
  }

  void _showCallActions({
    required BuildContext context,
    required String logId,
    required String otherUserId,
    required String username,
    required String imageUrl,
  }) {
    HapticFeedback.selectionClick();
    LGActionSheet.show(
      context: context,
      title: username,
      message: 'Call history options',
      actions: [
        LGActionSheetAction(
          title: 'Voice Call',
          icon: CupertinoIcons.phone,
          onPressed: () {
            _initiateCall(
              receiverId: otherUserId,
              receiverName: username,
              receiverImageUrl: imageUrl,
              callType: CallType.voice,
            );
          },
        ),
        LGActionSheetAction(
          title: 'Video Call',
          icon: CupertinoIcons.videocam,
          onPressed: () {
            _initiateCall(
              receiverId: otherUserId,
              receiverName: username,
              receiverImageUrl: imageUrl,
              callType: CallType.video,
            );
          },
        ),
        LGActionSheetAction(
          title: 'Delete Call Log',
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onPressed: () {
            LGActionSheet.showConfirmation(
              context: context,
              title: 'Delete Call Log?',
              message:
                  'Are you sure you want to remove this call with $username from your history?',
              confirmTitle: 'Delete',
              isDestructive: true,
              onConfirm: () => _deleteCallLog(logId),
            );
          },
        ),
      ],
    );
  }

  void _initiateCall({
    required String receiverId,
    required String receiverName,
    required String receiverImageUrl,
    required CallType callType,
  }) async {
    final currentUserId = ref.read(currentUserIdProvider);
    String callerName = 'User';
    String callerAvatar = '';
    try {
      final localMe = await LocalDatabaseHelper.instance
          .getUserProfile(currentUserId, currentUserId);
      if (localMe != null &&
          localMe['username'] != null &&
          localMe['username'].toString().isNotEmpty) {
        callerName = localMe['username'].toString();
        callerAvatar = (localMe['image_url'] ?? '').toString();
      }
    } catch (_) {}
    if (callerName == 'User') {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUserId)
            .get();
        final uData = userDoc.data();
        if (uData != null) {
          callerName = (uData['username'] ??
                  uData['name'] ??
                  FirebaseAuth.instance.currentUser?.displayName ??
                  'User')
              .toString();
          callerAvatar = (uData['imageurl'] ??
                  uData['userimageurl'] ??
                  FirebaseAuth.instance.currentUser?.photoURL ??
                  '')
              .toString();
        }
      } catch (_) {}
    }

    final call = CallModel(
      callId: DateTime.now().millisecondsSinceEpoch.toString(),
      callerId: currentUserId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverImageUrl,
      callType: callType,
      status: CallStatus.calling,
    );
    final error =
        await ref.read(callServiceProvider.notifier).initiateCall(call);
    if (error != null) {
      if (mounted) {
        GlassDialog.showInfo(
          context: context,
          title: 'Service Unavailable',
          message: error,
          buttonLabel: 'OK',
        );
      }
      return;
    }
    if (mounted) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const CallScreen()),
      );
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inDays == 0 && dt.day == now.day) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $amPm';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final currentUserId = ref.watch(currentUserIdProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(isDark),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header Row ──
            AppScreenHeader(
              title: 'Calls',
              actions: [
                AppHeaderIconButton(
                  icon: CupertinoIcons.phone_badge_plus,
                  isPrimary: true,
                  onPressed: () {
                    if (widget.onNewCall != null) {
                      widget.onNewCall!();
                    } else {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const FollowedChatList()),
                      );
                    }
                  },
                ),
              ],
            ),
            // Search Field
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 8),
              child: LGSearchField(
                controller: _searchController,
                placeholder: 'Search calls',
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            // Filter Pills (All, Missed)
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 8),
              child: Row(
                children: [
                  AppFilterChip(
                    label: 'All',
                    isSelected: _segment == 0,
                    onTap: () => setState(() => _segment = 0),
                  ),
                  const SizedBox(width: 8),
                  AppFilterChip(
                    label: 'Missed',
                    isSelected: _segment == 1,
                    onTap: () => setState(() => _segment = 1),
                  ),
                ],
              ),
            ),
            // Call List
            Expanded(
              child: Builder(
                builder: (context) {
                  _ensureStream(currentUserId);
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _callsStream,
                    builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = allDocs.where((doc) {
                    final data = doc.data();
                    final status = (data['status'] ?? '').toString();
                    if (_segment == 1 && status != 'missed') {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      final name = (data['otherUserName'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (!name.contains(_searchQuery)) return false;
                    }
                    return true;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.phone,
                              size: 52, color: AppColors.textMuted(isDark)),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            _segment == 1
                                ? 'No missed calls'
                                : 'No recent calls',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Stay connected with audio and video calls',
                            style:
                                TextStyle(color: AppColors.textMuted(isDark)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 110),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                        child: Text(
                          'RECENT',
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
                        margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        children: docs.map((doc) {
                          final data = doc.data();
                          final otherUserId =
                              (data['otherUserId'] ?? doc.id).toString();
                          String username =
                              (data['otherUserName'] ?? '').toString();
                          if (username.isEmpty || username == 'User') {
                            if (_resolvedNames[otherUserId]?.isNotEmpty ==
                                true) {
                              username = _resolvedNames[otherUserId]!;
                            } else {
                              _resolveMissingUsername(otherUserId);
                              username = 'User';
                            }
                          }
                          final imageUrl =
                              (data['otherUserImageUrl'] ?? '').toString();
                          final direction =
                              (data['direction'] ?? 'outgoing').toString();
                          final status = (data['status'] ?? '').toString();
                          final durationSeconds =
                              (data['durationSeconds'] as int?) ?? 0;
                          final timestamp =
                              (data['timestamp'] as Timestamp?)?.toDate();
                          final formattedTime = _formatTimestamp(timestamp);
                          final durationStr = _formatDuration(durationSeconds);
                          final isMissed = status == 'missed';

                          return RepaintBoundary(
                            key: ValueKey('call_log_${doc.id}'),
                            child: Dismissible(
                              key: Key('call_log_${doc.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: CupertinoColors.destructiveRed,
                              child: const Icon(CupertinoIcons.trash,
                                  color: Colors.white, size: 22),
                            ),
                            confirmDismiss: (_) async {
                              return await showCupertinoDialog<bool>(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: const Text('Delete Call Log'),
                                  content: Text('Delete call with $username?'),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _deleteCallLog(doc.id),
                            child: GestureDetector(
                              onLongPress: () {
                                _showCallActions(
                                  context: context,
                                  logId: doc.id,
                                  otherUserId: otherUserId,
                                  username: username,
                                  imageUrl: imageUrl,
                                );
                              },
                              child: CupertinoListTile(
                                padding: AppSpacing.listTilePadding,
                                leadingSize: AppSpacing.listTileLeadingSize,
                                leadingToTitle:
                                    AppSpacing.listTileLeadingToTitle,
                                onTap: () {
                                  _showCallActions(
                                    context: context,
                                    logId: doc.id,
                                    otherUserId: otherUserId,
                                    username: username,
                                    imageUrl: imageUrl,
                                  );
                                },
                                leading: UserAvatar(
                                  username: username,
                                  imageUrl: imageUrl,
                                  radius: AppAvatarSize.listTile,
                                ),
                                title: Text(
                                  username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isMissed
                                        ? CupertinoColors.systemRed
                                        : AppColors.textPrimary(isDark),
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      isMissed
                                          ? CupertinoIcons.phone_arrow_down_left
                                          : (direction == 'incoming'
                                              ? CupertinoIcons
                                                  .phone_arrow_down_left
                                              : CupertinoIcons
                                                  .phone_arrow_up_right),
                                      size: 14,
                                      color: isMissed
                                          ? CupertinoColors.systemRed
                                          : (direction == 'incoming'
                                              ? AppColors.success
                                              : AppColors.textMuted(isDark)),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        isMissed
                                            ? 'Missed${formattedTime.isNotEmpty ? " • $formattedTime" : ""}'
                                            : '${direction == "incoming" ? "Incoming" : "Outgoing"}${durationStr.isNotEmpty ? " • $durationStr" : ""}${formattedTime.isNotEmpty ? " • $formattedTime" : ""}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isMissed
                                              ? CupertinoColors.systemRed
                                              : AppColors.textMuted(isDark),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      onPressed: () {
                                        _initiateCall(
                                          receiverId: otherUserId,
                                          receiverName: username,
                                          receiverImageUrl: imageUrl,
                                          callType: CallType.voice,
                                        );
                                      },
                                      child: Icon(CupertinoIcons.phone,
                                          color: accent, size: 22),
                                    ),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      onPressed: () {
                                        _initiateCall(
                                          receiverId: otherUserId,
                                          receiverName: username,
                                          receiverImageUrl: imageUrl,
                                          callType: CallType.video,
                                        );
                                      },
                                      child: Icon(CupertinoIcons.video_camera,
                                          color: accent, size: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                        }).toList(),
                      ),
                      const SizedBox(height: 110),
                    ],
                  );
                },
              );
            },
          ),
        ),
          ],
        ),
      ),
    );
  }
}
