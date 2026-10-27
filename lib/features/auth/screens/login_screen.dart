import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:quick_messenger/features/chat/screens/main_navigation_screen.dart';
import 'package:quick_messenger/features/auth/screens/forgot_pass_screen.dart';
import 'package:quick_messenger/features/auth/screens/register_screen.dart';
import 'package:quick_messenger/core/utils/networkcheck.dart';
import 'package:flutter/material.dart' show Colors;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';

/// iOS-native Login.
///
/// - [CupertinoPageScaffold], [CupertinoTextField], [CupertinoButton.filled]
/// - [CupertinoPageRoute] everywhere, [CupertinoAlertDialog] for verification
/// - Firebase email/password logic unchanged.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool showPass = false;
  bool loggingIn = false;

  @override
  void initState() {
    super.initState();
    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    NetworkCheck().cancelSubscription();
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        await user?.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Verify email'),
            content: const Text(
                'Your email is not verified. We sent a verification email — please verify it.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnackBar(context, e.message ?? e.toString());
    } finally {
      if (mounted) setState(() => loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Log in'),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          children: [
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                height: 180,
                child: Image.asset(
                  "assets/images/login.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: -0.5,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to continue chatting with your contacts',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary(isDark),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoListSection.insetGrouped(
              backgroundColor: AppColors.background(isDark),
              margin: EdgeInsets.zero,
              children: [
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: emailController,
                    placeholder: 'Email',
                    placeholderStyle: TextStyle(
                      color: AppColors.textMuted(isDark),
                      fontSize: 16,
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 16,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefix: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        CupertinoIcons.mail,
                        size: 20,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: null,
                  ),
                ),
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: passController,
                    placeholder: 'Password',
                    placeholderStyle: TextStyle(
                      color: AppColors.textMuted(isDark),
                      fontSize: 16,
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 16,
                    ),
                    obscureText: !showPass,
                    textInputAction: TextInputAction.done,
                    prefix: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        CupertinoIcons.lock,
                        size: 20,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => setState(() => showPass = !showPass),
                      child: Icon(
                        showPass
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        size: 20,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: null,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const Forgotpass()),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            loggingIn
                ? const Center(child: CupertinoActivityIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.textPrimary(isDark),
                      onPressed: () {
                        if (emailController.text.trim().isNotEmpty &&
                            passController.text.isNotEmpty) {
                          setState(() => loggingIn = true);
                          login(
                              emailController.text.trim(), passController.text);
                        } else {
                          showSnackBar(context, 'Please fill all fields.');
                        }
                      },
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.onPrimary(isDark),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  onPressed: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const Register()),
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
