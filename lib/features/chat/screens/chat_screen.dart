// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/services/call_service.dart';
import 'package:quick_messenger/core/services/navigation_service.dart';
import 'package:quick_messenger/core/services/socket_service.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/utils/networkcheck.dart';
import 'package:quick_messenger/core/widgets/app_snackbar.dart';
import 'package:quick_messenger/core/widgets/glass_action_sheet.dart';
import 'package:quick_messenger/core/widgets/glass_dialog.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/features/chat/models/call_model.dart';
import 'package:quick_messenger/features/chat/models/message_model.dart';
import 'package:quick_messenger/features/chat/providers/chat_provider.dart';
import 'package:quick_messenger/features/chat/screens/call_screen.dart';
import 'package:quick_messenger/features/chat/screens/message_search_screen.dart';
import 'package:quick_messenger/features/chat/widgets/message_bubble.dart';
import 'package:quick_messenger/features/chat/widgets/message_input.dart';
import 'package:quick_messenger/features/profile/screens/user_profile_screen.dart';

/// iOS-native 1-to-1 chat screen.
///
/// - Frosted [CupertinoNavigationBar] with contact avatar, live status, and direct call buttons.
/// - WhatsApp iOS background canvas with calendar date separators.
/// - Interactive message bubbles with tapback reactions and reply banner.
/// - Action sheets powered by [LGActionSheet].
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.participantId,
    required this.participantName,
    required this.participantImageUrl,
    required this.participantAbout,
    required this.participantEmail,
  });

  final String participantId;
  final String participantName;
  final String participantImageUrl;
  final String participantAbout;
  final String participantEmail;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<PlatformFile> _pickedFiles = [];
  File? _pickedImage;
  List<XFile> _pickedImages = [];
  final bool _loading = false;
  bool _blocked = false;
  MessageModel? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _checkBlocked();
    _blockedByUser();
    WidgetsBinding.instance.addObserver(this);
    NetworkCheck().initializeInternetStatus(context);
    SocketService.instance.connect();
    // Mark conversation as read when opened and notify socket of active conversation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        final convId = ref.read(chatRepositoryProvider).getConversationId(uid, widget.participantId);
        ref.read(chatMessagesProvider(convId).notifier).markAsRead(widget.participantId);
        SocketService.instance.emitSetActiveConversation(convId);
        ref.read(chatRepositoryProvider).syncMessages(convId);
      }
    });
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      FirebaseFirestore.instance.collection("Users").doc(uid).update({"online": false});
    } else if (state == AppLifecycleState.resumed) {
      FirebaseFirestore.instance.collection("Users").doc(uid).update({"online": true});
    }
  }

  @override
  void dispose() {
    SocketService.instance.emitSetActiveConversation(null);
    _textController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    NetworkCheck().cancelSubscription();
    super.dispose();
  }


  Future<void> _checkBlocked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("block")
        .doc(uid)
        .collection("blockedid")
        .doc(widget.participantId)
        .get();
    if (doc.exists && doc.data()?["blocked"] == true) {
      if (mounted) setState(() => _blocked = true);
    }
  }

  Future<void> _blockedByUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("block")
        .doc(widget.participantId)
        .collection("blockedid")
        .doc(uid)
        .get();
    if (!doc.exists) {
      await FirebaseFirestore.instance
          .collection("block")
          .doc(widget.participantId)
          .collection("blockedid")
          .doc(uid)
          .set({"blocked": false});
    }
  }

  void _openProfile() async {
    final blockedByThem = await FirebaseFirestore.instance
        .collection("block")
        .doc(widget.participantId)
        .collection("blockedid")
        .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
        .get();

    if (blockedByThem.data()?["blocked"] == true) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Blocked"),
            content: Text("${widget.participantName} has blocked you."),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => SearchUserProfile(
            username: widget.participantName,
            email: widget.participantEmail,
            about: widget.participantAbout,
            imageurl: widget.participantImageUrl,
            userid: widget.participantId,
          ),
        ),
      );
    }
  }

  void _startCall(CallType callType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_blocked) {
      showSnackBar(context, "Cannot call a blocked contact");
      return;
    }
    final callId = '${uid}_${DateTime.now().millisecondsSinceEpoch}';
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    final callerName = userDoc.data()?['name'] ?? userDoc.data()?['username'] ?? 'User';
    final callerAvatar = userDoc.data()?['imageurl'] ?? '';

    final call = CallModel(
      callId: callId,
      callerId: uid,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: widget.participantId,
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

  void _showMoreOptions() {
    final currentUserId = ref.read(currentUserIdProvider);
    final repo = ref.read(chatRepositoryProvider);
    final conversationId = currentUserId.isNotEmpty
        ? repo.getConversationId(currentUserId, widget.participantId)
        : widget.participantId;

    LGActionSheet.show(
      context: context,
      title: widget.participantName,
      message: widget.participantAbout.isNotEmpty ? widget.participantAbout : null,
      actions: [
        LGActionSheetAction(
          title: 'Contact Info',
          icon: CupertinoIcons.person_crop_circle,
          onPressed: _openProfile,
        ),
        LGActionSheetAction(
          title: 'Search in Chat',
          icon: CupertinoIcons.search,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const MessageSearchScreen()),
            );
          },
        ),
        LGActionSheetAction(
          title: 'Clear Chat',
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onPressed: () {
            LGActionSheet.showConfirmation(
              context: context,
              title: 'Clear Chat?',
              message: 'This will delete all messages from this conversation on your device.',
              confirmTitle: 'Clear Messages',
              isDestructive: true,
              onConfirm: () async {
                await ref.read(chatMessagesProvider(conversationId).notifier).clearConversation();
                if (mounted) {
                  showSnackBar(context, "Chat cleared");
                }
              },
            );
          },
        ),
        LGActionSheetAction(
          title: _blocked ? 'Unblock Contact' : 'Block Contact',
          icon: _blocked ? CupertinoIcons.check_mark_circled : CupertinoIcons.slash_circle,
          isDestructive: !_blocked,
          onPressed: _toggleBlockContact,
        ),
      ],
    );
  }

  void _toggleBlockContact() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final newStatus = !_blocked;
    await FirebaseFirestore.instance
        .collection("block")
        .doc(uid)
        .collection("blockedid")
        .doc(widget.participantId)
        .set({"blocked": newStatus});
    if (mounted) {
      setState(() => _blocked = newStatus);
      showSnackBar(context, newStatus ? "Blocked ${widget.participantName}" : "Unblocked ${widget.participantName}");
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: [
          'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma', 'alac',
          'ape', 'ac3', 'opus', 'aiff', 'mid', 'mka', 'flv', 'amr',
          'pdf', 'txt', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'odt', 'ods', 'odp', 'rtf', 'epub', 'zip', 'rar', 'tar',
          '7z', 'gz', 'iso', 'mp4', 'mkv', 'avi', 'mov', 'wmv',
          'flv', 'webm', 'mpeg', 'mpg', '3gp', 'vob', 'ogv', 'rm',
          'ram', 'm4v', 'asf',
        ],
        allowMultiple: true,
        allowCompression: true,
        type: FileType.custom,
      );
      if (result != null && mounted) {
        setState(() => _pickedFiles.addAll(result.files));
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString());
    }
  }

  Future<void> _pickImageCamera() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        setState(() => _pickedImage = File(photo.path));
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString());
    }
  }

  Future<void> _pickImagesGallery() async {
    try {
      final photos = await _picker.pickMultiImage(limit: 5);
      if (photos.isNotEmpty && mounted) {
        setState(() => _pickedImages = photos);
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString());
    }
  }

  void _clearAttachments() {
    setState(() {
      _pickedFiles.clear();
      _pickedImage = null;
      _pickedImages.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleBack() {
    ref.read(conversationsProvider.notifier).loadConversations();
    NavigationService.handleBackNavigation(context);
  }


  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_blocked) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Blocked"),
          content: Text("You have blocked ${widget.participantName}."),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final blockedByThem = await FirebaseFirestore.instance
        .collection("block")
        .doc(widget.participantId)
        .collection("blockedid")
        .doc(uid)
        .get();
    if (blockedByThem.data()?["blocked"] == true) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Blocked"),
            content: Text("${widget.participantName} has blocked you."),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    final conversationId = ref.read(chatRepositoryProvider).getConversationId(uid, widget.participantId);
    final replyId = _replyToMessage?.messageId;
    final replyTxt = _replyToMessage?.text;
    final replySender = _replyToMessage?.senderId;

    setState(() {
      _replyToMessage = null;
    });

    await ref.read(chatMessagesProvider(conversationId).notifier).sendMessage(
      senderId: uid,
      receiverId: widget.participantId,
      text: text,
      replyToMessageId: replyId,
      replyToText: replyTxt,
      replyToSenderId: replySender,
      participantName: widget.participantName,
      participantImageUrl: widget.participantImageUrl,
    );
    _textController.clear();
    _scrollToBottom();
  }

  String _getFileType(String ext) {
    final lower = ext.toLowerCase();
    if (['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma',
      '.alac', '.ape', '.ac3', '.opus', '.aiff', '.mid', '.mka',
      '.flv', '.amr'].contains(lower)) {
      return 'Audio';
    }
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.svg',
      '.ico', '.webp', '.heif', '.heic', '.raw'].contains(lower)) {
      return 'Image';
    }
    if (['.pdf'].contains(lower)) {
      return 'PDF Document';
    }
    if (['.txt', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.odt', '.ods', '.odp', '.rtf', '.epub'].contains(lower)) {
      return 'Document';
    }
    if (['.zip', '.rar', '.tar', '.7z', '.gz', '.iso', '.tar.gz'].contains(lower)) {
      return 'Compressed File';
    }
    if (['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm',
      '.mpeg', '.mpg', '.3gp', '.vob', '.ogv', '.rm', '.ram',
      '.m4v', '.asf'].contains(lower)) {
      return 'Video';
    }
    return 'Unknown Type';
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(currentUserIdProvider);
    final repo = ref.watch(chatRepositoryProvider);
    final conversationId = currentUserId.isNotEmpty
        ? repo.getConversationId(currentUserId, widget.participantId)
        : widget.participantId;
    final messagesAsync = ref.watch(chatMessagesProvider(conversationId));

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxTitleWidth = (screenWidth - 200).clamp(120.0, 300.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          padding: const EdgeInsetsDirectional.only(start: 0, end: 6),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.only(left: 4, right: 4),
                minimumSize: const Size(32, 44),
                onPressed: _handleBack,
                child: Icon(
                  CupertinoIcons.back,
                  size: 26,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openProfile,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  UserAvatar(
                    username: widget.participantName,
                    seed: widget.participantId,
                    imageUrl: widget.participantImageUrl,
                    radius: 18,
                    showOnlineBadge: false,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxTitleWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.participantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("Users")
                              .doc(widget.participantId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final online = snapshot.data?.get("online") == true;
                            if (online) {
                              return const Text(
                                "Online",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.systemGreen,
                                ),
                              );
                            }
                            return Text(
                              "tap here for info",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted(isDark),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(32, 32),
              onPressed: () => _startCall(CallType.video),
              child: const Icon(CupertinoIcons.video_camera, size: 21, color: AppColors.accentPurple),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(32, 32),
              onPressed: () => _startCall(CallType.voice),
              child: const Icon(CupertinoIcons.phone, size: 19, color: AppColors.accentPurple),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(32, 32),
              onPressed: _showMoreOptions,
              child: Icon(CupertinoIcons.ellipsis_vertical, size: 18, color: AppColors.textPrimary(isDark)),
            ),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0F141C),
                    Color(0xFF0A0D12),
                  ]
                : const [
                    Color(0xFFF4F2ED),
                    Color(0xFFE8E4DD),
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(child: CupertinoActivityIndicator()),
                  error: (e, st) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_triangle,
                            size: 48, color: CupertinoColors.systemRed),
                        SizedBox(height: AppSpacing.sm),
                        const Text("Failed to load messages",
                            style: TextStyle(color: CupertinoColors.systemRed)),
                        SizedBox(height: AppSpacing.xs),
                        Text(e.toString(), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.chat_bubble_2,
                                size: 54, color: AppColors.textMuted(isDark)),
                            SizedBox(height: AppSpacing.sm),
                            Text("No messages yet",
                                style: TextStyle(color: AppColors.textSecondary(isDark))),
                            SizedBox(height: AppSpacing.xs),
                            Text("Send a message to start the conversation",
                                style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        left: AppSpacing.sm,
                        right: AppSpacing.sm,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final chronologicalIndex = messages.length - 1 - index;
                        final msg = messages[chronologicalIndex];
                        final isMe = msg.senderId == currentUserId;

                        DateTime? msgDate;
                        try {
                          msgDate = DateTime.parse(msg.clientCreatedAt).toLocal();
                        } catch (_) {}

                        bool isFirstMessageOfDay = false;
                        if (msgDate != null) {
                          if (chronologicalIndex == 0) {
                            isFirstMessageOfDay = true;
                          } else {
                            try {
                              final prevDate = DateTime.parse(messages[chronologicalIndex - 1].clientCreatedAt).toLocal();
                              if (!_isSameCalendarDay(msgDate, prevDate)) {
                                isFirstMessageOfDay = true;
                              }
                            } catch (_) {
                              isFirstMessageOfDay = true;
                            }
                          }
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isFirstMessageOfDay && msgDate != null)
                              _DatePill(date: msgDate, isDark: isDark),
                            MessageBubble(
                              key: ValueKey(msg.messageId),
                              message: msg,
                              isMe: isMe,
                              animateEntrance: true,
                              onReply: () {
                                setState(() => _replyToMessage = msg);
                              },
                              onForward: () {},
                              onEdit: isMe ? (newText) {
                                ref.read(chatMessagesProvider(conversationId).notifier)
                                    .editMessage(msg.messageId, newText, widget.participantId);
                              } : null,
                              onToggleReaction: (emoji) {
                                ref.read(chatMessagesProvider(conversationId).notifier)
                                    .toggleReaction(msg.messageId, emoji, widget.participantId, currentUserId);
                              },
                              onDeleteForMe: () {
                                ref.read(chatMessagesProvider(conversationId).notifier)
                                    .deleteForMe(msg.messageId);
                              },
                              onDeleteForEveryone: isMe ? () {
                                ref.read(chatMessagesProvider(conversationId).notifier)
                                    .deleteForEveryone(msg.messageId, widget.participantId);
                              } : null,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Floating Reply Preview Banner
              if (_replyToMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xE61E1E22) : const Color(0xF0F5F5F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.12)
                          : CupertinoColors.black.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _replyToMessage!.senderId == currentUserId
                                  ? 'Replying to yourself'
                                  : 'Replying to ${widget.participantName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentPurple,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _replyToMessage!.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                        onPressed: () => setState(() => _replyToMessage = null),
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 20,
                          color: AppColors.textMuted(isDark),
                        ),
                      ),
                    ],
                  ),
                ),

              // Attachments preview
              if (_pickedFiles.isNotEmpty ||
                  _pickedImage != null ||
                  _pickedImages.isNotEmpty)
                _AttachmentsPreview(
                  pickedFiles: _pickedFiles,
                  pickedImage: _pickedImage,
                  pickedImages: _pickedImages,
                  onClear: _clearAttachments,
                  getFileType: _getFileType,
                  isDark: isDark,
                ),

              // Input bar
              MessageInput(
                controller: _textController,
                onChanged: (_) {},
                onSend: _handleSend,
                onAttach: _loading ? null : _showAttachSheet,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  void _showAttachSheet() {
    LGActionSheet.show(
      context: context,
      title: "Share Content",
      actions: [
        LGActionSheetAction(
          title: "Camera",
          icon: CupertinoIcons.camera_fill,
          onPressed: _pickImageCamera,
        ),
        LGActionSheetAction(
          title: "Photo Library",
          icon: CupertinoIcons.photo_fill_on_rectangle_fill,
          onPressed: _pickImagesGallery,
        ),
        LGActionSheetAction(
          title: "Document",
          icon: CupertinoIcons.doc_fill,
          onPressed: _pickFiles,
        ),
      ],
    );
  }
}

