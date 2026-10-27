// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quick_messenger/core/database/local_database_helper.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_snackbar.dart';
import 'package:quick_messenger/core/widgets/glass_action_sheet.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/core/services/avatar_cache_service.dart';
import 'package:quick_messenger/core/services/drive_service.dart';
import 'package:quick_messenger/features/settings/screens/settings_screen.dart';
import 'package:quick_messenger/features/profile/screens/followers_following_screen.dart';

/// iOS-native own profile.
///
/// - [CupertinoPageScaffold] + [CupertinoNavigationBar] (Save/Cancel inline)
/// - Avatar with [CupertinoActionSheet] photo picker (camera / library)
/// - Fields in [CupertinoListSection.insetGrouped], edits via [CupertinoTextField]
/// - Follower/following counts open [FollowFollowingPage] via [CupertinoPageRoute]
/// - Firestore logic unchanged (username uniqueness, image upload, about).
class MyProfile extends ConsumerStatefulWidget {
  const MyProfile({super.key});

  @override
  ConsumerState<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends ConsumerState<MyProfile> {
  File? pickedImage;
  bool modifyUsername = false;
  bool modifyAbout = false;
  bool _isSaving = false;
  final TextEditingController usernameC = TextEditingController();
  final TextEditingController aboutC = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    usernameC.dispose();
    aboutC.dispose();
    super.dispose();
  }

  Future<void> updateProfile(String uid) async {
    if (_isSaving) return;
    final newUsername = usernameC.text.trim();
    final newAbout = aboutC.text.trim();

    if (modifyUsername && newUsername.isEmpty) {
      showSnackBar(context, "Username cannot be empty");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{};

      if (modifyUsername && newUsername.isNotEmpty) {
        final existing = await _firestore
            .collection("Users")
            .where("username", isEqualTo: newUsername)
            .get();
        if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
          showSnackBar(context, "Username already taken");
          return;
        }
        updates["username"] = newUsername;
        updates["username_lower"] = newUsername.toLowerCase();
        try {
          await FirebaseAuth.instance.currentUser
              ?.updateDisplayName(newUsername);
        } catch (_) {}
      }

      if (modifyAbout) {
        updates["about"] = newAbout;
      }

      if (pickedImage != null) {
        String? imageUrl;
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child("profile_images")
              .child("$uid.jpg");
          await ref.putFile(
            pickedImage!,
            SettableMetadata(contentType: "image/jpeg"),
          );
          imageUrl = await ref.getDownloadURL();
        } catch (storageError) {
          debugPrint(
              "[Profile] Firebase Storage failed: $storageError. Trying Drive...");
          final upload = await DriveService.instance.uploadMediaFile(
            file: pickedImage!,
            fileName: "profile_$uid.jpg",
            mimeType: "image/jpeg",
          );
          if (upload != null && upload['driveFileId'] != null) {
            final driveId = upload['driveFileId'] as String;
            imageUrl = 'https://lh3.googleusercontent.com/d/$driveId';
          } else {
            imageUrl = upload?['fileUrl'] as String?;
          }
        }
        if (imageUrl != null && imageUrl.isNotEmpty) {
          updates["userimageurl"] = imageUrl;
          updates["imageurl"] = imageUrl;
          try {
            await FirebaseAuth.instance.currentUser?.updatePhotoURL(imageUrl);
          } catch (_) {}
        } else {
          throw Exception(
              "Failed to upload photo. Please check your network connection and try again.");
        }
      }

