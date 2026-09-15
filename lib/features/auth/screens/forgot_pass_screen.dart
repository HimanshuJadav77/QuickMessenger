// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_snackbar.dart';

/// iOS-native forgot password.
class Forgotpass extends StatefulWidget {
  const Forgotpass({super.key});

  @override
  State<Forgotpass> createState() => _ForgotpassState();
}

class _ForgotpassState extends State<Forgotpass> {
  final emailController = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showSnackBar(context, 'Enter your email first.');
      return;
    }
    setState(() => sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emailController.clear();
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Reset email sent'),
          content: const Text(
              'Check your mail app for the reset link.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnackBar(context, e.message ?? e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Reset Password'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Enter your account email and we\'ll send you a reset link.',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            SizedBox(height: AppSpacing.md),
            CupertinoListSection.insetGrouped(
              backgroundColor: AppColors.background(isDark),
              margin: EdgeInsets.zero,
              children: [
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: emailController,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.mail, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: null,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            sending
                ? const Center(child: CupertinoActivityIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _send,
                      child: const Text('Send reset link'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