/// Frosted liquid glass calendar date pill separator.
class _DatePill extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _DatePill({required this.date, required this.isDark});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return "Today";
    if (msgDay == yesterday) return "Yesterday";
    if (msgDay.year == now.year) {
      return DateFormat('EEEE, MMMM d').format(dt);
    }
    return DateFormat('MMMM d, y').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.black.withValues(alpha: 0.5)
              : CupertinoColors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.1)
                : CupertinoColors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            color: isDark
                ? CupertinoColors.systemGrey.highContrastColor
                : CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

/// Small preview bar above input when attachments are selected.
class _AttachmentsPreview extends StatelessWidget {
  final List<PlatformFile> pickedFiles;
  final File? pickedImage;
  final List<XFile> pickedImages;
  final VoidCallback onClear;
  final String Function(String) getFileType;
  final bool isDark;

  const _AttachmentsPreview({
    required this.pickedFiles,
    required this.pickedImage,
    required this.pickedImages,
    required this.onClear,
    required this.getFileType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer(isDark).withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: AppColors.divider(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            children: [
              if (pickedImage != null) _PreviewItem(
                fileType: "Image",
                fileName: pickedImage!.path.split('/').last,
                thumbnail: Image.file(pickedImage!, width: 60, height: 60, fit: BoxFit.cover),
                isDark: isDark,
              ),
              ...pickedImages.map((x) => _PreviewItem(
                fileType: "Image",
                fileName: x.name,
                thumbnail: Image.file(File(x.path), width: 60, height: 60, fit: BoxFit.cover),
                isDark: isDark,
              )),
              ...pickedFiles.map((f) => _PreviewItem(
                fileType: getFileType(f.extension ?? ''),
                fileName: f.name,
                thumbnail: Icon(
                  _iconForType(getFileType(f.extension ?? '')),
                  size: 36,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
                isDark: isDark,
              )),
            ],
          ),
          Positioned(
            right: AppSpacing.xs,
            top: AppSpacing.xs,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onClear,
              child: const Icon(CupertinoIcons.clear_circled_solid, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Audio': return CupertinoIcons.music_note;
      case 'Image': return CupertinoIcons.photo;
      case 'Video': return CupertinoIcons.film;
      case 'PDF Document': return CupertinoIcons.doc_text;
      case 'Document': return CupertinoIcons.doc;
      case 'Compressed File': return CupertinoIcons.folder;
      default: return CupertinoIcons.doc;
    }
  }
}

class _PreviewItem extends StatelessWidget {
  final String fileType;
  final String fileName;
  final Widget thumbnail;
  final bool isDark;

  const _PreviewItem({
    required this.fileType,
    required this.fileName,
    required this.thumbnail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
            child: SizedBox(width: 80, height: 60, child: Center(child: thumbnail)),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}