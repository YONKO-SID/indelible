import 'package:flutter/material.dart';

/// COLOR PALETTE: Dark vault theme inspired by supplied design
class AppColors {
  // Surface Layers
  static const Color surface = Color(0xFF070B10); // Deepest space black/navy
  static const Color surfaceContainerLow = Color(0xFF0D1219);
  static const Color surfaceContainer = Color(0xFF121922); // Main cards
  static const Color surfaceContainerHigh = Color(0xFF1B2430);
  static const Color surfaceContainerHighest = Color(0xFF24303D);
  static const Color surfaceBright = Color(0xFF2E3D4D); // Used for highlights

  // Accents
  static const Color primary = Color(0xFF56E0F0); // Vibrant Cyan
  static const Color secondary = Color(0xFF8A6CFF); // Deep Purple/Indigo
  static const Color tertiary = Color(0xFF6BA4FF); // Bright Blue
  
  static const Color onPrimary = Color(0xFF070B10);

  // Status/Semantic
  static const Color errorContainer = Color(0xFF7A2E2E);
  static const Color success = Color(0xFF1FB56E);
  static const Color warning = Color(0xFFCB9E40);

  // Tones for text
  static const Color onSurface = Color(0xFFEAF6FF);
  static const Color onSurfaceVariant = Color(0xFF8FA6B6);

  // Borders / outlines
  static const Color outline = Color(0xFF1E2A34);
  static const Color outlineVariant = Color(0xFF2D3C4A);
  static const Color softShadow = Color(0xFF000810);

  // Gradient helper
  static const List<Color> primaryGradient = [Color(0xFF56E0F0), Color(0xFF6BA4FF)];
}
