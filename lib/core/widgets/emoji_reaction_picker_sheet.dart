import 'package:quick_messenger/core/theme/app_typography.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmojiReactionPickerSheet extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final List<Widget> actions;
  final bool showHeader;

  const EmojiReactionPickerSheet({
    super.key,
    required this.onEmojiSelected,
    this.actions = const [],
    this.showHeader = true,
  });

  @override
  State<EmojiReactionPickerSheet> createState() => _EmojiReactionPickerSheetState();
}

class _EmojiReactionPickerSheetState extends State<EmojiReactionPickerSheet> {
  bool _isExpanded = false;

  final List<String> _quickEmojis = ['❤️', '👍', '😂', '😮', '😢', '🙏'];
  final List<String> _allEmojis = [
    '❤️', '👍', '😂', '😮', '😢', '🙏',
    '🥰', '🔥', '👏', '🎉', '🤔', '😭',
    '😡', '👀', '💯', '✨', '🙌', '💔',
    '😎', '😊', '👍🏻', '👍🏽', '👍🏿', '💩',
    '🤡', '👻', '👽', '👾', '🤖', '🎃',
    '👍', '👎', '👊', '✊', '🤛', '🤜',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassFill(isDark),
            border: Border(
              top: BorderSide(
                color: AppColors.glassBorder(isDark),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.showHeader) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ..._quickEmojis.map((emoji) => _buildEmojiButton(emoji)),
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.add_reaction_outlined,
                          color: AppColors.textPrimary(isDark),
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 150,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: _allEmojis.length,
                        itemBuilder: (context, index) {
                          return _buildEmojiButton(_allEmojis[index]);
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              if (widget.actions.isNotEmpty) ...[
                if (widget.showHeader)
                  Divider(color: AppColors.divider(isDark), height: 1),
                ...widget.actions,
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return InkWell(
      onTap: () {
        widget.onEmojiSelected(emoji);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Text(
          emoji,
          style: TextStyle(fontSize: AppTypography.display.fontSize),
        ),
      ),
    );
  }
}

