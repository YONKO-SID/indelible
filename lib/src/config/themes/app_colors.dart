import 'package:flutter/material.dart';

/// COLOR PALETTE: Atmospheric Security ("Misty Storm")
class AppColors {
  // Surface Layers (Deep Charcoal to Fog)
  static const Color surface = Color(0xFF0F1419);
  static const Color surfaceContainerLow = Color(0xFF1A1F2E);
  static const Color surfaceContainer = Color(0xFF1D2333);
  static const Color surfaceContainerHigh = Color(0xFF232B3C);
  static const Color surfaceContainerHighest = Color(0xFF2B3548);
  static const Color surfaceBright = Color(0xFF354157);

  // Status/Semantic
  static const Color errorContainer = Color(0xFF4A151A); // Muted bruised red
  static const Color success = Color(0xFF8ACEFF); // Cyan Mist instead of standard Green

  // Primary Action (Storm Blue)
  static const Color primary = Color(0xFFA4C9FF);
  static const Color primaryContainer = Color(0xFF6B9CE2);
  static const Color onPrimary = Color(0xFF0F1419);

  // Secondary Highlight (Cyan Mist)
  static const Color secondary = Color(0xFF8ACEFF);
  static const Color secondaryContainer = Color(0xFF4A98D1);

  // Tertiary 
  static const Color tertiary = Color(0xFF65AFFE);
  static const Color tertiaryContainer = Color(0xFF4AA2F8);

  // Text
  static const Color onSurface = Color(0xFFF0F3F7);
  static const Color onSurfaceVariant = Color(0xFFB0B8C3);
  static const Color outline = Color(0xFF748299);
  static const Color outlineVariant = Color(0xFF5A677B);
}
