import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════
/// Horizontal scrollable gallery of recently protected assets.
///
/// Each asset card shows:
/// - Thumbnail preview with dark overlay
/// - File name and last verification time
/// - Hash identifier and verification badge
///
/// Tapping a card will navigate to detailed asset view.
// ═══════════════════════════════════════════════════════════
class RecentAssetsList extends StatelessWidget {
  const RecentAssetsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Asset Library Spotlight',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Icon(
                  Icons.movie_creation,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              children: [
                _buildAssetCard(
                  title: 'Visual Genesis.mp4',
                  hash: '0x8F...FF2',
                  timeAgo: 'Last verified 4m ago',
                  imageProvider: const NetworkImage(
                    'https://images.unsplash.com/photo-1593508512255-86ab42a8e620?q=80&w=600&auto=format&fit=crop',
                  ),
                ),
                const SizedBox(width: 16),
                _buildAssetCard(
                  title: 'Campaign_Hero.png',
                  hash: '0x2A...X91',
                  timeAgo: 'Last verified 1h ago',
                  imageProvider: const NetworkImage(
                    'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?q=80&w=600&auto=format&fit=crop',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAssetCard({
    required String title,
    required String hash,
    required String timeAgo,
    required ImageProvider imageProvider,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACTIVE TRACE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HASH: $hash',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Icon(Icons.verified, color: AppColors.primary, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
