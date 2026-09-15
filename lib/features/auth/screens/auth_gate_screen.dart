import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_messenger/features/auth/screens/register_screen.dart';
import 'package:quick_messenger/core/utils/networkcheck.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'login_screen.dart';

/// iOS-native welcome gate: brand hero + Sign Up / Log In.
///
/// No gradients — clean system background, accent-filled primary action.
class LogReg extends StatefulWidget {
  const LogReg({super.key});

  @override
  State<LogReg> createState() => _LogRegState();
}

class _LogRegState extends State<LogReg> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void dispose() {
    NetworkCheck().cancelSubscription();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background(isDark),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: accent.withValues(alpha: 0.12),
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset("assets/images/logo.png"),
              ),
              SizedBox(height: AppSpacing.md),
              const Text(
                "QuickMessenger",
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                "Message friends and family — fast, private, local-first.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => const Register()),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: accent.withValues(alpha: 0.12),
                  onPressed: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const Login()),
                  ),
                  child: Text(
                    'Log In',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
