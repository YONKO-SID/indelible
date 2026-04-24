import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/asset_log.dart';

/// Horizontal scrollable gallery of recently protected assets.
///
/// Fetches real data from backend `/logs` endpoint.
/// Each asset card shows:
/// - File type icon with colored background
/// - File name and size
/// - Protection timestamp
/// - Creator fingerprint (if available)
///
/// Tapping a card will navigate to detailed asset view.
class RecentAssetsList extends StatefulWidget {
  const RecentAssetsList({super.key});

  @override
  State<RecentAssetsList> createState() => _RecentAssetsListState();
}

class _RecentAssetsListState extends State<RecentAssetsList> {
  late Future<List<AssetLog>> _assetsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _assetsFuture = _apiService.fetchAssetLogs();
  }

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
                  'Protected Assets',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Icon(
                  Icons.shield_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AssetLog>>(
              future: _assetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingList();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final assets = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: assets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return _buildAssetCard(assets[index]);
                    },
                  );
                } else {
                  return Center(
                    child: Text(
                      'No assets protected yet',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Shimmer(),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_rounded, color: AppColors.errorContainer, size: 32),
            const SizedBox(height: 12),
            Text(
              'Failed to load assets',
              style: GoogleFonts.inter(
                color: AppColors.errorContainer,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(AssetLog asset) {
    final iconData = asset.fileType == 'Video' ? Icons.videocam : Icons.image;
    final bgColor = asset.fileType == 'Video' ? AppColors.tertiary : AppColors.secondary;

    return Container(
      width: 200,
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
          // Icon header
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                iconData,
                size: 40,
                color: bgColor,
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.displayFilename,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${asset.sizeKb.toStringAsFixed(1)} KB',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (asset.creatorFingerprint != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            asset.creatorFingerprint!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              color: bgColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        asset.relativeTime,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
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

