import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/themes/app_colors.dart';
import '../services/api_service.dart';
import '../models/asset_log.dart';
import 'layouts/dashboard_layout.dart';

/// Archive Screen — Full list of all protected assets.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final ApiService _api = ApiService();
  late Future<List<AssetLog>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _api.fetchAssetLogs();
  }

  void _download(String url) async {
    // Handle relative URLs
    if (url.startsWith('/')) {
      url = '${ApiService.baseUrl}$url';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/archive',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurfaceVariant, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Asset Archive',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _future = _api.fetchAssetLogs()),
                icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
                tooltip: 'Refresh',
              ),
            ]),
          ),

          // ── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 18),
                ),
                Expanded(child: TextField(
                  style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Filter by filename...',
                    hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none, isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                )),
              ]),
            ),
          ),

          // ── Asset list ────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<AssetLog>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}',
                    style: GoogleFonts.inter(color: AppColors.errorContainer)));
                }
                final all = snapshot.data ?? [];
                final filtered = _search.isEmpty
                    ? all
                    : all.where((a) => a.filename.toLowerCase().contains(_search)).toList();

                if (filtered.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.onSurfaceVariant, size: 48),
                    const SizedBox(height: 16),
                    Text('No assets found', style: GoogleFonts.spaceGrotesk(color: AppColors.onSurfaceVariant, fontSize: 16)),
                  ]));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _buildCard(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AssetLog asset) {
    final isVideo = asset.fileType == 'Video';
    final accentColor = isVideo ? AppColors.tertiary : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          // ── Thumbnail placeholder ──────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isVideo ? Icons.videocam_rounded : Icons.image_rounded,
              color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),

          // ── Metadata ──────────────────────────────────────
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(asset.displayFilename,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Row(children: [
              Text(asset.readableDate, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 12),
              Text('${asset.sizeKb.toStringAsFixed(0)} KB', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ]),
            if (asset.creatorFingerprint != null) ...[
              const SizedBox(height: 6),
              Text(asset.creatorFingerprint!,
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.primary),
                overflow: TextOverflow.ellipsis),
            ],
          ])),

          // ── Download ──────────────────────────────────────
          IconButton(
            onPressed: () => _download(asset.downloadUrl),
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: 'Download',
          ),
        ]),
      ),
    );
  }
}