      if (updates.isNotEmpty) {
        if (updates.containsKey('userimageurl')) {
          await AvatarCacheService.instance.invalidateUser(uid);
        }
        updates["updatedAt"] = FieldValue.serverTimestamp();
        await _firestore.collection("Users").doc(uid).update(updates);

        // Update local database profile cache immediately
        await LocalDatabaseHelper.instance.upsertUserProfile(uid, uid, {
          if (updates.containsKey('username')) 'username': updates['username'],
          if (updates.containsKey('username'))
            'display_name': updates['username'],
          if (updates.containsKey('about')) 'about': updates['about'],
          if (updates.containsKey('imageurl')) 'image_url': updates['imageurl'],
          'last_updated': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        setState(() {
          pickedImage = null;
          modifyAbout = false;
          modifyUsername = false;
        });
        showSnackBar(context, "Profile updated");
      }
    } on FirebaseException catch (e) {
      if (mounted) showSnackBar(context, e.message ?? e.toString());
    } catch (e) {
      if (mounted) showSnackBar(context, "$e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showPhotoPicker() {
    LGActionSheet.show(
      context: context,
      title: 'Profile Photo',
      actions: [
        LGActionSheetAction(
          title: 'Take Photo',
          icon: CupertinoIcons.camera_fill,
          onPressed: () async {
            try {
              final photo =
                  await ImagePicker().pickImage(source: ImageSource.camera);
              if (photo != null && mounted) {
                setState(() => pickedImage = File(photo.path));
              }
            } catch (e) {
              if (mounted) showSnackBar(context, "$e");
            }
          },
        ),
        LGActionSheetAction(
          title: 'Choose from Library',
          icon: CupertinoIcons.photo_fill,
          onPressed: () async {
            try {
              final photo =
                  await ImagePicker().pickImage(source: ImageSource.gallery);
              if (photo != null && mounted) {
                setState(() => pickedImage = File(photo.path));
              }
            } catch (e) {
              if (mounted) showSnackBar(context, "$e");
            }
          },
        ),
      ],
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;
    final userid = ref.watch(currentUserIdProvider);
    if (userid.isEmpty) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final isEditing = pickedImage != null || modifyAbout || modifyUsername;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection("Users").doc(userid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            !(snapshot.data?.exists ?? false)) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text('Profile')),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final data = snapshot.data!.data()!;
        final username = (data["username"] ?? 'User').toString();
        final imageurl = (data["userimageurl"] ??
                data["imageurl"] ??
                FirebaseAuth.instance.currentUser?.photoURL ??
                '')
            .toString();
        final email =
            (data["email"] ?? FirebaseAuth.instance.currentUser?.email ?? '')
                .toString();
        final about = (data["about"] ?? '').toString();

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('My Profile'),
            leading: CupertinoNavigationBarBackButton(
              onPressed: () => Navigator.pop(context),
            ),
            trailing: isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isSaving
                            ? null
                            : () => setState(() {
                                  pickedImage = null;
                                  modifyAbout = false;
                                  modifyUsername = false;
                                }),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.only(left: 12),
                        onPressed:
                            _isSaving ? null : () => updateProfile(userid),
                        child: _isSaving
                            ? const CupertinoActivityIndicator(radius: 10)
                            : Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                      ),
                    ],
                  )
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      LGActionSheet.show(
                        context: context,
                        actions: [
                          LGActionSheetAction(
                            title: 'Settings & Privacy',
                            icon: CupertinoIcons.settings_solid,
                            onPressed: _openSettings,
                          ),
                        ],
                      );
                    },
                    child: Icon(
                      CupertinoIcons.ellipsis_circle,
                      color: AppColors.textPrimary(isDark),
                    ),
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
              children: [
                SizedBox(height: AppSpacing.md),
                // Avatar + counts
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          UserAvatar(
                            username: username,
                            seed: userid,
                            imageUrl: pickedImage != null
                                ? pickedImage!.path
                                : imageurl,
                            radius: AppAvatarSize.profileHero,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _showPhotoPicker,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                  border: Border.all(
                                    color: AppColors.background(isDark),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.camera_fill,
                                  color: AppColors.onPrimary(isDark, accent),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => FollowFollowingPage(userid: userid),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CountColumn(
                              label: 'Followers',
                              stream: _firestore
                                  .collection("Users")
                                  .doc(userid)
                                  .collection("followers")
                                  .where("follower", isEqualTo: true)
                                  .snapshots(),
                              isDark: isDark,
                            ),
                            _CountColumn(
                              label: 'Following',
                              stream: _firestore
                                  .collection("Users")
                                  .doc(userid)
                                  .collection("following")
                                  .where("following", isEqualTo: true)
                                  .snapshots(),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                // Fields
                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.background(isDark),
                  header: const Text('PROFILE'),
                  children: [
                    CupertinoListTile(
                      leading: Icon(CupertinoIcons.person, color: accent),
                      title: const Text('Username'),
                      subtitle: modifyUsername
                          ? CupertinoTextField(
                              controller: usernameC,
                              autofocus: true,
                              placeholder: username,
                              padding: EdgeInsets.zero,
                              decoration: null,
                            )
                          : Text(username),
                      trailing: modifyUsername
                          ? null
                          : CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(() {
                                modifyUsername = true;
                                usernameC.text = username;
                              }),
                              child: Icon(CupertinoIcons.pencil,
                                  color: accent, size: 20),
                            ),
                    ),
                    CupertinoListTile(
                      leading: Icon(CupertinoIcons.mail, color: accent),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    CupertinoListTile(
                      leading: Icon(CupertinoIcons.info_circle, color: accent),
                      title: const Text('About'),
                      subtitle: modifyAbout
                          ? CupertinoTextField(
                              controller: aboutC,
                              autofocus: true,
                              placeholder: about,
                              padding: EdgeInsets.zero,
                              decoration: null,
                            )
                          : Text(
                              about.isEmpty ? 'Add a bio' : about,
                              style: about.isEmpty
                                  ? TextStyle(
                                      color: AppColors.textMuted(isDark))
                                  : null,
                            ),
                      trailing: modifyAbout
                          ? null
                          : CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(() {
                                modifyAbout = true;
                                aboutC.text = about;
                              }),
                              child: Icon(CupertinoIcons.pencil,
                                  color: accent, size: 20),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountColumn extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final bool isDark;

  const _CountColumn({
    required this.label,
    required this.stream,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            snapshot.connectionState == ConnectionState.waiting
                ? const CupertinoActivityIndicator(radius: 8)
                : Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(isDark),
              ),
            ),
          ],
        );
      },
    );
  }
}
