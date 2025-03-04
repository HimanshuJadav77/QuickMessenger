// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCJE-vEPbeXt46Lxiwq7DSVY9xF3lbp2ys',
    appId: '1:85470283732:web:73efafb6380d1fb76e7841',
    messagingSenderId: '85470283732',
    projectId: 'it-material-point-2b732',
    authDomain: 'it-material-point-2b732.firebaseapp.com',
    storageBucket: 'it-material-point-2b732.appspot.com',
    measurementId: 'G-EFNL7K4NFD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDU7-ZtGb3AMynKUCeeO9rJGtSZ3bQ-gSE',
    appId: '1:85470283732:android:cccab8536cb8cdbe6e7841',
    messagingSenderId: '85470283732',
    projectId: 'it-material-point-2b732',
    storageBucket: 'it-material-point-2b732.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRp4gnvag_0kMq3QCYriN1UqJkANW8FpY',
    appId: '1:85470283732:ios:cfac1089ca6860b66e7841',
    messagingSenderId: '85470283732',
    projectId: 'it-material-point-2b732',
    storageBucket: 'it-material-point-2b732.appspot.com',
    androidClientId: '85470283732-bjr456hcaccp6v59foq5lr9ab8hjmpap.apps.googleusercontent.com',
    iosClientId: '85470283732-paivjb9fhraqusspb3d448av5u4gcukj.apps.googleusercontent.com',
    iosBundleId: 'com.example.quickmsg',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCRp4gnvag_0kMq3QCYriN1UqJkANW8FpY',
    appId: '1:85470283732:ios:cfac1089ca6860b66e7841',
    messagingSenderId: '85470283732',
    projectId: 'it-material-point-2b732',
    storageBucket: 'it-material-point-2b732.appspot.com',
    androidClientId: '85470283732-bjr456hcaccp6v59foq5lr9ab8hjmpap.apps.googleusercontent.com',
    iosClientId: '85470283732-paivjb9fhraqusspb3d448av5u4gcukj.apps.googleusercontent.com',
    iosBundleId: 'com.example.quickmsg',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCJE-vEPbeXt46Lxiwq7DSVY9xF3lbp2ys',
    appId: '1:85470283732:web:b6b76accd5ec2b8f6e7841',
    messagingSenderId: '85470283732',
    projectId: 'it-material-point-2b732',
    authDomain: 'it-material-point-2b732.firebaseapp.com',
    storageBucket: 'it-material-point-2b732.appspot.com',
    measurementId: 'G-CBWJNZPP41',
  );

}