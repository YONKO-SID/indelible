import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════
/// Hero section displaying welcome message and user access level.
///
/// Shows:
/// - Personalized greeting with user's name
/// - Access tier level (e.g., "Curator Access Level Tier III")
/// - System status indicator
// ═══════════════════════════════════════════════════════════
class HeroSection extends StatelessWidget {
  /// User's display name for personalized greeting
  final String userName;

  /// Access tier description shown below greeting
  final String accessLevel;

  const HeroSection({
    super.key,
    this.userName = 'User',
    this.accessLevel = 'Curator Access Level Tier III',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName!',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            accessLevel,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
