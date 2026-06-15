import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';
import 'package:indelible/src/screens/layouts/dashboard_layout.dart';
import 'package:indelible/src/services/auth_service.dart';
import 'package:indelible/src/services/api_service.dart';
import 'package:indelible/src/models/alert.dart';
import 'package:indelible/src/screens/sections/piracy_alert_banner.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userName = 'Creator';
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  Timer? _alertTimer;
  List<PiracyAlert> _alerts = [];
  bool _isCheckingAlerts = false;

  late AnimationController _heroCtrl;
  late AnimationController _shieldCtrl;
  late Animation<double> _heroFade;
  late Animation<double> _shieldFloat;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startAlertPolling();

    _heroCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _shieldCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut),
    );
    _shieldFloat = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut),
    );

    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _heroCtrl.dispose();
    _shieldCtrl.dispose();
    super.dispose();
  }

  void _startAlertPolling() {
    _alertTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkAlerts());
    _checkAlerts();
  }

  Future<void> _checkAlerts() async {
    final user = _authService.currentUser;
    if (user == null || _isCheckingAlerts) return;
    _isCheckingAlerts = true;
    try {
      final alerts = await _apiService.fetchAlerts(user.uid);
      if (mounted) setState(() => _alerts = alerts);
    } catch (_) {} finally {
      _isCheckingAlerts = false;
    }
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Creator';
      });
    }
  }

  // ── Navigation helpers ──────────────────────────────────────────────────
  void _goTo(String route) => Navigator.of(context).pushReplacementNamed(route);

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/vault',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── PIRACY ALERTS (if any) ───────────────────────────────────
            if (_alerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: _alerts.map((alert) => PiracyAlertBanner(
                    alert: alert,
                    onDismiss: () => setState(() => _alerts.removeWhere((a) => a.id == alert.id)),
                    onViewDetails: () {},
                  )).toList(),
                ),
              ),

            // ── HERO SECTION ─────────────────────────────────────────────
            _HeroSection(
              userName: _userName,
              heroFade: _heroFade,
              shieldFloat: _shieldFloat,
              onProtect: () => _goTo('/protect'),
              onViewPlans: () => _scrollToPlans(),
            ),

            const SizedBox(height: 48),

            // ── FEATURE CARDS ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeatureCardsRow(onDashboard: () => _goTo('/dashboard')),
            ),

            const SizedBox(height: 56),

            // ── HOW WE SECURE ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _HowWeSecureSection(),
            ),

            const SizedBox(height: 56),

            // ── PLANS ─────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _PlansSection(),
            ),

            const SizedBox(height: 56),

            // ── TESTIMONIALS ──────────────────────────────────────────────
            const _TestimonialsSection(),

            const SizedBox(height: 40),

            // ── FOOTER ────────────────────────────────────────────────────
            const _Footer(),
          ],
        ),
      ),
    );
  }

  void _scrollToPlans() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Detailed plans comparison coming soon!',
          style: GoogleFonts.inter(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HERO SECTION with semi-circle arc background + shield image
// ════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  final String userName;
  final Animation<double> heroFade;
  final Animation<double> shieldFloat;
  final VoidCallback onProtect;
  final VoidCallback onViewPlans;

  const _HeroSection({
    required this.userName,
    required this.heroFade,
    required this.shieldFloat,
    required this.onProtect,
    required this.onViewPlans,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Arc / Semi-circle backdrop ────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _ArcBackgroundPainter()),
          ),

          // ── Shield image (ghosted, low opacity) ──────────────────────
          Positioned(
            bottom: -20,
            right: -30,
            child: AnimatedBuilder(
              animation: shieldFloat,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, shieldFloat.value),
                child: child,
              ),
              child: Opacity(
                opacity: 0.13,
                child: Image.asset(
                  'assets/images/sheild.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── Text content ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: FadeTransition(
              opacity: heroFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'WATERMARK · PROTECT · PROVE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main headline
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'YOUR WORK,\n',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                            height: 1.05,
                            letterSpacing: -1.5,
                          ),
                        ),
                        TextSpan(
                          text: 'INDELIBLE.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.05,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Color(0xFF5275FF), Color(0xFF38BDF8)],
                              ).createShader(const Rect.fromLTWH(0, 0, 260, 60)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sub-headline
                  Text(
                    'Invisible DWT watermarks embedded in every pixel.\nProve ownership. Find leaks. Send takedowns.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA row
                  Row(
                    children: [
                      _HeroCTA(
                        label: 'PROTECT AN ASSET  ↗',
                        filled: true,
                        onTap: onProtect,
                      ),
                      const SizedBox(width: 14),
                      _HeroCTA(
                        label: 'VIEW PLANS  ↗',
                        filled: false,
                        onTap: onViewPlans,
                      ),
                    ],
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

class _HeroCTA extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _HeroCTA({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: filled ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

// The arc background painter — draws the half-circle arc centred at top
class _ArcBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft arc fill centred at the horizontal mid-top
    final cx = size.width / 2;
    final cy = -size.height * 0.25; // push the centre above the visible area
    final radius = size.height * 1.15;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [
          const Color(0xFF171B26),   // surfaceContainerLow — slightly lighter
          const Color(0xFF0E111A),   // surface — the base canvas
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    final path = Path()
      ..moveTo(0, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        0, pi, false,
      )
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Subtle glowing arc stroke at the bottom edge of the arc
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF5275FF).withValues(alpha: 0.25);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0, pi, false,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ════════════════════════════════════════════════════════════════
// FEATURE CARDS ROW
// ════════════════════════════════════════════════════════════════

class _FeatureCardsRow extends StatelessWidget {
  final VoidCallback onDashboard;
  const _FeatureCardsRow({required this.onDashboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT\'S INSIDE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (ctx, box) {
          final isWide = box.maxWidth > 560;
          final cards = [
            _FeatureCard(
              icon: Icons.analytics_outlined,
              accentColor: AppColors.primary,
              title: 'Dashboard',
              body: 'Real-time forensic activity — bar charts, leak timeline, export logs.',
              cta: 'Open Dashboard',
              onTap: onDashboard,
            ),
            _FeatureCard(
              icon: Icons.workspace_premium_outlined,
              accentColor: AppColors.secondary,
              title: 'Know Plans',
              body: 'Free tier, Pro (1K images/mo), Enterprise (unlimited + DMCA auto-send).',
              cta: 'See Pricing',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Detailed plans comparison coming soon!',
                      style: GoogleFonts.inter(color: AppColors.onSurface),
                    ),
                    backgroundColor: AppColors.surfaceContainerHigh,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _FeatureCard(
              icon: Icons.shield_outlined,
              accentColor: AppColors.tertiary,
              title: 'How We Secure',
              body: 'DWT-LL + QIM watermarks embedded invisibly. HMAC-SHA256 verified. Blockchain anchored.',
              cta: 'Learn More',
              onTap: () {},
            ),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cards
                  .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c)))
                  .toList(),
            );
          }
          return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 14), child: c)).toList());
        }),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon, required this.accentColor, required this.title,
    required this.body, required this.cta, required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _hovered
                  ? [
                      widget.accentColor.withValues(alpha: 0.08),
                      AppColors.surfaceContainer,
                    ]
                  : [AppColors.surfaceContainer, AppColors.surfaceContainerLow],
            ),
            border: Border.all(
              color: _hovered
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : AppColors.outline,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: widget.accentColor.withValues(alpha: 0.12), blurRadius: 20)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 22),
              ),
              const SizedBox(height: 16),
              Text(widget.title, style: GoogleFonts.spaceGrotesk(color: AppColors.onSurface, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.body, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.55)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(widget.cta, style: GoogleFonts.inter(color: widget.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_outward_rounded, color: widget.accentColor, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HOW WE SECURE
// ════════════════════════════════════════════════════════════════

class _HowWeSecureSection extends StatelessWidget {
  const _HowWeSecureSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _SecureStep(
        number: '01',
        title: 'DWT-LL Frequency Embedding',
        body: 'Your watermark is embedded in the LL sub-band of the Discrete Wavelet Transform — the most energy-dense region, invisible to the eye but cryptographically robust.',
        color: AppColors.primary,
      ),
      _SecureStep(
        number: '02',
        title: 'QIM Quantization',
        body: 'Quantization Index Modulation (QIM) ensures the hidden bits survive JPEG re-compression, blurring, cropping up to 10 %, and noise injection.',
        color: AppColors.secondary,
      ),
      _SecureStep(
        number: '03',
        title: 'HMAC-SHA256 Payload',
        body: 'Every asset carries a cryptographically signed creator fingerprint + UTC timestamp. Even partial extraction is enough to prove original authorship.',
        color: AppColors.tertiary,
      ),
      _SecureStep(
        number: '04',
        title: 'Blockchain Anchoring',
        body: 'The payload hash is anchored to the Polygon network in real time — creating an immutable, timestamped record that\'s impossible to forge.',
        color: Color(0xFFFBBF24),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW WE SECURE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.8, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Four layers of forensic protection.', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        const SizedBox(height: 28),
        ...steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 16), child: s)),
      ],
    );
  }
}

