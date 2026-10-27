/// Application configuration constants.
///
/// In production, these values should be loaded from environment variables
/// or a secure config service, not hardcoded.
class AppConfig {
  AppConfig._();

  /// Agora App ID for voice/video calling.
  /// In production, load from environment variable or secure config service.
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: 'fc8b32bf5a0c426f9e0d0b144aa94a67',
  );

  /// Socket.IO server URL.
  static const String socketServerUrl = String.fromEnvironment(
    'SOCKET_SERVER_URL',
    defaultValue: 'https://quickmessengerserver.onrender.com',
  );

  /// Maximum monthly Agora usage in seconds (10,000 minutes).
  static const int maxMonthlyAgoraSeconds = 10000 * 60;

  /// Maximum call ring timeout in seconds.
  static const int callRingTimeoutSeconds = 40;

  /// Default call timeout for ring timeout.
  static const Duration callRingTimeout = Duration(seconds: 40);

  /// Message search debounce duration.
  static const Duration searchDebounce = Duration(milliseconds: 400);

  /// Maximum file upload size in bytes (10MB).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Maximum number of group members.
  static const int maxGroupMembers = 100;

  /// Message pagination limit.
  static const int messagesPageSize = 50;
}
