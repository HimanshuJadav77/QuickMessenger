import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/liquid_glass_app_bar.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/providers/socket_connection_provider.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String username;
  final String imageUrl;
  final String subtitle;
  final String? heroTag;
  final bool isTyping;
  final VoidCallback onBack;
  final VoidCallback? onProfileTap;
  final VoidCallback? onVideoCall;
  final VoidCallback? onVoiceCall;

  const ChatAppBar({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.subtitle,
    this.heroTag,
    this.isTyping = false,
    required this.onBack,
    this.onProfileTap,
    this.onVideoCall,
    this.onVoiceCall,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDarkMode(context);
    final isConnectedAsync = ref.watch(socketConnectionProvider);
    final isConnected =
        isConnectedAsync.value ?? true; // Default to true to prevent flash

    final String displaySubtitle;
    final Color subtitleColor;
    final FontWeight subtitleWeight;

    if (!isConnected) {
      displaySubtitle = 'Connecting...';
      subtitleColor = AppColors.error; // Or a warning color
      subtitleWeight = FontWeight.normal;
    } else if (isTyping) {
      displaySubtitle = 'typing...';
      subtitleColor = AppColors.onlineIndicator;
      subtitleWeight = FontWeight.bold;
    } else {
      displaySubtitle = subtitle;
      subtitleColor = AppColors.textSecondary(isDark);
      subtitleWeight = FontWeight.normal;
    }

    final iconColor = AppColors.textPrimary(isDark);

    return LiquidGlassAppBar(
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onBack,
        child: Icon(CupertinoIcons.back, color: iconColor, size: 24),
      ),
      title: InkWell(
        onTap: onProfileTap,
        child: Row(
          children: [
            UserAvatar(
              username: username,
              imageUrl: imageUrl,
              radius: 18,
              heroTag: heroTag,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    username,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    displaySubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleColor,
                      fontWeight: subtitleWeight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: onVideoCall,
          child: Icon(CupertinoIcons.video_camera, color: iconColor, size: 26),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: onVoiceCall,
          child: Icon(CupertinoIcons.phone, color: iconColor, size: 24),
        ),
      ],
    );
  }
}
