import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
        apiKey: "AIzaSyBjTJ3Dwi4iFEA70sfVX9gH3CCPzytgbrA",
        authDomain: "ai-powered-notes-scanner.firebaseapp.com",
        databaseURL:
            "https://ai-powered-notes-scanner-default-rtdb.firebaseio.com",
        projectId: "ai-powered-notes-scanner",
        storageBucket: "ai-powered-notes-scanner.firebasestorage.app",
        messagingSenderId: "304723757911",
        appId: "1:304723757911:web:acd2e3545fb3a98cfccc12",
        measurementId: "G-XY30BL94NZ");
  }
}
