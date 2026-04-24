import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
          .get(Uri.parse('http://127.0.0.1:8000/logs'))
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
  void _downloadFile(String url) {
    html.AnchorElement(href: url)
      ..setAttribute('download', '')
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protected Asset Logs',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Live index of all watermarked assets on the backend.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 4),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVerified ? Icons.shield_outlined : Icons.help_outline,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // File info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['filename'] as String? ?? '—',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${log['size_kb']} KB  •  Protected ${_formatTime(log['protected_at'])}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Fingerprint
          Expanded(
            flex: 2,
            child: Text(
              fp,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: isVerified ? AppColors.primary : AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Watermark timestamp
          Expanded(
            flex: 2,
            child: Text(
              _formatTime(log['watermark_timestamp'] as String?),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Download button
          IconButton(
            tooltip: 'Download protected asset',
            icon: const Icon(Icons.download, size: 18),
            color: AppColors.primary,
            onPressed: () {
              final url = log['download_url'] as String?;
              if (url != null) _downloadFile(url);
            },
          ),
        ],
      ),
    );
  }
}
