import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';

class IntroScreen2 extends StatefulWidget {
  const IntroScreen2({super.key});

  @override
  State<IntroScreen2> createState() => _IntroScreen2State();
}

class _IntroScreen2State extends State<IntroScreen2> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // The main engine driving the wave math
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Loops indefinitely

    // Entrance animations for the text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface, // Assume this is a very dark color
      body: Stack(
        children: [
          // 1. The Generative Math Background
          Positioned.fill(
            child: CustomPaint(
              painter: FrequencyWavePainter(
                animation: _controller,
                waveColor: AppColors.secondary, // Use a bright accent color here
              ),
            ),
          ),
          
          // 2. The Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 120), // Spacer for the waves
                  
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'DWT-DCT Forensic Engine',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Classical signal processing embeds cryptographic payloads in frequency domains. Invisible to humans, robust against attacks.',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The core math painter rendering the frequency visualization
class FrequencyWavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color waveColor;

  FrequencyWavePainter({required this.animation, required this.waveColor}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = waveColor.withValues(alpha: 0.3);

    // Add a glow effect
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..color = waveColor.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path1 = Path();
    final path2 = Path();
    final path3 = Path();

    final centerY = size.height * 0.35; // Position the waves in the upper middle
    final width = size.width;
    
    // Shift the phase based on the animation controller to create motion
    final phase = animation.value * 2 * pi;

    for (double x = 0; x <= width; x++) {
      // Calculate normalized X
      final nx = x / width;
      
      // Wave 1: Low Frequency (Approximation Band)
      final y1 = centerY + sin(nx * 2 * pi + phase) * 40;
      
      // Wave 2: Mid Frequency (Watermark Target Band)
      final y2 = centerY + sin(nx * 4 * pi - phase * 1.5) * 30 * sin(nx * pi); 
      
      // Wave 3: High Frequency (Details/Noise)
      final y3 = centerY + cos(nx * 8 * pi + phase * 2) * 20 * sin(nx * 2 * pi);

      if (x == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
        path3.moveTo(x, y3);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
        path3.lineTo(x, y3);
      }
    }

    // Draw Glows
    canvas.drawPath(path1, glowPaint);
    canvas.drawPath(path2, glowPaint);
    
    // Draw Core Lines
    paint.color = waveColor.withValues(alpha: 0.6);
    canvas.drawPath(path1, paint);
    
    paint.color = waveColor.withValues(alpha: 0.8);
    canvas.drawPath(path2, paint);
    
    paint.color = waveColor.withValues(alpha: 0.4);
    paint.strokeWidth = 1.0;
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant FrequencyWavePainter oldDelegate) => true;
}
