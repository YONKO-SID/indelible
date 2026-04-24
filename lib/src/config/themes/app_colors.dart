import 'package:flutter/material.dart';

/// COLOR PALETTE: FlareLine Dashboard Theme
class AppColors {
  // Surface Layers
  static const Color surface = Color(0xFF1A222C); // Main background
  static const Color surfaceContainerLow = Color(0xFF1C2434); // Sidebar background
  static const Color surfaceContainer = Color(0xFF24303F); // Card background
  static const Color surfaceContainerHigh = Color(0xFF2E3A47); // Hover states
  static const Color surfaceContainerHighest = Color(0xFF313D4A); // Active states
  static const Color surfaceBright = Color(0xFF3C4A59);

  // Status/Semantic
  static const Color errorContainer = Color(0xFFEF4444); // Red
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Orange

  // Primary Action (Blue)
  static const Color primary = Color(0xFF3C50E0);
  static const Color primaryContainer = Color(0xFF5A6DE6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary Highlight (Light Blue)
  static const Color secondary = Color(0xFF3BA2B8);
  static const Color secondaryContainer = Color(0xFF4CB3C9);

  // Tertiary 
  static const Color tertiary = Color(0xFF80CAEE);
  static const Color tertiaryContainer = Color(0xFF9BD8F4);

  // Text
  static const Color onSurface = Color(0xFFFFFFFF); // White text
  static const Color onSurfaceVariant = Color(0xFF8A99AF); // Muted gray text
  static const Color outline = Color(0xFF2E3A47); // Dark borders
  static const Color outlineVariant = Color(0xFF313D4A); // Lighter borders
}
