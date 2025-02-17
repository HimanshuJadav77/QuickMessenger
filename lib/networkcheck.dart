import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';

bool connectedToInternet = false;

class NetworkCheck {
  StreamSubscription<InternetStatus>? internetConnectionCheck;

  initializeInternetStatus(BuildContext context) {
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
          default:
            connectedToInternet = false;
            break;
        }
      },
    );
  }

  cancelSubscription() {
    internetConnectionCheck?.cancel();
  }
}
