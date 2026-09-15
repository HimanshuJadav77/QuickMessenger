import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_messenger/features/auth/screens/login_screen.dart';
import 'package:quick_messenger/features/auth/screens/verification_screen.dart';
import 'package:quick_messenger/core/widgets/app_snackbar.dart';
import 'package:quick_messenger/core/utils/networkcheck.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// iOS-native Register.
///
/// - [CupertinoPageScaffold], circular photo picker via [CupertinoActionSheet]
/// - Fields in [CupertinoListSection.insetGrouped] with [CupertinoTextField]
/// - Submit via [CupertinoButton.filled], [CupertinoAlertDialog] on errors
/// - Firebase create + Firestore doc logic unchanged.
class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool showPass = false;
  bool showCPass = false;
  bool registering = false;
  File? pickedImage;

  @override
  void initState() {
    super.initState();
    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    NetworkCheck().cancelSubscription();
    super.dispose();
  }

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> register() async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || pickedImage == null) return;
      final uploadTask =
          _storage.ref("UsersImage").child(user.uid).putFile(pickedImage!);
      final taskSnapshot = await uploadTask;
      final imageurl = await taskSnapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
        "username": usernameController.text.trim(),
        "email": emailController.text.trim(),
        "userimageurl": imageurl,
        "userid": user.uid,
        "about": "",
        "online": false
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const Verification()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnackBar(context, e.message ?? e.toString());
    } finally {
      if (mounted) setState(() => registering = false);
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .where("username", isEqualTo: username)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error checking username: $e");
      return false;
    }
  }

  void _showPhotoPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Profile photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final photo = await ImagePicker()
                    .pickImage(source: ImageSource.camera);
                if (photo != null && mounted) {
                  setState(() => pickedImage = File(photo.path));
                }
              } catch (e) {
                if (mounted) showSnackBar(context, "$e");
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 22),
                SizedBox(width: 10),
                Text('Take photo'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final photo = await ImagePicker()
                    .pickImage(source: ImageSource.gallery);
                if (photo != null && mounted) {
                  setState(() => pickedImage = File(photo.path));
                }
              } catch (e) {
                if (mounted) showSnackBar(context, "$e");
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 22),
                SizedBox(width: 10),
                Text('Choose from library'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showError(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passController.text.isEmpty ||
        confirmPassController.text.isEmpty) {
      showSnackBar(context, 'Please fill all fields.');
      return;
    }
    if (passController.text != confirmPassController.text) {
      showSnackBar(context, 'Passwords do not match.');
      return;
    }
    if (passController.text.length < 6) {
      showSnackBar(context, 'Password must be at least 6 characters.');
      return;
    }
    if (pickedImage == null) {
      showSnackBar(context, 'Please select a profile photo.');
      return;
    }
    setState(() => registering = true);
    final exists =
        await checkUsernameExists(usernameController.text.trim());
    if (!mounted) return;
    if (exists) {
      setState(() => registering = false);
      _showError('Sign up', 'Username already exists.');
    } else {
      await register();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sign Up'),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.md),
          children: [
            // Photo picker
            Center(
              child: GestureDetector(
                onTap: _showPhotoPicker,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    image: pickedImage != null
                        ? DecorationImage(
                            image: FileImage(pickedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: AppColors.divider(isDark),
                      width: 0.5,
                    ),
                  ),
                  child: pickedImage == null
                      ? Icon(
                          CupertinoIcons.person_fill,
                          size: 54,
                          color: AppColors.textMuted(isDark),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'Add photo',
                style: TextStyle(color: accent, fontSize: 15),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            CupertinoListSection.insetGrouped(
              backgroundColor: AppColors.background(isDark),
              margin: EdgeInsets.zero,
              children: [
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: usernameController,
                    placeholder: 'Username',
                    textInputAction: TextInputAction.next,
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.person, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: null,
                  ),
                ),
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: emailController,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.mail, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: null,
                  ),
                ),
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: passController,
                    placeholder: 'Password',
                    obscureText: !showPass,
                    textInputAction: TextInputAction.next,
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.lock, size: 20),
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () =>
                          setState(() => showPass = !showPass),
                      child: Icon(
                        showPass
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        size: 20,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: null,
                  ),
                ),
                CupertinoListTile(
                  title: CupertinoTextField(
                    controller: confirmPassController,
                    placeholder: 'Confirm password',
                    obscureText: !showCPass,
                    textInputAction: TextInputAction.done,
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child:
                          Icon(CupertinoIcons.lock_fill, size: 20),
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () =>
                          setState(() => showCPass = !showCPass),
                      child: Icon(
                        showCPass
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        size: 20,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: null,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            registering
                ? const Center(child: CupertinoActivityIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _submit,
                      child: const Text('Sign Up'),
                    ),
                  ),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(
                      color: AppColors.textSecondary(isDark)),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(builder: (_) => const Login()),
                  ),
                  child: Text(
                    'Log In',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: accent,
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
