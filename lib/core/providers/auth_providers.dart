import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for Firebase auth state.
/// iOS-perfect pattern: UI never reads `FirebaseAuth.instance` directly —
/// always watch these providers so login/logout rebuilds atomically.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current Firebase [User]. Watches [authStateChangesProvider] so it stays
/// fresh across sign-in / sign-out / token refresh.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).valueOrNull ??
      FirebaseAuth.instance.currentUser;
});

/// Current UID, '' when signed out. Prefer watching
/// [currentUserIdStreamProvider] for reactive rebuilds.
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.uid ?? '';
});

/// Reactive UID stream for `ref.watch(...).when()` UI branches.
final currentUserIdStreamProvider =
    StreamProvider<String>((ref) {
  return FirebaseAuth.instance
      .authStateChanges()
      .map((user) => user?.uid ?? '');
});