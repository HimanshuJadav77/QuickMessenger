// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:quick_messenger/features/auth/screens/auth_gate_screen.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';

import '../../chat/screens/main_navigation_screen.dart';

/// iOS-native email verification gate.
///
/// Sends the link, polls for verification, then enters [HomeScreen].
class Verification extends StatefulWidget {
  const Verification({super.key});

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  final _auth = FirebaseAuth.instance;
  bool resending = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 1),
      () => _auth.currentUser?.sendEmailVerification(),
    );
    timer =
        Timer.periodic(const Duration(seconds: 2), (_) => checkVerified());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkVerified() async {
    await _auth.currentUser?.reload();
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (verified && mounted) {
      timer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _resend() async {
    setState(() => resending = true);
    try {
      await _auth.currentUser?.sendEmailVerification();
    } finally {
      if (mounted) {
        Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => resending = false);
        });
      }
    }
  }

  Future<void> _cancel() async {
    timer?.cancel();
    try {
      await _auth.currentUser?.delete();
    } catch (_) {}
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const LogReg()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Verify email'),
        automaticallyImplyLeading: false,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.mail,
                size: 72,
                color: CupertinoTheme.of(context).primaryColor,
              ),
              SizedBox(height: AppSpacing.md),
              const Text(
                'Check your inbox',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'A verification link was sent to your email. Tap it, then come back — we\'ll let you in automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
              SizedBox(height: AppSpacing.lg),
              const CupertinoActivityIndicator(),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  resending
                      ? const CupertinoActivityIndicator()
                      : CupertinoButton(
                          onPressed: _resend,
                          child: const Text('Resend link'),
                        ),
                  CupertinoButton(
                    onPressed: _cancel,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: CupertinoColors.systemRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
