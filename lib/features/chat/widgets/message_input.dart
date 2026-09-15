import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/liquid_glass_container.dart';

/// iOS-native message composer (iMessage pattern).
///
/// - Single attach button (leading) + expanding [CupertinoTextField].
/// - Send arrow morphs in with spring when text is non-empty.
/// - All taps use [CupertinoButton] (opacity press) + haptics — no Material
///   ripple, no gradients, accent comes from [CupertinoTheme].
class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback? onAttach;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      level: 2,
      customRadius: BorderRadius.circular(28),
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (onAttach != null) ...[
              _buildActionIconButton(
                context: context,
                icon: CupertinoIcons.paperclip,
                onTap: onAttach!,
                semanticLabel: 'Attach file',
              ),
              SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: _MessageTextField(
                controller: controller,
                onChanged: onChanged,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            // iMessage-style send morph: arrow appears only with text.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                return AnimatedSwitcher(
                  duration: AppMotion.microStandard,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack),
                    child: FadeTransition(
                        opacity: animation, child: child),
                  ),
                  child: hasText
                      ? Padding(
                          key: const ValueKey('send_btn'),
                          padding: EdgeInsets.only(
                              right: AppSpacing.xs,
                              bottom: AppSpacing.xs),
                          child: _SendButton(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onSend();
                            },
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('empty_space'),
                          width: 8,
                          height: 36),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: CupertinoButton(
        padding: EdgeInsets.all(AppSpacing.xs),
        borderRadius: BorderRadius.circular(24),
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Icon(
          icon,
          color: CupertinoTheme.of(context).primaryColor,
          size: 24,
        ),
      ),
    );
  }
}

class _MessageTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _MessageTextField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    return CupertinoTextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      maxLines: 4,
      minLines: 1,
      placeholder: 'Message',
      placeholderStyle: TextStyle(
        color: AppColors.textMuted(isDark),
        fontSize: 16,
      ),
      style: TextStyle(
        color: AppColors.textPrimary(isDark),
        fontSize: 16,
        height: 1.4,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer(isDark).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      cursorColor: CupertinoTheme.of(context).primaryColor,
    );
  }
}

/// Flat-accent circular send arrow (iMessage). Scales down on press.
class _SendButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SendButton({
    required this.onTap,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Send message',
      button: true,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.arrow_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}