class _SecureStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final Color color;
  const _SecureStep({required this.number, required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.25))),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                Text(body, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PLANS
// ════════════════════════════════════════════════════════════════

class _PlansSection extends StatelessWidget {
  const _PlansSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLANS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.8, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Simple, transparent pricing.', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        const SizedBox(height: 28),
        LayoutBuilder(builder: (ctx, box) {
          final isWide = box.maxWidth > 560;
          final plans = [
            _PlanCard(
              name: 'Free',
              price: '\$0',
              period: '/mo',
              features: ['100 images / month', '720p video watermarking', 'Basic dashboard', 'Community support'],
              accentColor: AppColors.onSurfaceVariant,
              isPrimary: false,
            ),
            _PlanCard(
              name: 'Pro',
              price: '\$12',
              period: '/mo',
              features: ['1,000 images / month', '4K video watermarking', 'Full dashboard + logs', 'Priority support', 'DMCA draft generator'],
              accentColor: AppColors.primary,
              isPrimary: true,
            ),
            _PlanCard(
              name: 'Enterprise',
              price: 'Custom',
              period: '',
              features: ['Unlimited assets', 'Auto DMCA sending', 'Blockchain anchoring', 'Dedicated manager', 'API access'],
              accentColor: AppColors.secondary,
              isPrimary: false,
            ),
          ];
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plans.map((p) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: p))).toList(),
            );
          }
          return Column(children: plans.map((p) => Padding(padding: const EdgeInsets.only(bottom: 14), child: p)).toList());
        }),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final Color accentColor;
  final bool isPrimary;
  const _PlanCard({
    required this.name, required this.price, required this.period,
    required this.features, required this.accentColor, required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentColor.withValues(alpha: 0.12), AppColors.surfaceContainer],
              )
            : null,
        color: isPrimary ? null : AppColors.surfaceContainer,
        border: Border.all(
          color: isPrimary ? accentColor.withValues(alpha: 0.6) : AppColors.outline,
          width: isPrimary ? 2 : 1.5,
        ),
        boxShadow: isPrimary ? [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 24)] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('MOST POPULAR', style: GoogleFonts.inter(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: accentColor)),
              if (period.isNotEmpty)
                Text(period, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.outline, height: 1),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: accentColor, size: 15),
                const SizedBox(width: 8),
                Flexible(child: Text(f, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface))),
              ],
            ),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () async {
                if (name == 'Pro') {
                  final url = Uri.parse('https://rzp.io/l/indelible-pro');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                } else if (name == 'Enterprise') {
                  final url = Uri.parse('mailto:sales@indelible.security?subject=Enterprise%20Inquiry');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                } else {
                  // Free plan, just scroll up to protect asset / dashboard
                  // Let's scroll or navigate
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isPrimary ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  name == 'Enterprise' ? 'Contact Us' : 'Get Started',
                  style: GoogleFonts.inter(
                    color: isPrimary ? AppColors.onPrimary : accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TESTIMONIALS
// ════════════════════════════════════════════════════════════════

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const _testimonials = [
    (
      name: 'Aryan Mehta',
      role: 'Sports Broadcaster, StreamAxis',
      text: 'Within 48 hours of using Indelible, we caught an illegal re-stream of our IPL match and sent the DMCA notice automatically. Unreal.',
      avatar: 'A',
    ),
    (
      name: 'Priya Sharma',
      role: 'Digital Artist',
      text: 'I have been watermarking my artwork for years. Nothing comes close to how invisible yet powerful the DWT method is. My designs are truly mine now.',
      avatar: 'P',
    ),
    (
      name: 'Marcus Lin',
      role: 'Content Creator, 2.1M subs',
      text: 'The blockchain anchoring is a game changer. I can prove the exact second I published anything — no one can claim it was theirs.',
      avatar: 'M',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TESTIMONIALS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.8, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Creators trust Indelible.', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (ctx, box) {
            final isWide = box.maxWidth > 700;
            final cards = _testimonials.map((t) => _TestimonialCard(
              name: t.name, role: t.role, text: t.text, avatar: t.avatar,
            )).toList();

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 14), child: c))).toList(),
              );
            }
            return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 14), child: c)).toList());
          }),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String role;
  final String text;
  final String avatar;
  const _TestimonialCard({required this.name, required this.role, required this.text, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14))),
          const SizedBox(height: 12),
          Text('"$text"', style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface, height: 1.6)),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                child: Text(avatar, style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(role, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FOOTER
// ════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'INDELIBLE',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A mark indestructible',
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Made with ',
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
                const TextSpan(text: '♥ ', style: TextStyle(color: Color(0xFFF87171), fontSize: 14)),
                TextSpan(
                  text: 'from ',
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
                TextSpan(
                  text: 'Indelible',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} Indelible. All rights reserved.',
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
