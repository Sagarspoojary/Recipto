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
    apiKey: 'AIzaSyBs9u5EHOqDs2OAFYPrmox0y9gy8uqtnxw',
    appId: '1:556353258296:web:1234567890abcdef',
    messagingSenderId: '556353258296',
    projectId: 'receipto-48592',
    authDomain: 'receipto-48592.firebaseapp.com',
    storageBucket: 'receipto-48592.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBs9u5EHOqDs2OAFYPrmox0y9gy8uqtnxw',
    appId: '1:556353258296:android:71f93228066e3b4f4c37cd',
    messagingSenderId: '556353258296',
    projectId: 'receipto-48592',
    storageBucket: 'receipto-48592.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBs9u5EHOqDs2OAFYPrmox0y9gy8uqtnxw',
    appId: '1:556353258296:ios:abcdef123456',
    messagingSenderId: '556353258296',
    projectId: 'receipto-48592',
    storageBucket: 'receipto-48592.appspot.com',
    iosBundleId: 'com.receipto.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBs9u5EHOqDs2OAFYPrmox0y9gy8uqtnxw',
    appId: '1:556353258296:ios:abcdef123456',
    messagingSenderId: '556353258296',
    projectId: 'receipto-48592',
    storageBucket: 'receipto-48592.appspot.com',
    iosBundleId: 'com.receipto.app',
  );
}
