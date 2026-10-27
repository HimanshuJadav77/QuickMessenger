import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_messenger/core/database/local_database_helper.dart';
import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/features/chat/screens/chat_screen.dart';
import 'package:quick_messenger/features/profile/screens/user_profile_screen.dart';
import 'package:quick_messenger/core/utils/networkcheck.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';

/// iOS-native user search.
///
/// Fast, case-insensitive search supporting usernames, display names, and emails.
/// Uses a local SQLite cache-first approach to minimize Firestore reads.
class SearchUser extends ConsumerStatefulWidget {
  const SearchUser({super.key});

  @override
  ConsumerState<SearchUser> createState() => _SearchUserState();
}

class _SearchUserState extends ConsumerState<SearchUser> {
  final TextEditingController searchC = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    NetworkCheck().initializeInternetStatus(context);
    _loadInitialCachedUsers();
  }

  @override
  void dispose() {
    searchC.dispose();
    _debounce?.cancel();
    NetworkCheck().cancelSubscription();
    super.dispose();
  }

  Future<void> _loadInitialCachedUsers() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId.isEmpty) return;
    final cached = await LocalDatabaseHelper.instance
        .getAllCachedUserProfiles(currentUserId);
    if (mounted && _query.isEmpty && cached.isNotEmpty) {
      setState(() {
        _results = cached;
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _isLoading = false;
      });
      _loadInitialCachedUsers();
      return;
    }

    setState(() {
      _query = trimmed;
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId.isEmpty) return;

    final qLower = query.toLowerCase();

    // 1. Immediately search local SQLite cache for instant zero-latency feedback
    final localMatches = await LocalDatabaseHelper.instance
        .searchCachedUserProfiles(currentUserId, query);
    if (mounted && _query == query && localMatches.isNotEmpty) {
      setState(() {
        _results = localMatches;
      });
    }

    // 2. Fetch from Firestore using serverAndCache to minimize billable reads
    try {
      final snap = await FirebaseFirestore.instance
          .collection("Users")
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));

      final List<Map<String, dynamic>> remoteMatches = [];

      for (final doc in snap.docs) {
        final d = doc.data();
        final uid = (d['userid'] ?? d['uid'] ?? doc.id).toString();
        if (uid.isEmpty || uid == currentUserId) continue;

        final username = (d['username'] ?? 'User').toString();
        final email = (d['email'] ?? '').toString();
        final about =
            (d['about'] ?? 'Hey there! I am using QuickMessenger.').toString();
        final imageUrl =
            (d['imageurl'] ?? d['userimageurl'] ?? d['photoUrl'] ?? '')
                .toString();

        // Cache in SQLite for future instant lookup
        await LocalDatabaseHelper.instance
            .upsertUserProfile(currentUserId, uid, {
          'username': username,
          'display_name': username,
          'email': email,
          'image_url': imageUrl,
          'about': about,
        });

        // Case-insensitive substring match
        final uLower = username.toLowerCase();
        final eLower = email.toLowerCase();
        if (uLower.contains(qLower) || eLower.contains(qLower)) {
          remoteMatches.add({
            'uid': uid,
            'username': username,
            'email': email,
            'about': about,
            'image_url': imageUrl,
          });
        }
      }

      if (mounted && _query == query) {
        setState(() {
          _results = remoteMatches;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && _query == query) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('New Chat'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
              child: CupertinoSearchTextField(
                controller: searchC,
                placeholder: 'Search by username or email',
                onChanged: _onChanged,
                onSuffixTap: () {
                  searchC.clear();
                  _onChanged('');
                },
              ),
            ),
            Expanded(
              child: _buildBody(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading && _results.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_query.isEmpty && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_2,
                size: 48, color: AppColors.textMuted(isDark)),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Type a username or email to search',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ],
        ),
      );
    }

    if (_query.isNotEmpty && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search,
                size: 48, color: AppColors.textMuted(isDark)),
            SizedBox(height: AppSpacing.sm),
            Text(
              'No users found for "$_query"',
              style: TextStyle(color: AppColors.textMuted(isDark)),
            ),
          ],
        ),
      );
    }

    return CupertinoListSection.insetGrouped(
      backgroundColor: AppColors.background(isDark),
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      header: _query.isEmpty
          ? const Text('Suggested Contacts')
          : Text('Search Results (${_results.length})'),
      children: _results.map((user) {
        final username =
            (user['username'] ?? user['display_name'] ?? 'User').toString();
        final imageUrl = (user['image_url'] ??
                user['userimageurl'] ??
                user['imageurl'] ??
                '')
            .toString();
        final email = (user['email'] ?? '').toString();
        final about = (user['about'] ?? '').toString();
        final uid = (user['uid'] ?? user['userid'] ?? '').toString();

        return CupertinoListTile(
          padding: AppSpacing.listTilePadding,
          leadingSize: AppSpacing.listTileLeadingSize,
          leadingToTitle: AppSpacing.listTileLeadingToTitle,
          leading: UserAvatar(
            username: username,
            seed: uid,
            imageUrl: imageUrl,
            radius: AppAvatarSize.listTile,
          ),
          title: Text(
            username,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            email.isNotEmpty
                ? email
                : '@${username.toLowerCase().replaceAll(RegExp(r'\s+'), '')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => ChatScreen(
                        participantId: uid,
                        participantName: username,
                        participantImageUrl: imageUrl,
                        participantEmail: email,
                        participantAbout: about,
                      ),
                    ),
                  );
                },
                child: Icon(
                  CupertinoIcons.chat_bubble_fill,
                  size: 20,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(width: 4),
              const CupertinoListTileChevron(),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => SearchUserProfile(
                  username: username,
                  email: email,
                  about: about,
                  imageurl: imageUrl,
                  userid: uid,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
