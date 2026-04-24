import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/profile_screen.dart';
import 'config/themes/app_colors.dart';

/// Root widget of the INDELIBLE application.
///
/// Routing flow:
/// 1. App launches → SplashScreen (2s branded animation)
/// 2. SplashScreen → AuthGate (listens to auth state)
/// 3. AuthGate routes to: OnBoarding, Login, or Home
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
        scaffoldBackgroundColor: AppColors.surface,
        colorSchemeSeed: AppColors.primary,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      // Always starts at splash, hands off to auth route
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthGate(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
