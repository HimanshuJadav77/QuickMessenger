import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/services/call_service.dart';
import '../../../core/services/navigation_service.dart';
import '../models/call_model.dart';
import '../screens/call_screen.dart';

class IncomingCallDialog extends ConsumerWidget {
  const IncomingCallDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callServiceProvider);
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    if (call == null || call.status != CallStatus.ringing) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: LiquidGlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      imageUrl: call.callerAvatar,
                      username: call.callerName,
                      radius: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.callerName,
                            style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary(isDark)),
                          ),
                          Text(
                            'Incoming ${call.callType.name} call...',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary(isDark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: CupertinoIcons.phone_down_fill,
                      color: AppColors.error,
                      label: 'Decline',
                      onTap: () {
                        ref
                            .read(callServiceProvider.notifier)
                            .rejectCall(call.callId);
                      },
                    ),
                    _buildActionButton(
                      icon: call.callType == CallType.video
                          ? CupertinoIcons.video_camera_solid
                          : CupertinoIcons.phone_fill,
                      color: AppColors.success,
                      label: 'Accept',
                      onTap: () {
                        ref
                            .read(callServiceProvider.notifier)
                            .acceptCall(call.callId);
                        NavigationService.navigatorKey.currentState?.push(
                          CupertinoPageRoute(
                              builder: (_) => const CallScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

