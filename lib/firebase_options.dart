// lib/firebase_options.dart
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
    apiKey: 'AIzaSyAyaGnNyc2tfV8hoQ6Pr4VM25iinM70AUM',
    appId: '1:557234773917:web:23702e6673d73d58835974',
    messagingSenderId: '557234773917',
    projectId: 'chat00-7f1b1',
    authDomain: 'chat00-7f1b1.firebaseapp.com',
    storageBucket: 'chat00-7f1b1.appspot.com',
    measurementId: 'G-ZZKGKF1QN5',
    databaseURL: 'https://chat00-7f1b1-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyaGnNyc2tfV8hoQ6Pr4VM25iinM70AUM',
    appId: '1:557234773917:android:XXXXXXXXXXXXXXXX',
    messagingSenderId: '557234773917',
    projectId: 'chat00-7f1b1',
    storageBucket: 'chat00-7f1b1.appspot.com',
    databaseURL: 'https://chat00-7f1b1-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAyaGnNyc2tfV8hoQ6Pr4VM25iinM70AUM',
    appId: '1:557234773917:ios:XXXXXXXXXXXXXXXX',
    messagingSenderId: '557234773917',
    projectId: 'chat00-7f1b1',
    storageBucket: 'chat00-7f1b1.appspot.com',
    databaseURL: 'https://chat00-7f1b1-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.cashnet',
  );
}