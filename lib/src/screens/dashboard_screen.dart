import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/themes/app_colors.dart';
import '../services/api_service.dart';
import '../models/protection_stats.dart';
import '../models/asset_log.dart';
import '../models/activity_event.dart';
import '../screens/sections/stats_grid.dart';
import '../screens/sections/recent_assets_list.dart';
import '../screens/sections/recent_activity_list.dart';
import '../widgets/animations/animation_builders.dart';

/// Comprehensive dashboard screen with real-time monitoring
///
/// Displays:
/// - Real protection statistics with animated counters
/// - Protected asset library
/// - Live activity timeline
/// - System health indicators
///
/// All data fetched from backend `/logs` endpoint
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<ProtectionStats> _statsFuture;
  late Future<List<AssetLog>> _assetsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _statsFuture = _apiService.fetchProtectionStats();
    _assetsFuture = _apiService.fetchAssetLogs();
  }

  @override
  Widget build(BuildContext context) {
    final user = _getCurrentUser();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              FadeInAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $user',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time protection monitoring',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Key metrics with animated counters
              SlideInAnimation(
                child: _buildMetricsRow(),
              ),
              const SizedBox(height: 48),

              // Stats Grid with real data
              SlideInAnimation(
                duration: const Duration(milliseconds: 700),
                begin: const Offset(0, 0.3),
                child: const StatsGrid(),
              ),
              const SizedBox(height: 48),

              // Recent Assets
              SlideInAnimation(
                duration: const Duration(milliseconds: 900),
                begin: const Offset(0, 0.3),
                child: const RecentAssetsList(),
              ),
              const SizedBox(height: 48),

              // Recent Activity
              SlideInAnimation(
                duration: const Duration(milliseconds: 1100),
                begin: const Offset(0, 0.3),
                child: const RecentActivityList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return FutureBuilder<ProtectionStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final stats = snapshot.data!;
          return Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Protected Assets',
                  value: stats.totalAssets,
                  icon: Icons.shield_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  label: 'Success Rate',
                  value: stats.successRate.toInt(),
                  suffix: '%',
                  icon: Icons.verified_user_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  label: 'System Uptime',
                  value: stats.uptimePercentage.toInt(),
                  suffix: '%',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ).expand((widget) {
              return [widget, const SizedBox(width: 16)];
            }).toList()
              ..removeLast(),
          );
        }
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int value,
    String suffix = '',
    required IconData icon,
    required Color color,
  }) {
    return ScaleInAnimation(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedCounter(
                  targetValue: value,
                  textStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (suffix.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    suffix,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentUser() {
    // Get from Firebase auth or fallback
    return 'Creator';
  }
}
