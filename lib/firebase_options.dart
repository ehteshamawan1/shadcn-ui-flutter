// File generated manually for Firebase configuration
// Project: ska-dan-app
//
// To regenerate, run: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'this app does not support iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'this app does not support macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'this app does not support Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'this app does not support Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Android configuration (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPtYMoKSTNsC78ah3ZwzP-AwipQAajgVw',
    appId: '1:413383556944:android:c4af8520328a079a99f655',
    messagingSenderId: '413383556944',
    projectId: 'ska-dan-app',
    storageBucket: 'ska-dan-app.firebasestorage.app',
  );

  // Web configuration (from Firebase Console)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBFc9L4gHexaFoyrSKF9VXuttTKnaXZP88',
    appId: '1:413383556944:web:dc7c67305b223b5299f655',
    messagingSenderId: '413383556944',
    projectId: 'ska-dan-app',
    authDomain: 'ska-dan-app.firebaseapp.com',
    storageBucket: 'ska-dan-app.firebasestorage.app',
    measurementId: 'G-41LY3M5LYK',
  );
}
