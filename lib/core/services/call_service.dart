import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../features/chat/models/call_model.dart';
import 'notification_service.dart';
import 'socket_service.dart';

class CallStats {
  final int currentMonthUsedSeconds;
  final int totalFreeMinutes;

  CallStats({
    required this.currentMonthUsedSeconds,
    this.totalFreeMinutes = 10000,
  });

  double get usedMinutes => currentMonthUsedSeconds / 60.0;
  double get remainingMinutes => (totalFreeMinutes - usedMinutes).clamp(0, totalFreeMinutes.toDouble());
  double get percentageUsed => (usedMinutes / totalFreeMinutes * 100).clamp(0, 100);
}

final callServiceProvider = StateNotifierProvider<CallService, CallModel?>((ref) {
  return CallService(SocketService.instance);
});

final callStatsProvider = FutureProvider<CallStats>((ref) async {
  final callService = ref.watch(callServiceProvider.notifier);
  return callService.getCallStats();
});

class CallService extends StateNotifier<CallModel?> with WidgetsBindingObserver {
  final SocketService _socketService;

  static const String agoraAppId = 'fc8b32bf5a0c426f9e0d0b144aa94a67';

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  bool _isEngineInitialized = false;
  bool get isEngineInitialized => _isEngineInitialized;

  bool _isInChannel = false;
  bool get isInChannel => _isInChannel;

  String? _quotaErrorMessage;
  String? get quotaErrorMessage => _quotaErrorMessage;

  void Function(String message)? onQuotaError;

  Timer? _ringTimeoutTimer;
  DateTime? _connectedTimestamp;

  CallService(this._socketService) : super(null) {
    WidgetsBinding.instance.addObserver(this);
    _initSocketListeners();
    NotificationService.instance.onIncomingCall = (data) {
      handleIncomingCallFromFCM(data);
    };
  }

