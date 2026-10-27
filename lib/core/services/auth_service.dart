import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quick_messenger/core/database/local_database_helper.dart';
import 'package:quick_messenger/core/services/drive_service.dart';
import 'package:quick_messenger/core/services/socket_service.dart';

/// Central authentication service managing Google Sign-In with Google Drive scopes,
/// Firebase Auth credential exchange, and Firestore profile synchronization.
class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in with Google (including drive.file scope configured in DriveService).
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleSignIn = DriveService.instance.googleSignIn;
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('Users').doc(user.uid);
        final snapshot = await userDocRef.get();

        final username = user.displayName ??
            (user.email != null ? user.email!.split('@').first : 'User');
        final email = user.email ?? '';
        final imageUrl = user.photoURL ?? '';

        if (!snapshot.exists) {
          await userDocRef.set({
            'userid': user.uid,
            'username': username,
            'username_lower': username.toLowerCase(),
            'email': email,
            'imageurl': imageUrl,
            'about': 'Hey there! I am using QuickMessenger.',
            'online': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final data = snapshot.data();
          final updates = <String, dynamic>{'online': true};
          if (data?['username_lower'] == null) {
            updates['username_lower'] =
                (data?['username'] ?? username).toString().toLowerCase();
          }
          if (user.photoURL != null &&
              (data?['imageurl'] == null ||
                  (data?['imageurl'] as String).isEmpty)) {
            updates['imageurl'] = user.photoURL!;
          }
          await userDocRef.update(updates);
        }

        // Cache own profile in local database
        LocalDatabaseHelper.instance.upsertUserProfile(user.uid, user.uid, {
          'username': username,
          'display_name': username,
          'email': email,
          'image_url': imageUrl,
          'about': 'Hey there! I am using QuickMessenger.',
        }).ignore();

        // Initialize Drive folder in background
        DriveService.instance.getOrCreateAppFolder().ignore();
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Complete sign out: sets user offline in Firestore, disconnects Socket.IO,
  /// signs out of Google and Firebase.
  Future<void> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('Users').doc(uid).update({
          'online': false,
        });
      }
      SocketService.instance.disconnect();
      await DriveService.instance.googleSignIn.signOut();
      await _auth.signOut();
    } catch (_) {}
  }
}
