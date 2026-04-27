import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/asset_log.dart';

/// Horizontal gallery of recently protected assets.
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Assets',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/archive'),
                child: Text(
                  'VIEW ARCHIVE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tertiary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<AssetLog>>(
            future: _assetsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingList();
              } else if (snapshot.hasError) {
                return _buildErrorWidget(snapshot.error.toString());
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final assets = snapshot.data!.take(3).toList();
                return Column(
                  children: assets.map((asset) => _buildAssetItem(asset)).toList(),
                );
              } else {
                return const Center(child: Text('No assets yet'));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem(AssetLog asset) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://picsum.photos/100'), // Placeholder for asset image
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.displayFilename,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SHA-256: ${asset.creatorFingerprint ?? '8f2a...d9e1'}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
          child: const Shimmer(),
        ),
      )),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Text('Error: $error', style: const TextStyle(color: AppColors.errorContainer));
  }
}

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
      decoration: BoxDecoration(color: AppColors.surfaceBright.withValues(alpha: _opacity.value), borderRadius: BorderRadius.circular(12)),
    ));
  }
}
