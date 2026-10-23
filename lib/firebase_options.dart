
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAhS0C0qDHKQ_tdp9W8cn8jZ7Cq7XWoYxs',
    appId: '1:958070133795:web:1d2144fe2fd0ca8bf64d96',
    messagingSenderId: '958070133795',
    projectId: 'nearhelp-413c8',
    authDomain: 'nearhelp-413c8.firebaseapp.com',
    storageBucket: 'nearhelp-413c8.firebasestorage.app',
    measurementId: 'G-5DF6PDN1RQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCuHHTKOSH3kdCVWp6MbR52upEvdi8QSY',
    appId: '1:958070133795:android:96079f35b2266d63f64d96',
    messagingSenderId: '958070133795',
    projectId: 'nearhelp-413c8',
    storageBucket: 'nearhelp-413c8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB_nUksg-CVPLRMORqoK6bQeadD0xaFybA',
    appId: '1:958070133795:ios:f952fc23810b651cf64d96',
    messagingSenderId: '958070133795',
    projectId: 'nearhelp-413c8',
    storageBucket: 'nearhelp-413c8.firebasestorage.app',
    iosBundleId: 'com.example.nearHelp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB_nUksg-CVPLRMORqoK6bQeadD0xaFybA',
    appId: '1:958070133795:ios:f952fc23810b651cf64d96',
    messagingSenderId: '958070133795',
    projectId: 'nearhelp-413c8',
    storageBucket: 'nearhelp-413c8.firebasestorage.app',
    iosBundleId: 'com.example.nearHelp',
  );
}
