import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/glass_action_sheet.dart';
import '../../../core/widgets/message_status_icon.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final Function(String)? onEdit;
  final Function(String)? onToggleReaction;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final bool animateEntrance;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onForward,
    this.onEdit,
    this.onToggleReaction,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.animateEntrance = true,
  });

  String _formatTime(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('h:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  /// iOS-native long-press menu: tapback emoji row + [LGActionSheet].
  void _showActionSheet(BuildContext context) {
    const tapbacks = ['❤️', '👍', '👎', '😂', '‼️', '❓'];

    final Widget? tapbackHeader = message.isDeletedForEveryone
        ? null
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: tapbacks
                  .map(
                    (emoji) => CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      onPressed: () {
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                        onToggleReaction?.call(emoji);
                      },
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );

    LGActionSheet.show(
      context: context,
      customHeader: tapbackHeader,
      actions: [
        LGActionSheetAction(
          title: 'Reply',
          icon: CupertinoIcons.reply,
          onPressed: () {
            HapticFeedback.selectionClick();
            onReply?.call();
          },
        ),
        LGActionSheetAction(
          title: 'Copy',
          icon: CupertinoIcons.doc_on_doc,
          onPressed: () {
            HapticFeedback.selectionClick();
            Clipboard.setData(ClipboardData(text: message.text));
            showSnackBar(context, "Copied to clipboard");
          },
        ),
        if (onForward != null)
          LGActionSheetAction(
            title: 'Forward',
            icon: CupertinoIcons.arrow_uturn_right,
            onPressed: () {
              HapticFeedback.selectionClick();
              onForward?.call();
            },
          ),
        if (isMe && !message.isDeletedForEveryone)
          LGActionSheetAction(
            title: 'Edit',
            icon: CupertinoIcons.pencil,
            onPressed: () {
              HapticFeedback.selectionClick();
              _showEditDialog(context);
            },
          ),
        LGActionSheetAction(
          title: 'Delete',
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showDeleteDialog(context);
          },
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    LGActionSheet.show(
      context: context,
      title: 'Delete Message',
      message: 'Choose how you want to delete this message.',
      actions: [
        if (onDeleteForEveryone != null)
          LGActionSheetAction(
            title: 'Delete for everyone',
            icon: CupertinoIcons.delete,
            isDestructive: true,
            onPressed: () => onDeleteForEveryone?.call(),
          ),
        LGActionSheetAction(
          title: 'Delete for me',
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onPressed: () => onDeleteForMe?.call(),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Edit Message"),
        content: Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: "Enter updated message",
            maxLines: 4,
            minLines: 1,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                onEdit?.call(newText);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
      BuildContext context, bool isDark, bool isDeleted, bool hasReactions) {
    final accent = CupertinoTheme.of(context).primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        // WhatsApp Liquid Glass message bubble styling
        gradient: (isMe && !isDeleted)
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  Color.alphaBlend(Colors.black.withValues(alpha: 0.15), accent),
                ],
              )
            : null,
        color: (isMe && !isDeleted)
            ? null
            : (isDeleted
                ? AppColors.receiverBubble(isDark).withValues(alpha: 0.4)
                : (isDark
                    ? const Color(0xB8232326)
                    : const Color(0xF5F0F0F3))),
        border: Border.all(
          color: (isMe && !isDeleted)
              ? Colors.white.withValues(alpha: 0.25)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06)),
          width: 0.75,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.lg),
          topRight: Radius.circular(AppSpacing.lg),
          bottomLeft: isMe ? Radius.circular(AppSpacing.lg) : Radius.zero,
          bottomRight: isMe ? Radius.zero : Radius.circular(AppSpacing.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: (isMe && !isDeleted)
                ? accent.withValues(alpha: isDark ? 0.32 : 0.20)
                : Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.replyToText != null &&
              message.replyToText!.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.only(bottom: AppSpacing.xs),
              padding: EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.xs),
                border: Border(
                  left: BorderSide(
                    color: isMe
                        ? Colors.white
                        : CupertinoTheme.of(context).primaryColor,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                message.replyToText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color:
                      isMe ? Colors.white70 : AppColors.textSecondary(isDark),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          Wrap(
            alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    right: AppSpacing.xs, bottom: AppSpacing.xs),
                child: Text(
                  message.text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDeleted
                        ? (isMe ? Colors.white70 : AppColors.textMuted(isDark))
                        : (isMe
                            ? AppColors.senderText
                            : AppColors.receiverText(isDark)),
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isEdited) ...[
                    Text(
                      '(edited) ',
                      style: AppTypography.caption.copyWith(
                        color: isMe
                            ? Colors.white70
                            : AppColors.textSecondary(isDark),
                        fontSize: AppTypography.caption.fontSize,
                      ),
                    ),
                  ],
                  Text(
                    _formatTime(message.clientCreatedAt),
                    style: AppTypography.caption.copyWith(
                      color: isMe
                          ? Colors.white70
                          : AppColors.textSecondary(isDark),
                      fontSize: AppTypography.caption.fontSize,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: AppSpacing.xs),
                    MessageStatusIcon(status: message.status),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: animateEntrance ? AppMotion.entranceDuration : Duration.zero,
      curve: AppMotion.entranceCurve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onLongPress: () => _showActionSheet(context),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              top: 4,
              left: 8,
              right: 8,
              bottom: message.reactions.isNotEmpty ? 14 : 4,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildMessageContent(context, isDark,
                    message.isDeletedForEveryone, message.reactions.isNotEmpty),
                if (message.reactions.isNotEmpty)
                  Positioned(
                    bottom: -12,
                    left: isMe ? 12 : null,
                    right: isMe ? null : 12,
                    child: ReactionBadge(
                      reactions: message.reactions,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReactionBadge extends StatefulWidget {
  final Map<String, String> reactions;
  final bool isDark;

  const ReactionBadge({
    super.key,
    required this.reactions,
    required this.isDark,
  });

  @override
  State<ReactionBadge> createState() => _ReactionBadgeState();
}

class _ReactionBadgeState extends State<ReactionBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.reactionAnimationDuration,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uniqueReactions = widget.reactions.values.toSet().toList();

    return ScaleTransition(
      scale: CurvedAnimation(
          parent: _controller, curve: AppMotion.reactionAnimationCurve),
      child: Wrap(
        spacing: AppSpacing.xs,
        children: uniqueReactions.map((emoji) {
          final count = widget.reactions.values.where((e) => e == emoji).length;
          return ScaleTransition(
            scale: CurvedAnimation(
                parent: _controller, curve: AppMotion.reactionAnimationCurve),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: AppSpacing.xs / 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$emoji ${count > 1 ? count : ''}',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium.fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(widget.isDark),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}