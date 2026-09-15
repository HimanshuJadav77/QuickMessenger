import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/services/call_service.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/theme/app_typography.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_components.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/core/widgets/glass_dialog.dart';
import 'package:quick_messenger/features/chat/models/call_model.dart';
import 'package:quick_messenger/features/chat/screens/call_screen.dart';
import 'package:quick_messenger/features/chat/screens/following_chats_screen.dart';

class CallsTabScreen extends ConsumerStatefulWidget {
  const CallsTabScreen({super.key});

  @override
  ConsumerState<CallsTabScreen> createState() => _CallsTabScreenState();
}

class _CallsTabScreenState extends ConsumerState<CallsTabScreen>
    with AutomaticKeepAliveClientMixin {
  int _segment = 0; // 0: All, 1: Missed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initiateCall({
    required String receiverId,
    required String receiverName,
    required String receiverImageUrl,
    required CallType callType,
  }) async {
    final currentUserId = ref.read(currentUserIdProvider);
    String callerName = 'Me';
    String callerAvatar = '';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();
      callerName = userDoc.data()?['name'] ?? userDoc.data()?['username'] ?? 'Me';
      callerAvatar = userDoc.data()?['userimageurl'] ?? userDoc.data()?['imageurl'] ?? '';
    } catch (_) {}

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
    final error = await ref.read(callServiceProvider.notifier).initiateCall(call);
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
            // ── Top Header Actions (Matching Chats Page) ──
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LGIconButton(
                    icon: CupertinoIcons.phone_badge_plus,
                    color: accent,
                    iconColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const FollowedChatList()),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Large Title: "Calls" (34pt Bold)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Calls',
                  style: AppTypography.displayLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            // Search Field
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 8),
              child: LGSearchField(
                controller: _searchController,
                placeholder: 'Search calls',
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            // Filter Pills (All, Missed)
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _segment = 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _segment == 0
                            ? accent.withValues(alpha: isDark ? 0.25 : 0.16)
                            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _segment == 0 ? accent.withValues(alpha: 0.6) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          color: _segment == 0 ? accent : AppColors.textSecondary(isDark),
                          fontWeight: _segment == 0 ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _segment = 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _segment == 1
                            ? accent.withValues(alpha: isDark ? 0.25 : 0.16)
                            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _segment == 1 ? accent.withValues(alpha: 0.6) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Missed',
                        style: TextStyle(
                          color: _segment == 1 ? accent : AppColors.textSecondary(isDark),
                          fontWeight: _segment == 1 ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Call List
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: currentUserId.isNotEmpty
                    ? FirebaseFirestore.instance
                        .collection("Users")
                        .doc(currentUserId)
                        .collection("call_logs")
                        .orderBy("timestamp", descending: true)
                        .snapshots()
                    : null,
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
                      final name = (data['otherUserName'] ?? '').toString().toLowerCase();
                      if (!name.contains(_searchQuery)) return false;
                    }
                    return true;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.phone, size: 52, color: AppColors.textMuted(isDark)),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            _segment == 1 ? 'No missed calls' : 'No recent calls',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Stay connected with audio and video calls',
                            style: TextStyle(color: AppColors.textMuted(isDark)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 110),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
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
                          final otherUserId = (data['otherUserId'] ?? doc.id).toString();
                          final username = (data['otherUserName'] ?? 'User').toString();
                          final imageUrl = (data['otherUserImageUrl'] ?? '').toString();
                          final direction = (data['direction'] ?? 'outgoing').toString();
                          final status = (data['status'] ?? '').toString();
                          final durationSeconds = (data['durationSeconds'] as int?) ?? 0;
                          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                          final formattedTime = _formatTimestamp(timestamp);
                          final durationStr = _formatDuration(durationSeconds);
                          final isMissed = status == 'missed';

                          return CupertinoListTile(
                            leading: UserAvatar(
                              username: username,
                              imageUrl: imageUrl,
                              radius: 22,
                            ),
                            title: Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isMissed ? CupertinoColors.systemRed : AppColors.textPrimary(isDark),
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  isMissed
                                      ? CupertinoIcons.phone_arrow_down_left
                                      : (direction == 'incoming'
                                          ? CupertinoIcons.phone_arrow_down_left
                                          : CupertinoIcons.phone_arrow_up_right),
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
                                      color: isMissed ? CupertinoColors.systemRed : AppColors.textMuted(isDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  onPressed: () {
                                    _initiateCall(
                                      receiverId: otherUserId,
                                      receiverName: username,
                                      receiverImageUrl: imageUrl,
                                      callType: CallType.voice,
                                    );
                                  },
                                  child: Icon(CupertinoIcons.phone, color: accent, size: 22),
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  onPressed: () {
                                    _initiateCall(
                                      receiverId: otherUserId,
                                      receiverName: username,
                                      receiverImageUrl: imageUrl,
                                      callType: CallType.video,
                                    );
                                  },
                                  child: Icon(CupertinoIcons.video_camera, color: accent, size: 24),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 110),
                    ],
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
