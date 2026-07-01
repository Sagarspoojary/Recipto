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
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhtL3HBJ3WiwhTVQET2Qj2S63iYjP51hw',
    appId: '1:15580599771:web:b1d8f92ce3b4f4c37cdab2',
    messagingSenderId: '15580599771',
    projectId: 'recipto-febbf',
    authDomain: 'recipto-febbf.firebaseapp.com',
    storageBucket: 'recipto-febbf.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhtL3HBJ3WiwhTVQET2Qj2S63iYjP51hw',
    appId: '1:15580599771:android:2f0277a121cb6f045a83fe',
    messagingSenderId: '15580599771',
    projectId: 'recipto-febbf',
    storageBucket: 'recipto-febbf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhtL3HBJ3WiwhTVQET2Qj2S63iYjP51hw',
    appId: '1:15580599771:ios:2f0277a121cb6f045a83fe',
    messagingSenderId: '15580599771',
    projectId: 'recipto-febbf',
    storageBucket: 'recipto-febbf.firebasestorage.app',
    iosBundleId: 'com.receipto.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBhtL3HBJ3WiwhTVQET2Qj2S63iYjP51hw',
    appId: '1:15580599771:ios:2f0277a121cb6f045a83fe',
    messagingSenderId: '15580599771',
    projectId: 'recipto-febbf',
    storageBucket: 'recipto-febbf.firebasestorage.app',
    iosBundleId: 'com.receipto.app',
  );
}
