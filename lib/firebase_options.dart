import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBeL1vTcvbLU_fVg0dmmipv9baNxvIdQgA',
    appId: '1:318001829934:ios:dab683c1eacb22059e27bf',
    messagingSenderId: '318001829934',
    projectId: 'pawquest-e08af',
    storageBucket: 'pawquest-e08af.firebasestorage.app',
    iosBundleId: 'com.qianyi.pawquest',
  );

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is only configured for iOS in this build.',
        );
    }
  }
}