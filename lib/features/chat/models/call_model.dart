enum CallStatus { calling, ringing, connected, ended }
enum CallType { voice, video }

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String receiverId;
  final String? receiverName;
  final String? receiverAvatar;
  final CallType callType;
  final CallStatus status;
  final String? channelId;
  final String? token;
  final int? remoteUid;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverId,
    this.receiverName,
    this.receiverAvatar,
    required this.callType,
    required this.status,
    this.channelId,
    this.token,
    this.remoteUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      if (receiverName != null) 'receiverName': receiverName,
      if (receiverAvatar != null) 'receiverAvatar': receiverAvatar,
      'callType': callType.name,
      'status': status.name,
      if (channelId != null) 'channelId': channelId,
      if (token != null) 'token': token,
      if (remoteUid != null) 'remoteUid': remoteUid,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerAvatar: map['callerAvatar'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'],
      receiverAvatar: map['receiverAvatar'],
      callType: CallType.values.firstWhere((e) => e.name == map['callType'], orElse: () => CallType.voice),
      status: CallStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => CallStatus.calling),
      channelId: map['channelId'],
      token: map['token'],
      remoteUid: map['remoteUid'] is int
          ? map['remoteUid']
          : (map['remoteUid'] != null ? int.tryParse(map['remoteUid'].toString()) : null),
    );
  }

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    CallType? callType,
    CallStatus? status,
    String? channelId,
    String? token,
    int? remoteUid,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      channelId: channelId ?? this.channelId,
      token: token ?? this.token,
      remoteUid: remoteUid ?? this.remoteUid,
    );
  }
}

