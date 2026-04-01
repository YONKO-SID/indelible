// =============================================================================
// DASHBOARD SCREEN — Where users land after successful login.
//
// WHY A SEPARATE SCREEN?
// The login button needs somewhere to navigate TO. This is the placeholder
// dashboard that proves auth is working. We'll build the real dashboard later 
// with video upload, verification, and asset library.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  // Create an instance of our auth service
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Get the current user's info to display
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── User Avatar ──
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF2C2C2E),
              child: Text(
                // Show first letter of email, or "?" if no user
                user?.displayName?.substring(0, 1).toUpperCase() ??
                    user?.email?.substring(0, 1).toUpperCase() ??
                    "?",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Welcome Text ──
            Text(
              "Welcome to Indelible",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? "No email",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 48),

            // ── Sign Out Button ──
            // This proves the auth flow works end-to-end:
            // Login → Dashboard → Sign Out → Back to Login
            ElevatedButton.icon(
              onPressed: () async {
                await _authService.signOut();
                // After signing out, navigate back to login and clear the stack
                // pushAndRemoveUntil removes all previous screens so the user
                // can't press "back" to get to the dashboard without logging in
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false, // Remove ALL previous routes
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text("Sign Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
