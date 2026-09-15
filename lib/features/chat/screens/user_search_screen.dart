import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/features/profile/screens/user_profile_screen.dart';
import 'package:quick_messenger/core/utils/networkcheck.dart';

/// iOS-native user search.
///
/// [CupertinoSearchTextField] with debounce, results in
/// [CupertinoListSection] rows (avatar, name, chevron). Blocked-by-them
/// users are filtered out. Opens [SearchUserProfile] via [CupertinoPageRoute].
class SearchUser extends ConsumerStatefulWidget {
  const SearchUser({super.key});

  @override
  ConsumerState<SearchUser> createState() => _SearchUserState();
}

class _SearchUserState extends ConsumerState<SearchUser> {
  final searchC = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void dispose() {
    searchC.dispose();
    _debounce?.cancel();
    NetworkCheck().cancelSubscription();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(currentUserIdProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('New Chat'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs,
                  AppSpacing.md, AppSpacing.xs),
              child: CupertinoSearchTextField(
                controller: searchC,
                placeholder: 'Search by username',
                onChanged: _onChanged,
                onSuffixTap: () {
                  searchC.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.person_2,
                              size: 48,
                              color: AppColors.textMuted(isDark)),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Type a username to search',
                            style: TextStyle(
                                color:
                                    AppColors.textSecondary(isDark)),
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection("Users")
                          .where("username", isGreaterThanOrEqualTo: _query)
                          .where("username", isLessThan: '$_query\uf8ff')
                          .limit(20)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CupertinoActivityIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Something went wrong',
                              style: TextStyle(
                                  color: AppColors.textSecondary(
                                      isDark)),
                            ),
                          );
                        }

                        final queryLower = _query.toLowerCase();
                        final users = (snapshot.data?.docs ?? [])
                            .where((doc) {
                          final data = doc.data();
                          final username = (data["username"] ?? '')
                              .toString()
                              .toLowerCase()
                              .replaceAll(RegExp(r'\s+'), '');
                          final uid =
                              (data["userid"] ?? '').toString();
                          return uid.isNotEmpty &&
                              uid != currentUserId &&
                              username.contains(queryLower);
                        }).toList();

                        if (users.isEmpty) {
                          return Center(
                            child: Text(
                              'No users found for "$_query"',
                              style: TextStyle(
                                  color: AppColors.textMuted(isDark)),
                            ),
                          );
                        }

                        return CupertinoListSection.insetGrouped(
                          backgroundColor:
                              AppColors.background(isDark),
                          margin: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          children: users.map((doc) {
                            final data = doc.data();
                            final username =
                                (data["username"] ?? 'User')
                                    .toString();
                            final imageUrl =
                                (data["userimageurl"] ?? '')
                                    .toString();
                            final uid =
                                (data["userid"] ?? '').toString();

                            return StreamBuilder<
                                DocumentSnapshot<
                                    Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection("block")
                                  .doc(uid)
                                  .collection("blockedid")
                                  .doc(currentUserId)
                                  .snapshots(),
                              builder: (context, bSnap) {
                                if (bSnap.connectionState ==
                                        ConnectionState.waiting ||
                                    !bSnap.hasData) {
                                  return const SizedBox.shrink();
                                }
                                if (bSnap.data?.data()?["blocked"] ==
                                    true) {
                                  return const SizedBox.shrink();
                                }
                                return CupertinoListTile(
                                  leading: _SearchAvatar(
                                      imageUrl: imageUrl,
                                      username: username),
                                  title: Text(username),
                                  subtitle: Text(
                                    '@${username.toLowerCase().replaceAll(RegExp(r'\s+'), '')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing:
                                      const CupertinoListTileChevron(),
                                  onTap: () => Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (_) =>
                                          SearchUserProfile(
                                        username: data["username"],
                                        email: data["email"],
                                        about: data["about"],
                                        imageurl:
                                            data["userimageurl"],
                                        userid: uid,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAvatar extends StatelessWidget {
  final String imageUrl;
  final String username;

  const _SearchAvatar({required this.imageUrl, required this.username});

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            imageUrl.isEmpty ? accent.withValues(alpha: 0.15) : null,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            )
          : null,
    );
  }
}
