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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7pLZ-QAhDXtUnlH3v1n7ErKzGfWnWrYs',
    appId: '1:341897916087:android:87c19d339eb64eab61a732',
    messagingSenderId: '341897916087',
    projectId: 'tapa-budget-6ed7c',
    storageBucket: 'tapa-budget-6ed7c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7pLZ-QAhDXtUnlH3v1n7ErKzGfWnWrYs',
    appId: '1:341897916087:ios:87c19d339eb64eab61a732',
    messagingSenderId: '341897916087',
    projectId: 'tapa-budget-6ed7c',
    storageBucket: 'tapa-budget-6ed7c.firebasestorage.app',
    iosBundleId: 'com.example.tapa1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB7pLZ-QAhDXtUnlH3v1n7ErKzGfWnWrYs',
    appId: '1:341897916087:ios:87c19d339eb64eab61a732',
    messagingSenderId: '341897916087',
    projectId: 'tapa-budget-6ed7c',
    storageBucket: 'tapa-budget-6ed7c.firebasestorage.app',
    iosBundleId: 'com.example.tapa1',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7pLZ-QAhDXtUnlH3v1n7ErKzGfWnWrYs',
    appId: '1:341897916087:web:87c19d339eb64eab61a732',
    messagingSenderId: '341897916087',
    projectId: 'tapa-budget-6ed7c',
    authDomain: 'tapa-budget-6ed7c.firebaseapp.com',
    storageBucket: 'tapa-budget-6ed7c.firebasestorage.app',
  );
}