  void handleIncomingCallFromFCM(Map<String, dynamic> data) {
    debugPrint("[CallService] Incoming call via FCM: $data");
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final callId = data['callId']?.toString() ?? data['channelId']?.toString() ?? '';
    if (currentUid == null || callId.isEmpty) return;

    final callModel = CallModel(
      callId: callId,
      callerId: data['callerId']?.toString() ?? '',
      callerName: data['callerName']?.toString() ?? 'Someone',
      callerAvatar: data['callerImageUrl']?.toString() ?? '',
      receiverId: currentUid,
      channelId: data['channelId']?.toString(),
      token: data['token']?.toString(),
      callType: data['callType'] == 'video' ? CallType.video : CallType.voice,
      status: CallStatus.ringing,
    );

    if (state == null) {
      state = callModel;
      _startRingTimeout(callId);
      _saveCallLog(
        callId: callId,
        targetUserId: currentUid,
        otherUserId: callModel.callerId,
        otherUserName: callModel.callerName,
        otherUserImageUrl: callModel.callerAvatar,
        direction: 'incoming',
        callType: callModel.callType.name,
        status: 'missed',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("[CallService] AppLifecycleState changed to: $state");
    if (state == AppLifecycleState.detached) {
      // App is terminating/closing: immediately disconnect to ensure no background minutes are consumed
      if (this.state != null) {
        endCall(this.state!.callId);
      }
      _cleanupCall();
    } else if (state == AppLifecycleState.paused) {
      // App sent to background: mute video track to conserve bandwidth and quota
      if (this.state != null && this.state!.callType == CallType.video && _isInChannel) {
        _engine?.muteLocalVideoStream(true);
      }
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground: restore video track if in active video call
      if (this.state != null && this.state!.callType == CallType.video && _isInChannel) {
        _engine?.muteLocalVideoStream(false);
      }
    }
  }

  Future<void> _saveCallLog({
    required String callId,
    required String targetUserId,
    required String otherUserId,
    required String otherUserName,
    required String otherUserImageUrl,
    required String direction,
    required String callType,
    required String status,
    int durationSeconds = 0,
  }) async {
    try {
      if (targetUserId.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(targetUserId)
          .collection('call_logs')
          .doc(callId)
          .set({
        'callId': callId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserImageUrl': otherUserImageUrl,
        'direction': direction,
        'callType': callType,
        'status': status,
        'durationSeconds': durationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("[CallService] Error saving call log: $e");
    }
  }

  void _initSocketListeners() {
    _socketService.onCallOffer = (data) async {
      debugPrint("[CallService] onCallOffer: $data");
      final callModel = CallModel.fromMap(data);
      if (state == null && callModel.receiverId == FirebaseAuth.instance.currentUser?.uid) {
        state = callModel.copyWith(status: CallStatus.ringing);
        _startRingTimeout(callModel.callId);

        _saveCallLog(
          callId: callModel.callId,
          targetUserId: callModel.receiverId,
          otherUserId: callModel.callerId,
          otherUserName: callModel.callerName,
          otherUserImageUrl: callModel.callerAvatar,
          direction: 'incoming',
          callType: callModel.callType.name,
          status: 'missed',
        );
      }
    };

    _socketService.onCallTokenReady = (data) async {
      debugPrint("[CallService] onCallTokenReady: $data");
      if (state != null && state!.callId == data['callId']) {
        final channelId = data['channelId']?.toString() ?? state!.channelId;
        final token = data['token']?.toString() ?? state!.token;
        state = state!.copyWith(channelId: channelId, token: token);
      }
    };

    _socketService.onCallAnswer = (data) async {
      debugPrint("[CallService] onCallAnswer: $data");
      if (state != null && state!.callId == data['callId']) {
        _cancelRingTimeout();
        _connectedTimestamp = DateTime.now();
        state = state!.copyWith(status: CallStatus.connected);
        try {
          await WakelockPlus.enable();
        } catch (e) {
          debugPrint("[CallService] Error enabling wakelock: $e");
        }

        _saveCallLog(
          callId: state!.callId,
          targetUserId: state!.callerId,
          otherUserId: state!.receiverId,
          otherUserName: state!.receiverName ?? 'User',
          otherUserImageUrl: state!.receiverAvatar ?? '',
          direction: 'outgoing',
          callType: state!.callType.name,
          status: 'connected',
        );
        _saveCallLog(
          callId: state!.callId,
          targetUserId: state!.receiverId,
          otherUserId: state!.callerId,
          otherUserName: state!.callerName,
          otherUserImageUrl: state!.callerAvatar,
          direction: 'incoming',
          callType: state!.callType.name,
          status: 'connected',
        );

        final channelId = data['channelId']?.toString() ?? state!.channelId;
        final token = data['token']?.toString() ?? state!.token;
        if (channelId != null && token != null) {
          await _joinChannel(
            token: token,
            channelId: channelId,
            isVideo: state!.callType == CallType.video,
          );
        }
      }
    };

    _socketService.onCallRejected = (data) {
      debugPrint("[CallService] onCallRejected: $data");
      if (state != null && state!.callId == data['callId']) {
        _cancelRingTimeout();
        _saveCallLog(
          callId: state!.callId,
          targetUserId: state!.callerId,
          otherUserId: state!.receiverId,
          otherUserName: state!.receiverName ?? 'User',
          otherUserImageUrl: state!.receiverAvatar ?? '',
          direction: 'outgoing',
          callType: state!.callType.name,
          status: 'rejected',
        );
        _cleanupCall();
      }
    };

    _socketService.onCallEnded = (data) {
      debugPrint("[CallService] onCallEnded: $data");
      if (state != null && state!.callId == data['callId']) {
        _cancelRingTimeout();
        final duration = _connectedTimestamp != null
            ? DateTime.now().difference(_connectedTimestamp!).inSeconds
            : (int.tryParse(data['durationSeconds']?.toString() ?? '0') ?? 0);

        _saveCallLog(
          callId: state!.callId,
          targetUserId: state!.callerId,
          otherUserId: state!.receiverId,
          otherUserName: state!.receiverName ?? 'User',
          otherUserImageUrl: state!.receiverAvatar ?? '',
          direction: 'outgoing',
          callType: state!.callType.name,
          status: duration > 0 ? 'completed' : 'unanswered',
          durationSeconds: duration,
        );
        _saveCallLog(
          callId: state!.callId,
          targetUserId: state!.receiverId,
          otherUserId: state!.callerId,
          otherUserName: state!.callerName,
          otherUserImageUrl: state!.callerAvatar,
          direction: 'incoming',
          callType: state!.callType.name,
          status: duration > 0 ? 'completed' : 'missed',
          durationSeconds: duration,
        );

        state = state!.copyWith(status: CallStatus.ended);
        Future.delayed(const Duration(seconds: 1), () {
          _cleanupCall();
        });
      }
    };

    _socketService.onCallError = (data) {
      debugPrint("[CallService] onCallError: $data");
      _cancelRingTimeout();

      final code = data['code']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';
      final nextDate = data['nextAvailableDate']?.toString() ?? '';

      if (code == 'QUOTA_EXCEEDED' || nextDate.isNotEmpty) {
        _quotaErrorMessage = message.isNotEmpty
            ? message
            : 'Calling service is not available until $nextDate.';
        onQuotaError?.call(_quotaErrorMessage!);
      }

      state = state?.copyWith(status: CallStatus.ended);
      Future.delayed(const Duration(milliseconds: 500), () {
        _cleanupCall();
      });
    };
  }

  void _startRingTimeout(String callId) {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(const Duration(seconds: 40), () {
      debugPrint("[CallService] Call $callId timed out (no answer after 40s). Terminating to prevent quota waste.");
      if (state != null && state!.callId == callId && state!.status != CallStatus.connected) {
        if (state!.receiverId == FirebaseAuth.instance.currentUser?.uid) {
          _saveCallLog(
            callId: state!.callId,
            targetUserId: state!.receiverId,
            otherUserId: state!.callerId,
            otherUserName: state!.callerName,
            otherUserImageUrl: state!.callerAvatar,
            direction: 'incoming',
            callType: state!.callType.name,
            status: 'missed',
          );
        }
        endCall(callId);
      }
    });
  }

  void _cancelRingTimeout() {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
  }

  Future<bool> _requestPermissions(CallType callType) async {
    final micStatus = await Permission.microphone.request();
    if (callType == CallType.video) {
      final cameraStatus = await Permission.camera.request();
      return micStatus.isGranted && cameraStatus.isGranted;
    }
    return micStatus.isGranted;
  }

  Future<void> _initEngine(CallType callType) async {
    if (_isEngineInitialized && _engine != null) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("[CallService] Agora joined channel: ${connection.channelId}");
          _isInChannel = true;
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("[CallService] Agora remote user joined: $remoteUid");
          if (state != null) {
            state = state!.copyWith(remoteUid: remoteUid, status: CallStatus.connected);
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("[CallService] Agora remote user offline ($reason): $remoteUid");
          // When remote user closes app or leaves, immediately end call to avoid staying in channel alone
          if (state?.remoteUid == remoteUid) {
            state = state!.copyWith(status: CallStatus.ended);
            Future.delayed(const Duration(seconds: 1), () {
              _cleanupCall();
            });
          }
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("[CallService] Agora error: $err - $msg");
        },
      ),
    );

    if (callType == CallType.video) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.enableAudio();
    }

    _isEngineInitialized = true;
  }

  Future<void> _joinChannel({
    required String token,
    required String channelId,
    required bool isVideo,
  }) async {
    if (_engine == null) return;
    _isInChannel = true;
    await _engine!.joinChannel(
      token: token,
      channelId: channelId,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: isVideo,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideo,
      ),
    );
  }

  Future<String?> checkQuotaAvailability() async {
    final stats = await getCallStats();
    if (stats.currentMonthUsedSeconds >= 10000 * 60) {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextDate = "${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01";
      final msg = "Calling service is not available until $nextDate.";
      _quotaErrorMessage = msg;
      return msg;
    }
    return null;
  }

  Future<String?> initiateCall(CallModel call) async {
    _quotaErrorMessage = null;
    final quotaErr = await checkQuotaAvailability();
    if (quotaErr != null) {
      return quotaErr;
    }

    final granted = await _requestPermissions(call.callType);
    if (!granted) {
      debugPrint("[CallService] Permissions not granted for call");
      return "Permissions required for call.";
    }

    state = call;
    await _initEngine(call.callType);
    _startRingTimeout(call.callId);

    _saveCallLog(
      callId: call.callId,
      targetUserId: call.callerId,
      otherUserId: call.receiverId,
      otherUserName: call.receiverName ?? 'User',
      otherUserImageUrl: call.receiverAvatar ?? '',
      direction: 'outgoing',
      callType: call.callType.name,
      status: 'calling',
    );

    _socketService.emitCallOffer(call.toMap());
    return null;
  }

  Future<void> acceptCall(String callId) async {
    if (state != null && state!.callId == callId) {
      _cancelRingTimeout();
      final granted = await _requestPermissions(state!.callType);
      if (!granted) {
        debugPrint("[CallService] Permissions not granted for acceptCall");
        return;
      }

      await _initEngine(state!.callType);
      _connectedTimestamp = DateTime.now();
      state = state!.copyWith(status: CallStatus.connected);
      try {
        await WakelockPlus.enable();
      } catch (e) {
        debugPrint("[CallService] Error enabling wakelock: $e");
      }

      _saveCallLog(
        callId: state!.callId,
        targetUserId: state!.receiverId,
        otherUserId: state!.callerId,
        otherUserName: state!.callerName,
        otherUserImageUrl: state!.callerAvatar,
        direction: 'incoming',
        callType: state!.callType.name,
        status: 'connected',
      );

      if (state!.token != null && state!.channelId != null) {
        await _joinChannel(
          token: state!.token!,
          channelId: state!.channelId!,
          isVideo: state!.callType == CallType.video,
        );
      }

      _socketService.emitCallAnswer({
        'callId': callId,
        'callerId': state!.callerId,
        'channelId': state!.channelId,
        'token': state!.token,
      });
    }
  }

  void rejectCall(String callId) {
    if (state != null && state!.callId == callId) {
      _cancelRingTimeout();
      _saveCallLog(
        callId: state!.callId,
        targetUserId: state!.receiverId,
        otherUserId: state!.callerId,
        otherUserName: state!.callerName,
        otherUserImageUrl: state!.callerAvatar,
        direction: 'incoming',
        callType: state!.callType.name,
        status: 'rejected',
      );
      _socketService.emitCallRejected({'callId': callId, 'callerId': state!.callerId});
      _cleanupCall();
    }
  }

  void endCall(String callId) {
    if (state != null && state!.callId == callId) {
      _cancelRingTimeout();
      final duration = _connectedTimestamp != null
          ? DateTime.now().difference(_connectedTimestamp!).inSeconds
          : 0;

      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final isCaller = state!.callerId == currentUid;

      _saveCallLog(
        callId: state!.callId,
        targetUserId: state!.callerId,
        otherUserId: state!.receiverId,
        otherUserName: state!.receiverName ?? 'User',
        otherUserImageUrl: state!.receiverAvatar ?? '',
        direction: 'outgoing',
        callType: state!.callType.name,
        status: duration > 0 ? 'completed' : 'unanswered',
        durationSeconds: duration,
      );
      _saveCallLog(
        callId: state!.callId,
        targetUserId: state!.receiverId,
        otherUserId: state!.callerId,
        otherUserName: state!.callerName,
        otherUserImageUrl: state!.callerAvatar,
        direction: 'incoming',
        callType: state!.callType.name,
        status: duration > 0 ? 'completed' : (isCaller ? 'missed' : 'rejected'),
        durationSeconds: duration,
      );

      final targetId = isCaller ? state!.receiverId : state!.callerId;
      _socketService.emitCallEnded({
        'callId': callId,
        'receiverId': targetId,
        'callerId': state!.callerId,
        'durationSeconds': duration,
      });

      state = state!.copyWith(status: CallStatus.ended);
      Future.delayed(const Duration(seconds: 1), () {
        _cleanupCall();
      });
    }
  }

  Future<void> toggleMute(bool isMuted) async {
    await _engine?.muteLocalAudioStream(isMuted);
  }

  Future<void> toggleVideo(bool isVideoOn) async {
    if (isVideoOn) {
      await _engine?.enableLocalVideo(true);
      await _engine?.muteLocalVideoStream(false);
    } else {
      await _engine?.muteLocalVideoStream(true);
      await _engine?.enableLocalVideo(false);
    }
  }

  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    await _engine?.setEnableSpeakerphone(isSpeakerOn);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> _recordCallDuration(int seconds) async {
    if (seconds <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final key = 'agora_call_seconds_${now.year}_${now.month}';
      final current = prefs.getInt(key) ?? 0;
      final updated = current + seconds;
      await prefs.setInt(key, updated);
      final minutesUsed = (updated / 60).toStringAsFixed(1);
      final remaining = (10000 - (updated / 60)).toStringAsFixed(1);
      debugPrint("[CallService] ⏱️ Call finished (${seconds}s). Monthly Agora usage: $minutesUsed min / 10,000 min (Remaining: $remaining min)");
    } catch (e) {
      debugPrint("[CallService] Error saving call stats: $e");
    }
  }

  Future<CallStats> getCallStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final key = 'agora_call_seconds_${now.year}_${now.month}';
      final seconds = prefs.getInt(key) ?? 0;
      return CallStats(currentMonthUsedSeconds: seconds);
    } catch (_) {
      return CallStats(currentMonthUsedSeconds: 0);
    }
  }

  Future<void> _cleanupCall() async {
    _cancelRingTimeout();

    if (_connectedTimestamp != null) {
      final duration = DateTime.now().difference(_connectedTimestamp!).inSeconds;
      _recordCallDuration(duration);
      _connectedTimestamp = null;
    }

    try {
      if (_isInChannel) {
        await _engine?.leaveChannel();
      }
      await _engine?.stopPreview();
      await _engine?.release();
    } catch (e) {
      debugPrint("[CallService] Error during engine cleanup: $e");
    }

    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint("[CallService] Error disabling wakelock: $e");
    }

    _engine = null;
    _isEngineInitialized = false;
    _isInChannel = false;
    if (mounted) state = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupCall();
    super.dispose();
  }
}

