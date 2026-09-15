import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material, CircleAvatar, Divider;
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class LGContextMenuItem {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const LGContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// WhatsApp iOS Liquid Glass Peek-and-Pop Context Menu.
///
/// Features:
/// - Blurred full-screen backdrop
/// - Floating chat conversation preview card with wallpaper and bubbles
/// - Sleek frosted glass action list below preview (Mark as unread, Archive, Mute, Lock, Delete, etc.)
void showLGContextMenu({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String imageUrl,
  required List<LGContextMenuItem> items,
  String? lastMessage,
  String? timestamp,
}) {
  HapticFeedback.mediumImpact();
  final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
  final accent = CupertinoTheme.of(context).primaryColor;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.40),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (ctx, anim, secondaryAnim, _) {
      final curvedAnim = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(ctx),
            child: Center(
              child: SingleChildScrollView(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.90, end: 1.0).animate(curvedAnim),
                  child: FadeTransition(
                    opacity: anim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Floating Chat Preview Card ──
                          Container(
                            width: 310,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: isDark ? const Color(0xE6141416) : const Color(0xF2FFFFFF),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : Colors.black.withValues(alpha: 0.10),
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                children: [
                                  // Mini Preview Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(alpha: 0.03),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.10)
                                              : Colors.black.withValues(alpha: 0.06),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: accent.withValues(alpha: 0.2),
                                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                          child: imageUrl.isEmpty
                                              ? Text(
                                                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: accent,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColors.textPrimary(isDark),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (timestamp != null)
                                          Text(
                                            timestamp,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted(isDark),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Mini preview body
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      color: isDark ? const Color(0xFF0C0C0E) : const Color(0xFFEFEFF4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.08)
                                                  : Colors.black.withValues(alpha: 0.06),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "🔒 Messages are end-to-end encrypted",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted(isDark),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF26262A) : Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Text(
                                                lastMessage != null && lastMessage.isNotEmpty
                                                    ? lastMessage
                                                    : subtitle,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary(isDark),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Mini Input footer
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    color: isDark ? const Color(0xFF161618) : Colors.white,
                                    child: Row(
                                      children: [
                                        Icon(CupertinoIcons.add, size: 18, color: AppColors.textMuted(isDark)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF26262A) : const Color(0xFFF0F0F2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(CupertinoIcons.mic, size: 18, color: AppColors.textMuted(isDark)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Liquid Glass Context Menu Card ──
                          Container(
                            width: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: isDark ? const Color(0xCC242428) : const Color(0xECF8F8FC),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(items.length, (index) {
                                  final item = items[index];
                                  final isLast = index == items.length - 1;

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          Navigator.pop(ctx);
                                          item.onTap();
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              item.icon,
                                              size: 20,
                                              color: item.isDestructive
                                                  ? CupertinoColors.systemRed
                                                  : AppColors.textPrimary(isDark),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                item.label,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: item.isDestructive
                                                      ? CupertinoColors.systemRed
                                                      : AppColors.textPrimary(isDark),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 0.5,
                                          thickness: 0.5,
                                          indent: 48,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.10)
                                              : Colors.black.withValues(alpha: 0.08),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class LGContextMenuRegion extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<LGContextMenuItem> items;
  final String? lastMessage;
  final String? timestamp;

  const LGContextMenuRegion({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.items,
    this.lastMessage,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        showLGContextMenu(
          context: context,
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
          items: items,
          lastMessage: lastMessage,
          timestamp: timestamp,
        );
      },
      child: child,
    );
  }
}
