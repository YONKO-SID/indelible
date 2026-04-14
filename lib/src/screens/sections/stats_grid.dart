import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════
/// Displays system performance metrics in a responsive grid.
///
/// Each card shows a metric title, percentage value, and
/// progress bar. Automatically adjusts columns based on width:
/// - Mobile (<500px): 1 column
/// - Tablet (500-800px): 2 columns
/// - Desktop (>800px): 3 columns
///
/// Currently uses hardcoded data. Later will fetch from API.
// ═══════════════════════════════════════════════════════════
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

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
        LayoutBuilder(
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
              childAspectRatio: 2.5, // Make cards wider
              children: [
                _buildStatCard(
                  title: 'Watermark Persistence',
                  value: '99.8%',
                  progress: 0.998,
                  color: AppColors.primary,
                ),
                _buildStatCard(
                  title: 'Metadata Encapsulation',
                  value: '94.2%',
                  progress: 0.942,
                  color: AppColors.secondary,
                ),
                _buildStatCard(
                  title: 'Cross-Platform Sync',
                  value: '87.5%',
                  progress: 0.875,
                  color: AppColors.tertiary,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              Text(
                title.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
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
