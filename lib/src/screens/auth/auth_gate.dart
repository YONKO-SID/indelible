import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indelible/src/screens/onboarding_screen.dart';
import 'package:indelible/src/screens/login_screen.dart';
import 'package:indelible/src/screens/home_screen.dart';

/// Routing gate that listens to auth state changes.
///
/// Flow:
/// 1. First launch → OnBoardingScreen
/// 2. Logged out → LoginScreen
/// 3. Logged in → HomeScreen
///
/// Uses StreamBuilder to react to login/logout in real-time.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// Checks if user has completed onboarding
  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ── Still loading Firebase ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8FF5FE)),
              ),
            ),
          );
        }

        final user = snapshot.data;

        return FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (context, onboardingSnapshot) {
            // Still loading prefs? Show spinner
            if (!onboardingSnapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8FF5FE),
                    ),
                  ),
                ),
              );
            }

            final hasSeen = onboardingSnapshot.data ?? false;

            // Route based on onboarding and auth state
            if (!hasSeen) return const OnBoardingScreen();
            if (user == null) return const LoginScreen();
            return const HomeScreen();
          },
        );
      },
    );
  }
}
