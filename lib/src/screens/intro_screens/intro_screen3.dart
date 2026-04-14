import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';

/// Third intro screen - final call to action
class IntroScreen3 extends StatelessWidget {
  const IntroScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 120,
                color: AppColors.tertiary,
              ),
              const SizedBox(height: 48),
              Text(
                'Cryptographic Proof',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'HMAC-SHA256 signatures with Reed-Solomon error correction. Prove ownership even after heavy compression.',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
