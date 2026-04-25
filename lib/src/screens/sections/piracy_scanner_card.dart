import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/themes/app_colors.dart';
import '../../services/api_service.dart';

// ═══════════════════════════════════════════════════════════
/// AI-powered piracy scanner card.
///
/// INPUTS: A URL entered by the user (e.g. a social media post).
/// OUTPUT: Gemini AI classification (is_pirated, confidence, reasoning)
///         and an auto-generated DMCA takedown notice if piracy is detected.
///
/// Calls the backend POST /scan-piracy endpoint.
// ═══════════════════════════════════════════════════════════
class PiracyScannerCard extends StatefulWidget {
  const PiracyScannerCard({super.key});

  @override
  State<PiracyScannerCard> createState() => _PiracyScannerCardState();
}

class _PiracyScannerCardState extends State<PiracyScannerCard> {
  final _urlController = TextEditingController();
  bool _isScanning = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Sends the URL to the backend /scan-piracy endpoint.
  Future<void> _startScan() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a URL to scan.');
      return;
    }
    setState(() {
      _isScanning = true;
      _result = null;
      _error = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/scan-piracy'),
      );
      request.fields['url'] = url;

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        setState(() {
          _result = jsonDecode(response.body) as Map<String, dynamic>;
          _isScanning = false;
        });
      } else {
        throw Exception('Backend returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Scan failed: $e';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.tertiary.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Piracy Scanner',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'GEMINI 2.5',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppColors.tertiary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter any URL — our AI will scrape it, analyze media for piracy, '
            'and auto-generate a DMCA notice if infringement is detected.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── URL Input ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'https://example.com/suspicious-post',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.tertiary),
                    ),
                    prefixIcon: const Icon(Icons.language, color: AppColors.onSurfaceVariant),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _startScan(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : const Icon(Icons.radar, size: 18),
                  label: Text(
                    _isScanning ? 'SCANNING...' : 'SCAN',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // ── Error ───────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.inter(
                color: AppColors.errorContainer,
                fontSize: 13,
              ),
            ),
          ],

          // ── Results ─────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResults(_result!),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(Map<String, dynamic> data) {
    final aiAnalysis = data['ai_analysis'] as Map<String, dynamic>? ?? {};
    final isPirated = aiAnalysis['is_pirated'] as bool? ?? false;
    final confidence = ((aiAnalysis['confidence'] as num?)?.toDouble() ?? 0.0);
    final reasoning = aiAnalysis['reasoning'] as String? ?? '—';
    final legal = data['legal_notice_draft'] as String?;
    final mocked = data['mocked'] as bool? ?? false;

    final statusColor = isPirated ? AppColors.errorContainer : AppColors.primary;
    final statusLabel = isPirated ? 'PIRACY DETECTED' : 'NO PIRACY FOUND';
    final statusIcon = isPirated ? Icons.gavel : Icons.verified_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: GoogleFonts.spaceGrotesk(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}% confidence',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              if (mocked) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'MOCK',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: AppColors.secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Reasoning
          Text(
            'AI Reasoning:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            reasoning,
            style: GoogleFonts.inter(
              color: AppColors.onSurface,
              fontSize: 13,
            ),
          ),

          // DMCA notice
          if (legal != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.article_outlined,
                    color: AppColors.errorContainer, size: 16),
                const SizedBox(width: 8),
                Text(
                  'AUTO-GENERATED DMCA TAKEDOWN NOTICE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: AppColors.errorContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                legal,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
