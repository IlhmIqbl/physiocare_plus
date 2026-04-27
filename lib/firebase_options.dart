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
        throw UnsupportedError('iOS not configured — add GoogleService-Info.plist');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS not configured');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not configured');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCPPrFk9EBelXPVK8QT0vvPA1Mh1fyR97Y',
    authDomain: 'physio-4523e.firebaseapp.com',
    projectId: 'physio-4523e',
    storageBucket: 'physio-4523e.firebasestorage.app',
    messagingSenderId: '781865475170',
    appId: '1:781865475170:web:48313f269d883ab399053b',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCFhGjO8mW-MuAXUWxs9NIgIve7jwkp3Cg',
    appId: '1:781865475170:android:7e151f06ec8826f099053b',
    messagingSenderId: '781865475170',
    projectId: 'physio-4523e',
    storageBucket: 'physio-4523e.firebasestorage.app',
  );
}
