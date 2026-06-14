import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';

class IntroScreen1 extends StatefulWidget {
  const IntroScreen1({super.key});

  @override
  State<IntroScreen1> createState() => _IntroScreen1State();
}

class _IntroScreen1State extends State<IntroScreen1> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

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
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // 1. The Custom Radar Shield Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: RadarShieldPainter(
                animation: _controller,
                radarColor: AppColors.primary,
              ),
            ),
          ),
          
          // 2. The Text Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 120), // Spacer for the radar
                  
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Protect Your Digital Assets',
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
                        'Embed invisible forensic watermarks into your videos and images. Survives compression, cropping, and re-encoding.',
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

class RadarShieldPainter extends CustomPainter {
  final Animation<double> animation;
  final Color radarColor;

  RadarShieldPainter({required this.animation, required this.radarColor}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    final maxRadius = min(size.width, size.height) * 0.22;
    final value = animation.value;

    // Draw background concentric grid circles
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = radarColor.withValues(alpha: 0.06);

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), gridPaint);
    }

    // Draw pulsing radar rings
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = radarColor.withValues(alpha: 1.0 - value);
    canvas.drawCircle(center, maxRadius * value, pulsePaint);
    canvas.drawCircle(center, maxRadius * ((value + 0.5) % 1.0), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = radarColor.withValues(alpha: 1.0 - ((value + 0.5) % 1.0)));

    // Radar Sweep Line
    final angle = value * 2 * pi;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: [
          radarColor.withValues(alpha: 0.4),
          radarColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, linePaint);

    // Sweep line needle
    final needlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = radarColor.withValues(alpha: 0.5);
    final dx = center.dx + maxRadius * cos(angle);
    final dy = center.dy + maxRadius * sin(angle);
    canvas.drawLine(center, Offset(dx, dy), needlePaint);

    // Draw Shield Path in Center
    final shieldPath = Path();
    final shieldWidth = maxRadius * 0.45;
    final shieldHeight = maxRadius * 0.55;
    final sy = center.dy - shieldHeight / 2;
    
    shieldPath.moveTo(center.dx, sy); // top point
    shieldPath.quadraticBezierTo(center.dx + shieldWidth * 0.8, sy + shieldHeight * 0.1, center.dx + shieldWidth, sy + shieldHeight * 0.2);
    shieldPath.quadraticBezierTo(center.dx + shieldWidth, sy + shieldHeight * 0.7, center.dx, sy + shieldHeight); // bottom point
    shieldPath.quadraticBezierTo(center.dx - shieldWidth, sy + shieldHeight * 0.7, center.dx - shieldWidth, sy + shieldHeight * 0.2);
    shieldPath.quadraticBezierTo(center.dx - shieldWidth * 0.8, sy + shieldHeight * 0.1, center.dx, sy);
    shieldPath.close();

    final shieldGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = radarColor.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(shieldPath, shieldGlowPaint);

    final shieldFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = radarColor.withValues(alpha: 0.08);
    canvas.drawPath(shieldPath, shieldFillPaint);

    final shieldBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = radarColor;
    canvas.drawPath(shieldPath, shieldBorderPaint);

    // Stylized checkmark inside shield
    final checkPath = Path();
    checkPath.moveTo(center.dx - shieldWidth * 0.3, center.dy);
    checkPath.lineTo(center.dx - shieldWidth * 0.05, center.dy + shieldHeight * 0.18);
    checkPath.lineTo(center.dx + shieldWidth * 0.35, center.dy - shieldHeight * 0.15);
    
    canvas.drawPath(
      checkPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = radarColor,
    );
  }

  @override
  bool shouldRepaint(covariant RadarShieldPainter oldDelegate) => true;
}
