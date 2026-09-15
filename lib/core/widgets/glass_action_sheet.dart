import 'dart:ui' as dart_ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Divider;
import 'package:flutter/services.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';

class LGActionSheetAction {
  final String title;
  final IconData? icon;
  final bool isDestructive;
  final bool isDefault;
  final Widget? trailing;
  final VoidCallback onPressed;

  const LGActionSheetAction({
    required this.title,
    this.icon,
    this.isDestructive = false,
    this.isDefault = false,
    this.trailing,
    required this.onPressed,
  });
}

// Backwards-compatible alias
typedef GlassActionSheetAction = LGActionSheetAction;
typedef GlassActionSheet = LGActionSheet;

/// WhatsApp iOS Liquid Glass Action Sheet.
///
/// Features:
/// - Compact proportions (46px item height, constrained max-width 420px)
/// - Strictly leading-aligned icons with fixed 28x28 container and baseline alignment
/// - Clean 15pt medium typography (no oversized fonts)
/// - Authentic iOS blur (sigma 24) and specular glass border
/// - Support for custom headers (e.g. tapback emoji bar)
/// - Built-in confirmation sheet helper
class LGActionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    Widget? customHeader,
    required List<LGActionSheetAction> actions,
    String cancelTitle = 'Cancel',
    VoidCallback? onCancel,
  }) {
    HapticFeedback.lightImpact();
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final hasIcons = actions.any((a) => a.icon != null);

    return showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Main Action Card (Frosted Glass) ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: dart_ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xE8222226)
                                : const Color(0xF4F7F7F8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Custom header (e.g. tapbacks)
                              if (customHeader != null) ...[
                                customHeader,
                                Divider(
                                  height: 0.5,
                                  thickness: 0.5,
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ] else if (title != null || message != null) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (title != null)
                                        Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted(isDark),
                                          ),
                                        ),
                                      if (title != null && message != null)
                                        const SizedBox(height: 3),
                                      if (message != null)
                                        Text(
                                          message,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted(isDark),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 0.5,
                                  thickness: 0.5,
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ],

                              // Action list
                              for (int i = 0; i < actions.length; i++) ...[
                                _ActionItem(
                                  action: actions[i],
                                  hasIcons: hasIcons,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    actions[i].onPressed();
                                  },
                                ),
                                if (i < actions.length - 1)
                                  Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                    indent: hasIcons ? 56 : 16,
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Cancel Capsule (Frosted Glass) ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: dart_ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xE8222226)
                                : const Color(0xF4F7F7F8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.5,
                            ),
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              onCancel?.call();
                            },
                            child: Text(
                              cancelTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Compact iOS confirmation action sheet (for Delete, Leave, Block actions)
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmTitle,
    bool isDestructive = true,
    required VoidCallback onConfirm,
    String cancelTitle = 'Cancel',
  }) {
    return show<bool>(
      context: context,
      title: title,
      message: message,
      actions: [
        LGActionSheetAction(
          title: confirmTitle,
          isDestructive: isDestructive,
          isDefault: !isDestructive,
          onPressed: onConfirm,
        ),
      ],
      cancelTitle: cancelTitle,
    );
  }
}

class _ActionItem extends StatelessWidget {
  final LGActionSheetAction action;
  final bool hasIcons;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionItem({
    required this.action,
    required this.hasIcons,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = action.isDestructive
        ? CupertinoColors.destructiveRed
        : (isDark ? CupertinoColors.white : CupertinoColors.black);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (hasIcons) ...[
              SizedBox(
                width: 28,
                height: 28,
                child: action.icon != null
                    ? Center(
                        child: Icon(
                          action.icon,
                          size: 20,
                          color: textColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                action.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: action.isDefault
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action.trailing != null) action.trailing!,
          ],
        ),
      ),
    );
  }
}


