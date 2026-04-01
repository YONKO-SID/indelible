// =============================================================================
// MAIN.DART — The app's entry point.
//
// WHY IS FIREBASE INITIALIZED HERE?
// Firebase.initializeApp() MUST run before ANY Firebase service is used.
// It connects your app to the Firebase project (reads google-services.json
// on Android or GoogleService-Info.plist on iOS).
//
// WidgetsFlutterBinding.ensureInitialized() is required because
// Firebase.initializeApp() is async, and you can't call async code
// before Flutter's binding is ready.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/app.dart';

void main() async {
  // Step 1: Tell Flutter "I need to do async work before runApp()"
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Initialize Firebase WITH your project's config
  // DefaultFirebaseOptions.currentPlatform auto-selects the right config
  // (web, android, or ios) based on which platform you're running on.
  // WITHOUT this, web gets a blank screen because it can't find your project.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Step 3: Run the app
  runApp(const IndelibleApp());
}
