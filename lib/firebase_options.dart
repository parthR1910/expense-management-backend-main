import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: "AIzaSyDMA-2P7nFF25qsH3IlwZnvDKocpvpAVZg",
      authDomain: "expensemangementapp.firebaseapp.com",
      projectId: "expensemangementapp",
      storageBucket: "expensemangementapp.firebasestorage.app",
      messagingSenderId: "932920776979",
      appId: "1:932920776979:web:26ca8cebc08ce498af22e6",
    );
  }
}
