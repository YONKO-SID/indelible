import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/themes/app_colors.dart';
import '../services/api_service.dart';
import '../models/protection_stats.dart';
import '../models/alert.dart';
import '../widgets/animations/animation_builders.dart';
import 'layouts/dashboard_layout.dart';
import 'sections/recent_assets_list.dart' hide Shimmer;

/// Bento-Grid Dashboard — powered entirely by real backend data
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<_DashboardBundle>? _bundle;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _bundle = _loadAll();
  }

  Future<_DashboardBundle> _loadAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final results = await Future.wait([
      _api.fetchProtectionStats(userUid: uid),
      _api.fetchDashboardStats(userUid: uid),
      _api.fetchAlerts(uid),
    ]);
    return _DashboardBundle(
      stats: results[0] as ProtectionStats,
      chartData: results[1] as Map<String, dynamic>,
      alerts: results[2] as List<PiracyAlert>,
    );
  }

  Future<void> _runCrawlScan() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Running web crawler scan…',
          style: GoogleFonts.inter(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _api.fetchCrawlResults(userUid: uid);
    if (!mounted) return;
    setState(() {
      _bundle = _loadAll();
    });
  }

  Future<void> _exportFullLogs() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/logs?user_uid=$uid'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showLogsDialog(response.body);
      } else {
        throw Exception('Backend returned ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  void _showLogsDialog(String rawJson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          'Full Protection Logs',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.primary,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: 560,
          height: 420,
          child: SingleChildScrollView(
            child: SelectableText(
              rawJson,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Creator';
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ────────────────────────────────────────────────
            FadeInAnimation(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.0,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back, $_displayName.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Crawl + Export buttons
                  Wrap(
                    spacing: 12,
                    children: [
                      _ActionChip(
                        label: 'Run Web Scan',
                        icon: Icons.radar_outlined,
                        color: AppColors.secondary,
                        onTap: _runCrawlScan,
                      ),
                      _ActionChip(
                        label: 'Export Logs',
                        icon: Icons.download_outlined,
                        color: AppColors.primary,
                        onTap: _exportFullLogs,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── MAIN CONTENT ──────────────────────────────────────────
            FutureBuilder<_DashboardBundle>(
              future: _bundle ??= _loadAll(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonGrid();
                }
                if (snap.hasError || !snap.hasData) {
                  return _buildError(snap.error.toString());
                }
                final b = snap.data!;
                return Column(
                  children: [
                    // Metric bento cards
                    StaggeredListAnimation(
                      itemDelay: const Duration(milliseconds: 80),
                      children: [
                        _buildHeroCard(b.stats),
                        const SizedBox(height: 16),
                        _buildMetricRow(b.stats, b.alerts.length),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Real weekly activity bar chart
                    SlideInAnimation(
                      duration: const Duration(milliseconds: 600),
                      child: _RealBarChartCard(chartData: b.chartData),
                    ),
                    const SizedBox(height: 32),

                    // Leak detection activity timeline (max 4)
                    SlideInAnimation(
                      duration: const Duration(milliseconds: 700),
                      begin: const Offset(0, 0.2),
                      child: _LeakTimeline(alerts: b.alerts),
                    ),
                    const SizedBox(height: 32),

                    // Protected assets list
                    SlideInAnimation(
                      duration: const Duration(milliseconds: 800),
                      begin: const Offset(0, 0.2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Protected Assets'),
                          const SizedBox(height: 16),
                          const RecentAssetsList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Container(width: 40, height: 1.5, color: AppColors.outline),
      ],
    );
  }

  Widget _buildHeroCard(ProtectionStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: AppColors.glassCard(radius: 24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL PROTECTED ASSETS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedCounter(
                    targetValue: stats.totalAssets,
                    textStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'items',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DWT-LL watermark embedded in every asset',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_outward_rounded,
                color: Colors.black,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(ProtectionStats stats, int alertCount) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'SUCCESS RATE',
            value: '${stats.successRate.toStringAsFixed(0)}%',
            color: AppColors.secondary,
            icon: Icons.verified_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'SYSTEM STATUS',
            value: '${stats.uptimePercentage.toStringAsFixed(1)}%',
            color: AppColors.tertiary,
            icon: Icons.speed_outlined,
            subtitle: 'Uptime',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'LEAKS DETECTED',
            value: alertCount.toString(),
            color: alertCount > 0
                ? AppColors.errorContainer
                : AppColors.success,
            icon: alertCount > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            subtitle: alertCount > 0 ? 'Action needed' : 'All clear',
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    return Column(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const DashboardShimmer(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Expanded(
                child: Container(
                  height: 132,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const DashboardShimmer(),
                ),
              ),
              if (i < 2) const SizedBox(width: 16),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.errorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data bundle ────────────────────────────────────────────────────────────

class _DashboardBundle {
  final ProtectionStats stats;
  final Map<String, dynamic> chartData;
  final List<PiracyAlert> alerts;
  _DashboardBundle({
    required this.stats,
    required this.chartData,
    required this.alerts,
  });
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 132,
      decoration: AppColors.glassCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Real bar chart using /dashboard-stats data ─────────────────────────────

class _RealBarChartCard extends StatelessWidget {
  final Map<String, dynamic> chartData;
  const _RealBarChartCard({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final rawBars = chartData['bars'] as List<dynamic>? ?? List.filled(7, 0);
    final labels =
        (chartData['labels'] as List<dynamic>?)?.cast<String>() ??
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final bars = rawBars.map((v) => (v as num).toDouble()).toList();
    final totalEvents = chartData['total_events'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColors.glassCard(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FORENSIC ACTIVITY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weekly Watermark Events',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalEvents total',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _RealBarChartPainter(
                bars: bars,
                labels: labels,
                primaryColor: AppColors.primary,
                secondaryColor: AppColors.secondary,
                gridColor: AppColors.outlineVariant.withValues(alpha: 0.15),
                textColor: AppColors.onSurfaceVariant,
                isEmpty: totalEvents == 0,
              ),
            ),
          ),
          if (totalEvents == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No watermarking events yet — protect your first asset to see activity.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _RealBarChartPainter extends CustomPainter {
  final List<double> bars;
  final List<String> labels;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color textColor;
  final bool isEmpty;

  _RealBarChartPainter({
    required this.bars,
    required this.labels,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.textColor,
    required this.isEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final maxVal = bars.isEmpty
        ? 1.0
        : (bars.reduce(max) == 0 ? 1.0 : bars.reduce(max));
    final spacing = size.width / (bars.length + 1);
    final barWidth = min(spacing * 0.4, 18.0);
    final chartHeight = size.height - 24;

    // Grid lines
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = gridColor;
    for (int i = 1; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < bars.length; i++) {
      final x = spacing * (i + 1);
      final barHeight = isEmpty ? 0.0 : (bars[i] / maxVal) * chartHeight;
      final y = chartHeight - barHeight;

      // Track background
      final trackPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = gridColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, 0, barWidth, chartHeight),
          Radius.circular(barWidth / 2),
        ),
        trackPaint,
      );

      if (barHeight > 0) {
        final isMax = bars[i] == bars.reduce(max) && bars[i] > 0;
        final rect = Rect.fromLTWH(x - barWidth / 2, y, barWidth, barHeight);
        final barPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isMax
                ? [secondaryColor, primaryColor]
                : [primaryColor.withValues(alpha: 0.5), primaryColor],
          ).createShader(rect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
          barPaint,
        );

        if (isMax) {
          // Glow
          final glowPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = primaryColor.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(Offset(x, y), barWidth * 0.9, glowPaint);

          // Tooltip
          final tooltipPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = AppColors.onSurface;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 22, y - 28, 44, 20),
              const Radius.circular(6),
            ),
            tooltipPaint,
          );
          final path = Path()
            ..moveTo(x - 4, y - 8)
            ..lineTo(x, y - 4)
            ..lineTo(x + 4, y - 8)
            ..close();
          canvas.drawPath(path, tooltipPaint);

          final textSpan = TextSpan(
            text: bars[i].toInt().toString(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
          );
          textPainter.text = textSpan;
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 24));
        }
      }

      // Label
      final isActive = !isEmpty && bars[i] > 0 && bars[i] == bars.reduce(max);
      final labelSpan = TextSpan(
        text: labels[i],
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? primaryColor : textColor,
        ),
      );
      textPainter.text = labelSpan;
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RealBarChartPainter old) =>
      old.bars != bars || old.isEmpty != isEmpty;
}

// ── Leak detection activity timeline (max 4 items) ────────────────────────

class _LeakTimeline extends StatelessWidget {
  final List<PiracyAlert> alerts;
  const _LeakTimeline({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final capped = alerts.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LEAK DETECTION LOG',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (alerts.length > 4)
              Text(
                '${alerts.length - 4} more hidden',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (capped.isEmpty)
          _EmptyState()
        else
          Container(
            decoration: AppColors.glassCard(radius: 20),
            child: Column(
              children: [
                for (int i = 0; i < capped.length; i++) ...[
                  _LeakRow(alert: capped[i]),
                  if (i < capped.length - 1)
                    Divider(color: AppColors.outline, height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: AppColors.glassCard(radius: 20),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.success, size: 40),
          const SizedBox(height: 12),
          Text(
            'No leaks found yet',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Run a web scan to check if your protected assets appear on public forums.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LeakRow extends StatelessWidget {
  final PiracyAlert alert;
  const _LeakRow({required this.alert});

  String _relativeTime() {
    try {
      final dt = DateTime.parse(alert.timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.errorContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leaked asset detected',
                  style: GoogleFonts.inter(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.sourceUrl.length > 55
                      ? '${alert.sourceUrl.substring(0, 52)}…'
                      : alert.sourceUrl,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.confidence,
                  style: GoogleFonts.inter(
                    color: AppColors.errorContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _relativeTime(),
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shimmer placeholder ────────────────────────────────────────────────────

class DashboardShimmer extends StatefulWidget {
  const DashboardShimmer({super.key});
  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.25,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: _opacity.value),
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );
}
