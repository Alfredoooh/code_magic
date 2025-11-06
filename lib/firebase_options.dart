import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyC5U9dqsap6vJY0MF1RWuYMt83b2ezb6t0',
    appId: '1:329928312757:web:dc728da51e4c4cea3abbfc',
    messagingSenderId: '329928312757',
    projectId: 'delta-182c8',
    authDomain: 'delta-182c8.firebaseapp.com',
    storageBucket: 'delta-182c8.firebasestorage.app',
    measurementId: 'G-PCLWXJHCBT',
    databaseURL: 'https://delta-182c8-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLUfbKGwKX0XP8RRTvesa8_9x8zHA9V4A',
    appId: '1:329928312757:android:4b16e327699c41b03abbfc',
    messagingSenderId: '329928312757',
    projectId: 'delta-182c8',
    storageBucket: 'delta-182c8.firebasestorage.app',
    databaseURL: 'https://delta-182c8-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC5U9dqsap6vJY0MF1RWuYMt83b2ezb6t0',
    appId: '1:329928312757:ios:XXXXXXXXXXXXXXXX',
    messagingSenderId: '329928312757',
    projectId: 'delta-182c8',
    storageBucket: 'delta-182c8.firebasestorage.app',
    iosBundleId: 'com.cahsnet.app',
    databaseURL: 'https://delta-182c8-default-rtdb.europe-west1.firebasedatabase.app',
  );
}