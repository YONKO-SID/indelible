import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';

/// Splash screen shown for 2 seconds on app launch.
///
/// Displays branded logo animation, then hands off to AuthGate
/// for routing decisions (OnBoarding, Login, or Home).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  /// Waits 2 seconds then hands off to AuthGate for routing
  void _navigateAfterSplash() {
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Don't decide routing here — AuthGate handles all routing
      Navigator.of(context).pushReplacementNamed('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Indelible_logo.png', height: 180),
            const SizedBox(height: 24),
            Text(
              'INDELIBLE',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A mark indestructible',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
