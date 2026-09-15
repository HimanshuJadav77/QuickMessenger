import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:quick_messenger/core/widgets/app_dialogs.dart';

bool connectedToInternet = false;

class NetworkCheck {
  static final NetworkCheck _instance = NetworkCheck._internal();
  factory NetworkCheck() => _instance;
  NetworkCheck._internal();

  StreamSubscription<InternetStatus>? internetConnectionCheck;

  void initializeInternetStatus(BuildContext context) {
    internetConnectionCheck?.cancel();
    internetConnectionCheck = InternetConnection().onStatusChange.listen(
      (event) {
        switch (event) {
          case InternetStatus.connected:
            connectedToInternet = true;
            break;
          case InternetStatus.disconnected:
            connectedToInternet = false;
            if (context.mounted) {
              showCustomDialog(
                  "Network", "You are not connected to Internet!", context);
            }
            break;
        }
      },
    );
  }

  void cancelSubscription() {
    internetConnectionCheck?.cancel();
    internetConnectionCheck = null;
  }
}
