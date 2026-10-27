import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../core/services/media_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/glass_action_sheet.dart';
import '../../../core/widgets/message_status_icon.dart';
import '../../../core/widgets/user_avatar.dart';
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
  final Function(String localPath)? onMediaDownloaded;
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
    this.onMediaDownloaded,
    this.animateEntrance = true,
  });

  static final _timeFormatter = DateFormat('h:mm a');

  String _formatTime(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return _timeFormatter.format(date);
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
        if (!message.isDeletedForEveryone)
          LGActionSheetAction(
            title: 'Reply',
            icon: CupertinoIcons.reply,
            onPressed: () {
              HapticFeedback.selectionClick();
              onReply?.call();
            },
          ),
        if (message.type == 'text' && !message.isDeletedForEveryone)
          LGActionSheetAction(
            title: 'Copy',
            icon: CupertinoIcons.doc_on_doc,
            onPressed: () {
              HapticFeedback.selectionClick();
              Clipboard.setData(ClipboardData(text: message.text));
              showSnackBar(context, "Copied to clipboard");
            },
          ),
        if (message.localPath != null && File(message.localPath!).existsSync())
          LGActionSheetAction(
            title: 'Open File',
            icon: CupertinoIcons.arrow_up_right_square,
            onPressed: () {
              HapticFeedback.selectionClick();
              OpenFile.open(message.localPath!);
            },
          ),
        if (onForward != null && !message.isDeletedForEveryone)
          LGActionSheetAction(
            title: 'Forward',
            icon: CupertinoIcons.arrow_uturn_right,
            onPressed: () {
              HapticFeedback.selectionClick();
              onForward?.call();
            },
          ),
        if (isMe && !message.isDeletedForEveryone && message.type == 'text')
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
          padding: const EdgeInsets.only(top: 12),
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
    final isMedia = message.type == 'image' || message.type == 'file';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMedia ? 6 : AppSpacing.md,
        vertical: isMedia ? 6 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: (isMe && !isDeleted)
            ? AppColors.textPrimary(isDark)
            : (isDeleted
                ? (isDark ? const Color(0xFF1E1E22) : const Color(0xFFE8E8ED))
                : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7))),
        border: Border.all(
          color: (isMe && !isDeleted)
              ? Colors.transparent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: 1.0,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft:
              isMe ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight:
              isMe ? const Radius.circular(4) : const Radius.circular(20),
        ),
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
                  color: isMe
                      ? AppColors.background(isDark).withValues(alpha: 0.8)
                      : AppColors.textSecondary(isDark),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Media viewer (image / document)
          if (!isDeleted && isMedia) ...[
            if (message.type == 'image')
              _ImageBubble(
                message: message,
                isMe: isMe,
                isDark: isDark,
                onDownloaded: onMediaDownloaded,
              )
            else if (message.type == 'file')
              _FileBubble(
                message: message,
                isMe: isMe,
                isDark: isDark,
                onDownloaded: onMediaDownloaded,
              ),
            const SizedBox(height: 4),
          ],

          // Text content & metadata wrap
          Wrap(
            alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              if (message.text.isNotEmpty &&
                  (!isMedia ||
                      (message.text != message.fileName &&
                          message.text != '📷 Photo'))) ...[
                Padding(
                  padding: EdgeInsets.only(
                      left: isMedia ? 6 : 0,
                      right: AppSpacing.xs,
                      bottom: AppSpacing.xs),
                  child: Text(
                    message.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDeleted
                          ? AppColors.textMuted(isDark)
                          : (isMe
                              ? AppColors.background(isDark)
                              : AppColors.textPrimary(isDark)),
                      fontStyle:
                          isDeleted ? FontStyle.italic : FontStyle.normal,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
              Padding(
                padding: EdgeInsets.only(right: isMedia ? 4 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited) ...[
                      Text(
                        '(edited) ',
                        style: AppTypography.caption.copyWith(
                          color: isMe
                              ? AppColors.background(isDark)
                                  .withValues(alpha: 0.6)
                              : AppColors.textSecondary(isDark),
                          fontSize: AppTypography.caption.fontSize,
                        ),
                      ),
                    ],
                    Text(
                      _formatTime(message.clientCreatedAt),
                      style: AppTypography.caption.copyWith(
                        color: isDeleted
                            ? AppColors.textMuted(isDark)
                            : (isMe
                                ? AppColors.background(isDark)
                                    .withValues(alpha: 0.6)
                                : AppColors.textSecondary(isDark)),
                        fontSize: AppTypography.caption.fontSize,
                      ),
                    ),
                    if (isMe && !isDeleted) ...[
                      SizedBox(width: AppSpacing.xs),
                      MessageStatusIcon(status: message.status),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final content = GestureDetector(
      onLongPress: () => _showActionSheet(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? AppSpacing.xl : AppSpacing.md,
            right: isMe ? AppSpacing.md : AppSpacing.xl,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildMessageContent(context, isDark,
                  message.isDeletedForEveryone, message.reactions.isNotEmpty),
              if (message.reactions.isNotEmpty) ...[
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: _ReactionsDisplay(
                    reactions: message.reactions,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!animateEntrance) {
      return content;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.entranceDuration,
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
      child: content,
    );
  }
}

class _ReactionsDisplay extends StatefulWidget {
  final Map<String, String> reactions;
  final bool isDark;

  const _ReactionsDisplay({required this.reactions, required this.isDark});

  @override
  State<_ReactionsDisplay> createState() => _ReactionsDisplayState();
}

class _ReactionsDisplayState extends State<_ReactionsDisplay>
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

/// Image bubble supporting local offline caching and progressive Drive download.
class _ImageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool isDark;
  final Function(String localPath)? onDownloaded;

  const _ImageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
    this.onDownloaded,
  });

  @override
  State<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<_ImageBubble> {
  bool _isDownloading = false;
  double? _progress;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _localPath = widget.message.localPath;
    if (_localPath == null || _localPath!.isEmpty) {
      final syncHit = MediaCacheService.instance.getCachedPathSync(
        url: widget.message.fileUrl ?? '',
        driveFileId: widget.message.driveFileId,
      );
      if (syncHit != null) {
        _localPath = syncHit;
      }
    }
    _checkCacheAndAutoDownload();
  }

  void _checkCacheAndAutoDownload() async {
    if (_localPath != null && File(_localPath!).existsSync()) return;
    final url = widget.message.fileUrl;
    if (url == null || url.isEmpty) return;

    final cached = await MediaCacheService.instance.getCachedFilePath(
      url: url,
      fileName: widget.message.fileName ?? 'image.jpg',
      driveFileId: widget.message.driveFileId,
    );
    if (cached != null && mounted) {
      setState(() => _localPath = cached);
      widget.onDownloaded?.call(cached);
      return;
    }

    _startDownload();
  }

  Future<void> _startDownload() async {
    final url = widget.message.fileUrl;
    if (url == null || url.isEmpty) return;
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    final downloaded = await MediaCacheService.instance.downloadFile(
      url: url,
      fileName: widget.message.fileName ?? 'image.jpg',
      driveFileId: widget.message.driveFileId,
      onProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() => _progress = received / total);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        if (downloaded != null) {
          _localPath = downloaded;
        }
      });
      if (downloaded != null) {
        widget.onDownloaded?.call(downloaded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final cacheDim = (220 * pixelRatio).round().clamp(220, 800);

    final isDownloaded = _localPath != null && File(_localPath!).existsSync();
    final isUploading = widget.message.status == 'uploading' ||
        (widget.isMe &&
            (widget.message.fileUrl == null ||
                widget.message.fileUrl!.isEmpty) &&
            widget.message.status != 'failed');
    final isFailed = widget.message.status == 'failed';
    final directUrl = UserAvatar.formatDirectImageUrl(widget.message.fileUrl);

    if (isUploading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 220,
          height: 220,
          color:
              widget.isDark ? const Color(0xFF1E1E22) : const Color(0xFFE4E4EA),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isDownloaded)
                Image.file(
                  File(_localPath!),
                  cacheWidth: cacheDim,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(
                          radius: 14, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Uploading media...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isFailed) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 220,
          height: 220,
          color:
              widget.isDark ? const Color(0xFF1E1E22) : const Color(0xFFE4E4EA),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isDownloaded)
                Image.file(
                  File(_localPath!),
                  cacheWidth: cacheDim,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              Container(
                color: Colors.black.withValues(alpha: 0.50),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.exclamationmark_circle_fill,
                          color: CupertinoColors.destructiveRed, size: 28),
                      SizedBox(height: 6),
                      Text(
                        'Upload failed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (isDownloaded) {
          OpenFile.open(_localPath!);
        } else {
          _startDownload();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 220,
          height: 220,
          color:
              widget.isDark ? const Color(0xFF1E1E22) : const Color(0xFFE4E4EA),
          child: isDownloaded
              ? Image.file(
                  File(_localPath!),
                  cacheWidth: cacheDim,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => (directUrl.isNotEmpty
                      ? Image.network(
                          directUrl,
                          cacheWidth: cacheDim,
                          fit: BoxFit.cover,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return _buildPlaceholder();
                          },
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder()),
                )
              : (directUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          directUrl,
                          cacheWidth: cacheDim,
                          fit: BoxFit.cover,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return _buildPlaceholder();
                          },
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        ),
                        if (_isDownloading)
                          Container(
                            color: Colors.black.withValues(alpha: 0.35),
                            child: Center(child: _buildDownloadOverlay()),
                          ),
                      ],
                    )
                  : _buildDownloadOverlay()),
        ),
      ),
    );
  }

  Widget _buildDownloadOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading)
            SizedBox(
              width: 38,
              height: 38,
              child: CupertinoActivityIndicator(
                radius: 14,
                color: widget.isMe
                    ? Colors.white
                    : CupertinoTheme.of(context).primaryColor,
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.cloud_download,
                color: Colors.white,
                size: 24,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            _isDownloading
                ? (_progress != null
                    ? '${(_progress! * 100).toInt()}%'
                    : 'Downloading...')
                : (widget.message.fileSize != null
                    ? _formatSize(widget.message.fileSize!)
                    : 'Tap to Download'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isMe
                  ? Colors.white70
                  : AppColors.textSecondary(widget.isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(CupertinoIcons.photo, size: 36, color: Colors.grey),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

/// Document/file bubble supporting local caching, open, and Drive download.
class _FileBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool isDark;
  final Function(String localPath)? onDownloaded;

  const _FileBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
    this.onDownloaded,
  });

  @override
  State<_FileBubble> createState() => _FileBubbleState();
}

class _FileBubbleState extends State<_FileBubble> {
  bool _isDownloading = false;
  double? _progress;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _localPath = widget.message.localPath;
    _checkCache();
  }

  void _checkCache() async {
    if (_localPath != null && File(_localPath!).existsSync()) return;
    final url = widget.message.fileUrl;
    if (url == null || url.isEmpty) return;

    final cached = await MediaCacheService.instance.getCachedFilePath(
      url: url,
      fileName: widget.message.fileName ?? 'file',
      driveFileId: widget.message.driveFileId,
    );
    if (cached != null && mounted) {
      setState(() => _localPath = cached);
      widget.onDownloaded?.call(cached);
    }
  }

  Future<void> _startDownload() async {
    final url = widget.message.fileUrl;
    if (url == null || url.isEmpty) return;
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    final downloaded = await MediaCacheService.instance.downloadFile(
      url: url,
      fileName: widget.message.fileName ?? 'file',
      driveFileId: widget.message.driveFileId,
      onProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() => _progress = received / total);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        if (downloaded != null) {
          _localPath = downloaded;
        }
      });
      if (downloaded != null) {
        widget.onDownloaded?.call(downloaded);
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDownloaded = _localPath != null && File(_localPath!).existsSync();
    final isUploading = widget.message.status == 'uploading' ||
        (widget.isMe &&
            (widget.message.fileUrl == null ||
                widget.message.fileUrl!.isEmpty) &&
            widget.message.status != 'failed');
    final isFailed = widget.message.status == 'failed';
    final fileName = widget.message.fileName ?? 'Document';
    final sizeStr = widget.message.fileSize != null
        ? _formatSize(widget.message.fileSize!)
        : '';

    String statusText;
    if (isUploading) {
      statusText =
          sizeStr.isNotEmpty ? 'Uploading... • $sizeStr' : 'Uploading...';
    } else if (isFailed) {
      statusText =
          sizeStr.isNotEmpty ? 'Upload failed • $sizeStr' : 'Upload failed';
    } else if (_isDownloading) {
      statusText = _progress != null
          ? '${(_progress! * 100).toInt()}% • $sizeStr'
          : 'Downloading...';
    } else if (isDownloaded) {
      statusText = sizeStr.isNotEmpty ? 'Downloaded • $sizeStr' : 'Downloaded';
    } else {
      statusText =
          sizeStr.isNotEmpty ? 'Tap to Download • $sizeStr' : 'Tap to Download';
    }

    final accent = CupertinoTheme.of(context).primaryColor;
    final primaryTextColor = widget.isMe
        ? AppColors.bubbleMeText(widget.isDark)
        : AppColors.textPrimary(widget.isDark);
    final secondaryTextColor = widget.isMe
        ? AppColors.bubbleMeText(widget.isDark).withValues(alpha: 0.72)
        : AppColors.textSecondary(widget.isDark);
    final iconBoxColor = widget.isMe
        ? AppColors.bubbleMeText(widget.isDark).withValues(alpha: 0.18)
        : accent.withValues(alpha: 0.12);
    final iconColor =
        widget.isMe ? AppColors.bubbleMeText(widget.isDark) : accent;

    return GestureDetector(
      onTap: () {
        if (isUploading) return;
        if (isDownloaded) {
          OpenFile.open(_localPath!);
        } else {
          _startDownload();
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.isMe
              ? (widget.isDark
                  ? Colors.black.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.15))
              : (widget.isDark
                  ? const Color(0xFF1E1E22)
                  : const Color(0xFFE4E4EA)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBoxColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.doc_fill,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              CupertinoActivityIndicator(
                  radius: 10, color: widget.isMe ? primaryTextColor : null)
            else if (isFailed)
              const Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 20,
                color: CupertinoColors.destructiveRed,
              )
            else if (_isDownloading)
              CupertinoActivityIndicator(
                  radius: 10, color: widget.isMe ? primaryTextColor : null)
            else if (!isDownloaded)
              Icon(
                CupertinoIcons.arrow_down_circle,
                size: 20,
                color: secondaryTextColor,
              ),
          ],
        ),
      ),
    );
  }
}
