import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/user_avatar.dart';
import '../models/call_model.dart';
import '../../../core/services/call_service.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = true;

  Timer? _callTimer;
  int _callDurationSeconds = 0;

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSecs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSecs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final call = ref.watch(callServiceProvider);
    final callNotifier = ref.watch(callServiceProvider.notifier);

    final quotaError = callNotifier.quotaErrorMessage;

    if (call == null || quotaError != null) {
      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (quotaError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.systemYellow.withValues(alpha: 0.16),
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: CupertinoColors.systemYellow,
                      size: 44,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Service Unavailable',
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.textPrimary(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    quotaError,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(12),
                    child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ] else ...[
                  Text(
                    'Call Ended',
                    style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary(isDark)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (call.status == CallStatus.connected && _callTimer == null) {
      _startTimer();
    } else if (call.status == CallStatus.ended) {
      _callTimer?.cancel();
    }

    final isVideoCall = call.callType == CallType.video;
    final engine = callNotifier.engine;
    final hasRemoteVideo = isVideoCall && call.status == CallStatus.connected && call.remoteUid != null && engine != null;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isCaller = call.callerId == currentUserId;
    final displayName = isCaller
        ? (call.receiverName?.isNotEmpty == true ? call.receiverName! : 'Calling...')
        : call.callerName;
    final displayAvatar = isCaller ? (call.receiverAvatar ?? '') : call.callerAvatar;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.background(isDark),
        ),
        child: Stack(
          children: [
            // Remote Video Background (when available)
            if (hasRemoteVideo)
              Positioned.fill(
                child: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: engine,
                    canvas: VideoCanvas(uid: call.remoteUid!),
                    connection: RtcConnection(channelId: call.channelId),
                  ),
                ),
              )
            // Or full-screen local preview if video call is ongoing but remote user hasn't rendered yet
            else if (isVideoCall && engine != null && _isVideoOn)
              Positioned.fill(
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),

            // Local Video Preview (Picture-in-Picture)
            if (isVideoCall && engine != null && _isVideoOn)
              Positioned(
                top: 60,
                right: 16,
                width: 110,
                height: 155,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),

            // UI Overlay
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(CupertinoIcons.chevron_down, color: AppColors.textPrimary(isDark), size: AppSpacing.xl),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Row(
                          children: [
                            Icon(CupertinoIcons.lock, color: AppColors.textSecondary(isDark), size: AppSpacing.xs),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'End-to-end Encrypted',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary(isDark)),
                            ),
                          ],
                        ),
                        SizedBox(width: AppSpacing.xl),
                      ],
                    ),
                  ),

                  // Caller / Receiver Info (Shown when not in full-screen remote video)
                  if (!hasRemoteVideo)
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: call.status == CallStatus.ringing ? 0.3 : 0.1,
                                ),
                              ),
                            ),
                            UserAvatar(
                              imageUrl: displayAvatar,
                              username: displayName,
                              radius: 60,
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          displayName,
                          style: AppTypography.display.copyWith(color: AppColors.textPrimary(isDark)),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          _getStatusText(call.status),
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary(isDark)),
                        ),
                      ],
                    )
                  else
                    const Spacer(),

                  // Bottom Controls inside SafeArea
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: LiquidGlassContainer(
                      customRadius: BorderRadius.circular(28),
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // In-call control buttons row
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildControlButton(
                                  icon: _isMuted ? CupertinoIcons.mic_slash : CupertinoIcons.mic,
                                  label: _isMuted ? 'Unmute' : 'Mute',
                                  isActive: _isMuted,
                                  onTap: () {
                                    setState(() => _isMuted = !_isMuted);
                                    callNotifier.toggleMute(_isMuted);
                                  },
                                  isDark: isDark,
                                ),
                                if (isVideoCall) ...[
                                  _buildControlButton(
                                    icon: _isVideoOn ? CupertinoIcons.video_camera : CupertinoIcons.video_camera_solid,
                                    label: _isVideoOn ? 'Camera' : 'Camera Off',
                                    isActive: !_isVideoOn,
                                    onTap: () {
                                      setState(() => _isVideoOn = !_isVideoOn);
                                      callNotifier.toggleVideo(_isVideoOn);
                                    },
                                    isDark: isDark,
                                  ),
                                  _buildControlButton(
                                    icon: CupertinoIcons.switch_camera,
                                    label: 'Flip',
                                    isActive: false,
                                    onTap: () => callNotifier.switchCamera(),
                                    isDark: isDark,
                                  ),
                                ],
                                _buildControlButton(
                                  icon: _isSpeakerOn ? CupertinoIcons.volume_up : CupertinoIcons.volume_down,
                                  label: 'Speaker',
                                  isActive: _isSpeakerOn,
                                  onTap: () {
                                    setState(() => _isSpeakerOn = !_isSpeakerOn);
                                    callNotifier.toggleSpeaker(_isSpeakerOn);
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          // Prominent Centered Red End Call Button
                          _buildEndCallButton(
                            onTap: () {
                              callNotifier.endCall(call.callId);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return _formatDuration(_callDurationSeconds);
      case CallStatus.ended:
        return 'Call Ended';
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.textPrimary(isDark) : AppColors.glassFill(isDark),
              border: Border.all(
                color: isActive ? Colors.transparent : AppColors.glassBorder(isDark),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? AppColors.background(isDark) : AppColors.textPrimary(isDark),
                size: 22,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndCallButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.error,
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            CupertinoIcons.phone_down_fill,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
