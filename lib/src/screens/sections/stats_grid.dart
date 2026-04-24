import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/protection_stats.dart';

/// Displays system performance metrics in a responsive grid.
///
/// Fetches real data from backend `/logs` endpoint and displays:
/// - Watermark Persistence (success rate)
/// - Verification Rate (successful verifications)
/// - Asset Protection Rate (uptime)
///
/// Each card shows metric title, percentage value, and animated progress bar.
/// Responsive layout: 1 column (mobile) → 2 columns (tablet) → 3 columns (desktop)
class StatsGrid extends StatefulWidget {
  const StatsGrid({super.key});

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> {
  late Future<ProtectionStats> _statsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _statsFuture = _apiService.fetchProtectionStats();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monitoring Engine',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            Icon(Icons.radar, color: AppColors.primary.withValues(alpha: 0.5)),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<ProtectionStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid();
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            } else if (snapshot.hasData) {
              final stats = snapshot.data!;
              return _buildStatsGrid(stats);
            } else {
              return _buildLoadingGrid();
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ProtectionStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust crossAxisCount based on screen width
        int columns = constraints.maxWidth > 800
            ? 3
            : (constraints.maxWidth > 500 ? 2 : 1);

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            _buildStatCard(
              title: 'Watermark Persistence',
              value: '${(stats.successRate).toStringAsFixed(1)}%',
              progress: stats.successRate / 100,
              color: AppColors.primary,
            ),
            _buildStatCard(
              title: 'Asset Integrity',
              value: '${stats.totalAssets}',
              progress: stats.totalAssets > 0 ? 0.95 : 0.0,
              color: AppColors.secondary,
              subtitle: '${stats.totalAssets} protected',
            ),
            _buildStatCard(
              title: 'System Uptime',
              value: '${stats.uptimePercentage.toStringAsFixed(1)}%',
              progress: stats.uptimePercentage / 100,
              color: AppColors.tertiary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth > 800
            ? 3
            : (constraints.maxWidth > 500 ? 2 : 1);

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: List.generate(
            3,
            (index) => Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
              child: const Shimmer(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorContainer.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.errorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load stats: $error',
              style: GoogleFonts.inter(
                color: AppColors.errorContainer,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required double progress,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple shimmer loading animation
class Shimmer extends StatefulWidget {
  const Shimmer({super.key});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Container(
        color: AppColors.surfaceBright.withValues(alpha: _opacity.value),
      ),
    );
  }
}
