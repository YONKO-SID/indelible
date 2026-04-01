// =============================================================================
// APP.DART — The root MaterialApp widget.
//
// WHY SEPARATE FROM MAIN.DART?
// main.dart handles initialization (Firebase, etc.)
// app.dart handles the VISUAL configuration (theme, routing, etc.)
//
// This separation means:
//   - main.dart is about SETUP (Firebase, analytics, crash reporting)
//   - app.dart is about DISPLAY (theme, what screen to show first)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

class IndelibleApp extends StatelessWidget {
  const IndelibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indelible',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorSchemeSeed: const Color(0xFF00D4FF), // INDELIBLE brand cyan
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      // ── Auth-Aware Home Screen ──
      // Check if user is already signed in from a previous session.
      // FirebaseAuth persists login state — if you signed in yesterday
      // and didn't sign out, currentUser will still be set today.
      home: FirebaseAuth.instance.currentUser != null
          ? DashboardScreen()
          : const LoginScreen(),
    );
  }
}
