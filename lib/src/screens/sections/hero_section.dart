import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';

/// Hero section for the dashboard.
class HeroSection extends StatefulWidget {
  final String userName;
  final String accessLevel;

  const HeroSection({
    super.key,
    this.userName = 'User',
    this.accessLevel = 'Curator Access Level Tier III',
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${widget.userName}',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.primaryGradient,
          ).createShader(bounds),
          child: Text(
            'Your media vault is secure',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
          ),
        ),
      ],
    );
  }
}
