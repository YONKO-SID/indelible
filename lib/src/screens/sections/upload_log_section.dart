import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../config/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════
/// Live upload log fetched from the FastAPI /logs endpoint.
///
/// INPUTS: None — auto-refreshes on build and via refresh button.
/// OUTPUT: A table of every protected asset stored on the backend,
///         including its creator fingerprint, watermark timestamp,
///         file size, and a download link.
///
/// Replaces the hardcoded RecentActivityList for real data.
// ═══════════════════════════════════════════════════════════
class UploadLogSection extends StatefulWidget {
  const UploadLogSection({super.key});

  @override
  State<UploadLogSection> createState() => _UploadLogSectionState();
}

class _UploadLogSectionState extends State<UploadLogSection> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  /// Calls the backend /logs endpoint and parses the response.
  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.49:8000/logs'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot reach backend: $e';
        _isLoading = false;
      });
    }
  }

  /// Formats an ISO timestamp string to a readable short form.
  String _formatTime(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} UTC';
    } catch (_) {
      return iso.substring(0, 19);
    }
  }

  /// Triggers a browser download for a protected asset.
  void _downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protected Asset Logs',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Live index of all watermarked assets on the backend.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh logs',
              onPressed: _fetchLogs,
              icon: Icon(
                Icons.refresh,
                color: _isLoading ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Body ────────────────────────────────────────────
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_error != null)
          _buildErrorCard()
        else if (_logs.isEmpty)
          _buildEmptyCard()
        else
          ..._logs.map(_buildLogRow),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorContainer.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.errorContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: AppColors.errorContainer,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _fetchLogs,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                color: AppColors.onSurfaceVariant, size: 40),
            const SizedBox(height: 12),
            Text(
              'No protected assets yet.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
            Text(
              'Use "Protect New Asset" to get started.',
              style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogRow(Map<String, dynamic> log) {
    final fp = log['creator_fingerprint'] as String? ?? 'unknown';
    final isVerified = fp != 'unknown';
    final statusColor = isVerified ? AppColors.primary : AppColors.secondary;
    final filename = log['filename'] as String? ?? '—';
    final sizeKb = log['size_kb']?.toString() ?? '?';
    final downloadUrl = log['download_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor.withValues(alpha: 0.6), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Status Icon ──
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVerified ? Icons.shield_outlined : Icons.help_outline,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // ── Two-row info block ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: filename + size
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        filename,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sizeKb KB',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Row 2: fingerprint + timestamp
                Row(
                  children: [
                    Icon(
                      isVerified ? Icons.verified_outlined : Icons.radio_button_unchecked,
                      size: 11,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        fp,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: isVerified ? AppColors.primary : AppColors.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (log['watermark_timestamp'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formatTime(log['watermark_timestamp'] as String?),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Download Button ──
          if (downloadUrl != null)
            IconButton(
              tooltip: 'Download protected asset',
              icon: const Icon(Icons.download_rounded, size: 18),
              color: AppColors.primary,
              onPressed: () => _downloadFile(downloadUrl),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
