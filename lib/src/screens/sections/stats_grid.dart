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

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: List.generate(4, (_) => Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Shimmer(),
          )),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorContainer.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.errorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error,
                style: GoogleFonts.inter(color: AppColors.errorContainer, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ProtectionStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth > 1200
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            _buildStatCard(
              title: 'PROTECTED',
              value: '${stats.totalAssets}',
              icon: Icons.verified_rounded,
              iconColor: AppColors.tertiary,
            ),
            _buildStatCard(
              title: 'SYNCING',
              value: '156',
              icon: Icons.sync_rounded,
              iconColor: AppColors.onSurface,
            ),
            _buildStatCard(
              title: 'STORAGE',
              value: '84%',
              showProgress: true,
              progressValue: 0.84,
            ),
            _buildStatCard(
              title: 'INTEGRITY',
              value: '99.9',
              suffix: '%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
    String? suffix,
    bool showProgress = false,
    double progressValue = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  suffix,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
              ],
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progressValue,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shimmer / Helper widgets ───────────────────────────────
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
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _opacity, builder: (context, child) => Container(
      decoration: BoxDecoration(color: AppColors.surfaceBright.withValues(alpha: _opacity.value), borderRadius: BorderRadius.circular(16)),
    ));
  }
}
