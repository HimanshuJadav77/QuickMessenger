import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// WhatsApp iOS Liquid Glass Gradient Avatar.
///
/// Features:
/// - Deterministic vibrant gradient background based on username hash
/// - Bold first letter with drop shadow if no image is available
/// - Specular liquid glass rim border and subtle elevation shadow
/// - Automatic fallback if network image fails
/// - Optional online status badge
class UserAvatar extends ConsumerWidget {
  final String username;
  final String? seed;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final String? heroTag;
  final bool showOnlineBadge;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.username,
    this.seed,
    this.imageUrl,
    this.radius = 24.0,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.heroTag,
    this.showOnlineBadge = false,
    this.isOnline = false,
    this.onTap,
  });

  static const List<List<Color>> _gradientPalettes = [
    [Color(0xFF8A3FFC), Color(0xFF5B1DA8)], // Vivid Purple
    [Color(0xFF0F62FE), Color(0xFF002D9C)], // Royal Blue
    [Color(0xFF0072C3), Color(0xFF004380)], // Electric Azure
    [Color(0xFF009D9A), Color(0xFF004D4B)], // Jade Teal
    [Color(0xFF198038), Color(0xFF084B1E)], // Forest Green
    [Color(0xFFEE5396), Color(0xFF8C1448)], // Hot Magenta
    [Color(0xFFFF832B), Color(0xFFA63C00)], // Vivid Tangerine
    [Color(0xFFFA4D56), Color(0xFF9E1018)], // Crimson Scarlet
    [Color(0xFF6741D9), Color(0xFF381A99)], // Deep Violet
    [Color(0xFF0891B2), Color(0xFF0E5366)], // Ocean Cyan
    [Color(0xFF16A34A), Color(0xFF0B5825)], // Emerald Grass
    [Color(0xFFD97706), Color(0xFF78350F)], // Warm Amber
    [Color(0xFFDC2626), Color(0xFF7F1D1D)], // Ruby Red
    [Color(0xFFDB2777), Color(0xFF831843)], // Rose Blush
    [Color(0xFF4F46E5), Color(0xFF26207A)], // Deep Indigo
    [Color(0xFF0D9488), Color(0xFF064E48)], // Turquoise Sea
    [Color(0xFF65A30D), Color(0xFF365314)], // Lime Olive
    [Color(0xFFEA580C), Color(0xFF7C2D12)], // Spiced Pumpkin
    [Color(0xFF9333EA), Color(0xFF49127E)], // Amethyst Purple
    [Color(0xFF2563EB), Color(0xFF133682)], // Cobalt Blue
    [Color(0xFF059669), Color(0xFF024630)], // Deep Mint
    [Color(0xFFE11D48), Color(0xFF750E24)], // Cerise Wine
    [Color(0xFF7C3AED), Color(0xFF3B157D)], // Cyber Lavender
    [Color(0xFF0284C7), Color(0xFF034E75)], // Sky Blue
  ];

  List<Color> _getGradient(String key) {
    if (key.isEmpty) return _gradientPalettes[0];
    int hash = 5381;
    for (int i = 0; i < key.length; i++) {
      hash = ((hash << 5) + hash) + key.codeUnitAt(i);
    }
    final index = hash.abs() % _gradientPalettes.length;
    return _gradientPalettes[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final name = username.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hashKey = (seed != null && seed!.isNotEmpty)
        ? '$seed-$name'
        : (name.isNotEmpty ? name : 'user');
    final colors = _getGradient(hashKey);
    final size = radius * 2;
    final calcFontSize = fontSize ?? (radius * 0.72);

    final textChild = Center(
      child: Text(
        initial,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: calcFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );

    Widget avatarCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: backgroundColor != null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? colors[0]).withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => textChild,
              )
            : textChild,
      ),
    );

    if (showOnlineBadge) {
      avatarCore = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCore,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF25D366) // WhatsApp Green
                    : const Color(0xFF8E8E93),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      avatarCore = Hero(tag: heroTag!, child: avatarCore);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarCore);
    }

    return avatarCore;
  }
}

