import 'package:flutter/material.dart';

/// COLOR PALETTE: "Misty Storm" — Deep slate-blue cybersecurity identity
/// Primary cobalt blue accent + cyber cyan metrics on a deep navy canvas.
class AppColors {
  AppColors._(); // Prevent instantiation

  // --- Core Canvas & Surfaces ---
  /// The deepest slate-blue base canvas
  static const Color surface = Color(0xFF0E111A);
  /// Elevated card / container surface
  static const Color surfaceContainerLow = Color(0xFF171B26);
  /// Main cards — frosted, elevated
  static const Color surfaceContainer = Color(0xFF1E2433);
  /// Hover / active card state
  static const Color surfaceContainerHigh = Color(0xFF242B3D);
  /// Highest elevation surface
  static const Color surfaceContainerHighest = Color(0xFF2E3850);
  /// Bright highlight / shimmer layer
  static const Color surfaceBright = Color(0xFF3A4560);

  // --- Brand Accents ---
  /// High-energy cobalt blue — active states, shields, primary CTA
  static const Color primary = Color(0xFF5275FF);
  /// Cyber neon cyan — graph lines, metrics, data glows
  static const Color secondary = Color(0xFF38BDF8);
  /// Verification success green
  static const Color tertiary = Color(0xFF34D399);
  /// Forgery / tamper alert red
  static const Color errorContainer = Color(0xFFF87171);
  static const Color error = Color(0xFFEF4444);

  static const Color onPrimary = Color(0xFF0E111A);

  // --- Status / Semantic ---
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);

  // --- Typography Hierarchy ---
  /// Bright, crisp off-white for primary headings
  static const Color onSurface = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFFF8FAFC);
  /// Soft white for body text
  static const Color onSurfaceVariant = Color(0xFF64748B);

  // --- Borders / Outlines ---
  /// Low-contrast structural dividers
  static const Color outline = Color(0xFF242B3D);
  /// Slightly more visible outline for card edges
  static const Color outlineVariant = Color(0xFF2E3850);
  /// Deep shadow colour
  static const Color softShadow = Color(0xFF080B12);

  // --- Gradient helpers ---
  static const List<Color> primaryGradient = [Color(0xFF5275FF), Color(0xFF38BDF8)];

  /// Atmospheric glow BoxDecoration factory — use on Bento cards & the TopAppBar
  static BoxDecoration glassCard({
    double radius = 24,
    Color? borderColor,
    bool glowing = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E2433), Color(0xFF0E111A)],
        stops: [0.0, 1.0],
      ),
      border: Border.all(
        color: (borderColor ?? const Color(0xFF242B3D)).withValues(alpha: 0.6),
        width: 1.5,
      ),
      boxShadow: glowing
          ? [
              BoxShadow(
                color: const Color(0xFF5275FF).withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ]
          : [
              BoxShadow(
                color: const Color(0xFF080B12).withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }
}
