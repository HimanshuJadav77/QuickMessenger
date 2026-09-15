import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/theme/app_typography.dart';
import 'package:quick_messenger/features/auth/screens/auth_gate_screen.dart';

import '../../chat/screens/main_navigation_screen.dart';

/// iOS-native splash: centered logo, Cupertino activity indicator,
/// navigates with [CupertinoPageRoute] (swipe-back ready).
class Splash extends StatefulWidget {
  const Splash({super.key, this.snapshot});

  // ignore: prefer_typing_uninitialized_variables
  final snapshot;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    checkUser();
  }

  void checkUser() {
    Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;
        final bool loggedIn = widget.snapshot?.hasData == true;
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) =>
                loggedIn ? const HomeScreen() : const LogReg(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: Image.asset("assets/images/logo.png"),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            "QuickMessenger",
            style: AppTypography.title.copyWith(
              fontFamily: ".SF Pro Display",
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          CupertinoActivityIndicator(
            color: AppColors.textMuted(isDark),
          ),
        ],
      ),
    );
  }
}