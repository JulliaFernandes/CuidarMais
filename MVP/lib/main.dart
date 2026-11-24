import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sem internet ou sem Firebase, o app abre mesmo assim, só com as contas
  // de demonstração.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase indisponível: $e');
  }
  runApp(CuidarMaisApp(useFirebase: firebaseReady));
}
