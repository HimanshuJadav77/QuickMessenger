// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/features/profile/screens/profile_screen.dart';
import 'package:quick_messenger/features/profile/screens/user_profile_screen.dart';

/// iOS-native followers / following with segmented control.
class FollowFollowingPage extends StatefulWidget {
  const FollowFollowingPage({super.key, required this.userid});

  final userid;

  @override
  State<FollowFollowingPage> createState() => _FollowFollowingPageState();
}

class _FollowFollowingPageState extends State<FollowFollowingPage> {
  final _firestore = FirebaseFirestore.instance;
  int _segment = 0;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accent = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('People'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CupertinoSegmentedControl<int>(
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Text('Followers'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Text('Following'),
                  ),
                },
                groupValue: _segment,
                selectedColor: accent,
                unselectedColor:
                    AppColors.surfaceContainer(isDark),
                borderColor: AppColors.divider(isDark),
                pressedColor:
                    accent.withValues(alpha: 0.2),
                onValueChanged: (v) =>
                    setState(() => _segment = v),
              ),
            ),
            Expanded(
              child: _segment == 0
                  ? _UserList(
                      stream: _firestore
                          .collection("Users")
                          .doc(widget.userid)
                          .collection("followers")
                          .where("follower", isEqualTo: true)
                          .snapshots(),
                      emptyText: 'No followers yet',
                      isDark: isDark,
                      currentUserId: currentUserId,
                    )
                  : _UserList(
                      stream: _firestore
                          .collection("Users")
                          .doc(widget.userid)
                          .collection("following")
                          .where("following", isEqualTo: true)
                          .snapshots(),
                      emptyText: 'Not following anyone yet',
                      isDark: isDark,
                      currentUserId: currentUserId,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyText;
  final bool isDark;
  final String currentUserId;

  const _UserList({
    required this.stream,
    required this.emptyText,
    required this.isDark,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CupertinoActivityIndicator());
        }
        final ids = snapshot.data?.docs ?? [];
        if (ids.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style:
                  TextStyle(color: AppColors.textMuted(isDark)),
            ),
          );
        }

        return CupertinoListSection.insetGrouped(
          backgroundColor: AppColors.background(isDark),
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          children: ids.map((doc) {
            final otherId = doc.id;
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(otherId)
                  .get(),
              builder: (context, userSnap) {
                final data = userSnap.data?.data();
                if (data == null) {
                  return const SizedBox(
                    height: 56,
                    child: Center(
                        child: CupertinoActivityIndicator(
                            radius: 10)),
                  );
                }
                final username =
                    (data["username"] ?? 'User').toString();
                final imageUrl =
                    (data["userimageurl"] ?? '').toString();

                return CupertinoListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: imageUrl.isEmpty
                          ? accent.withValues(alpha: 0.15)
                          : null,
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? Center(
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          )
                        : null,
                  ),
                  title: Text(otherId == currentUserId
                      ? '$username (you)'
                      : username),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    if (otherId == currentUserId) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const MyProfile()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => SearchUserProfile(
                            username: data["username"],
                            email: data["email"],
                            about: data["about"],
                            imageurl: data["userimageurl"],
                            userid: otherId,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
