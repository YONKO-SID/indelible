import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';

class IntroScreen3 extends StatefulWidget {
  const IntroScreen3({super.key});

  @override
  State<IntroScreen3> createState() => _IntroScreen3State();
}

class _IntroScreen3State extends State<IntroScreen3> with SingleTickerProviderStateMixin {
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
          // 1. The Cryptographic Network Painter
          Positioned.fill(
            child: CustomPaint(
              painter: CryptoProofPainter(
                animation: _controller,
                nodeColor: AppColors.tertiary,
              ),
            ),
          ),
          
          // 2. Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 120), // Spacer for the graphics
                  
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Cryptographic Proof',
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
                        'HMAC-SHA256 signatures with Reed-Solomon error correction. Prove ownership even after heavy compression.',
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

class CryptoProofPainter extends CustomPainter {
  final Animation<double> animation;
  final Color nodeColor;

  CryptoProofPainter({required this.animation, required this.nodeColor}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    final maxRadius = min(size.width, size.height) * 0.22;
    final value = animation.value;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = nodeColor.withValues(alpha: 0.2);

    final nodeOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = nodeColor;

    final nodeFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.surface;

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = nodeColor.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Draw background security matrix rings
    final matrixPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = nodeColor.withValues(alpha: 0.05);
    canvas.drawCircle(center, maxRadius, matrixPaint);
    canvas.drawCircle(center, maxRadius * 0.6, matrixPaint);

    // Define Node Positions
    // 1 Center Node (Merkle Root)
    // 4 Middle layer nodes
    // 8 Outer layer nodes
    final double midRadius = maxRadius * 0.6;
    final List<Offset> midNodes = [];
    for (int i = 0; i < 4; i++) {
      final double angle = (i * pi / 2) + (value * 0.15 * pi); // slight rotation
      midNodes.add(Offset(
        center.dx + midRadius * cos(angle),
        center.dy + midRadius * sin(angle),
      ));
    }

    final double outerRadius = maxRadius;
    final List<Offset> outerNodes = [];
    for (int i = 0; i < 8; i++) {
      final double angle = (i * pi / 4) - (value * 0.1 * pi); // reverse rotation
      outerNodes.add(Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      ));
    }

    // 1. Draw Connection Lines (Blockchain ledger/hash links)
    // From Center to Middle layer
    for (var node in midNodes) {
      canvas.drawLine(center, node, linePaint);
      
      // Moving packet along the line
      final packetPos = Offset.lerp(center, node, value);
      if (packetPos != null) {
        canvas.drawCircle(packetPos, 4.0, Paint()..color = nodeColor);
        canvas.drawCircle(packetPos, 8.0, Paint()..color = nodeColor.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }

    // From Middle layer to Outer layer (Each mid node connects to two outer nodes)
    for (int i = 0; i < 4; i++) {
      final midNode = midNodes[i];
      final outerNode1 = outerNodes[i * 2];
      final outerNode2 = outerNodes[(i * 2 + 1) % 8];

      canvas.drawLine(midNode, outerNode1, linePaint);
      canvas.drawLine(midNode, outerNode2, linePaint);

      // Packets from mid to outer
      final packetPos1 = Offset.lerp(midNode, outerNode1, (value + 0.5) % 1.0);
      final packetPos2 = Offset.lerp(midNode, outerNode2, (value + 0.5) % 1.0);
      if (packetPos1 != null) {
        canvas.drawCircle(packetPos1, 3.0, Paint()..color = nodeColor);
      }
      if (packetPos2 != null) {
        canvas.drawCircle(packetPos2, 3.0, Paint()..color = nodeColor);
      }
    }

    // 2. Draw Nodes
    // Outer Nodes (small)
    for (var node in outerNodes) {
      canvas.drawCircle(node, 10.0, glowPaint);
      canvas.drawCircle(node, 6.0, nodeFillPaint);
      canvas.drawCircle(node, 6.0, nodeOutlinePaint..strokeWidth = 1.5);
    }

    // Middle Nodes (medium)
    for (var node in midNodes) {
      canvas.drawCircle(node, 14.0, glowPaint);
      canvas.drawCircle(node, 9.0, nodeFillPaint);
      canvas.drawCircle(node, 9.0, nodeOutlinePaint..strokeWidth = 2.0);
      
      // Inner dot representing verification status
      canvas.drawCircle(node, 3.0, Paint()..color = nodeColor.withValues(alpha: 0.8));
    }

    // Center Node (Large Merkle Root)
    final double pulseScale = 1.0 + (sin(value * 2 * pi) * 0.08);
    final centerNodeRadius = 22.0 * pulseScale;
    
    canvas.drawCircle(center, centerNodeRadius + 8, glowPaint);
    canvas.drawCircle(center, centerNodeRadius, nodeFillPaint);
    canvas.drawCircle(center, centerNodeRadius, nodeOutlinePaint..strokeWidth = 2.5);

    // Draw a small lock/shield icon detail using Path inside the Center Node
    final keyPath = Path();
    final kw = centerNodeRadius * 0.45;
    final kh = centerNodeRadius * 0.55;
    final ksy = center.dy - kh / 2;

    keyPath.moveTo(center.dx, ksy); // top point
    keyPath.quadraticBezierTo(center.dx + kw * 0.8, ksy + kh * 0.1, center.dx + kw, ksy + kh * 0.2);
    keyPath.quadraticBezierTo(center.dx + kw, ksy + kh * 0.7, center.dx, ksy + kh); // bottom point
    keyPath.quadraticBezierTo(center.dx - kw, ksy + kh * 0.7, center.dx - kw, ksy + kh * 0.2);
    keyPath.quadraticBezierTo(center.dx - kw * 0.8, ksy + kh * 0.1, center.dx, ksy);
    keyPath.close();

    canvas.drawPath(
      keyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = nodeColor,
    );

    // Small keyhole or dot inside the mini shield
    canvas.drawCircle(center, 2.5, Paint()..color = nodeColor);
  }

  @override
  bool shouldRepaint(covariant CryptoProofPainter oldDelegate) => true;
}
