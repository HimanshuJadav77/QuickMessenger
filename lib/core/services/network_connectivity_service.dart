import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final connectivityProvider = StreamProvider<InternetStatus>((ref) {
  return InternetConnection().onStatusChange;
});

// We keep a dummy service so existing code calling NetworkConnectivityService.instance.initializeInternetStatus(context) doesn't break,
// but we do nothing in it to avoid the Snackbar.
class NetworkConnectivityService {
  static final NetworkConnectivityService instance = NetworkConnectivityService._internal();

  NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => instance;

  void initializeInternetStatus(dynamic context) {
    // No-op: Internet status is now handled reactively via Riverpod (connectivityProvider).
  }

  void cancelSubscription() {
    // No-op
  }
}

