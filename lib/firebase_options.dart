// File generated to match the QR Cafe Firebase project.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlSd1gYDWP7XvsW9ELG8ecgnmYhDOuWq8',
    appId: '1:932259613195:web:72c84386ba71b8b179d50e',
    messagingSenderId: '932259613195',
    projectId: 'saas-5116b',
    authDomain: 'saas-5116b.firebaseapp.com',
    storageBucket: 'saas-5116b.firebasestorage.app',
    measurementId: 'G-58KMNZMES4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9V6zVS3NT6QpAcro6id436YGix2i8eY4',
    appId: '1:932259613195:android:20b6287dd6be29af79d50e',
    messagingSenderId: '932259613195',
    projectId: 'saas-5116b',
    storageBucket: 'saas-5116b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAm2SE1FAbNtU9YhKVe2YTgJhoqw_Cc_S4',
    appId: '1:932259613195:ios:182360efb0182e3c79d50e',
    messagingSenderId: '932259613195',
    projectId: 'saas-5116b',
    storageBucket: 'saas-5116b.firebasestorage.app',
    iosBundleId: 'com.qrcafe.customerApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAm2SE1FAbNtU9YhKVe2YTgJhoqw_Cc_S4',
    appId: '1:932259613195:ios:182360efb0182e3c79d50e',
    messagingSenderId: '932259613195',
    projectId: 'saas-5116b',
    storageBucket: 'saas-5116b.firebasestorage.app',
    iosBundleId: 'com.qrcafe.customerApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBlSd1gYDWP7XvsW9ELG8ecgnmYhDOuWq8',
    appId: '1:932259613195:web:677f106b2dc9b9ca79d50e',
    messagingSenderId: '932259613195',
    projectId: 'saas-5116b',
    authDomain: 'saas-5116b.firebaseapp.com',
    storageBucket: 'saas-5116b.firebasestorage.app',
    measurementId: 'G-TTTCD6Y16H',
  );
}
