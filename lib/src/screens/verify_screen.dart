import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../config/themes/app_colors.dart';
import 'layouts/dashboard_layout.dart';

// ═══════════════════════════════════════════════════════════════
/// Verify Screen — Upload a suspected piracy copy or your own
/// protected file to run HMAC forensic verification.
///
/// Pipeline:
///   1. DWT extraction of embedded bits
///   2. Reed-Solomon error correction
///   3. HMAC-SHA256 signature check
///   4. Creator registry lookup
// ═══════════════════════════════════════════════════════════════
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  // ── State ──────────────────────────────────────────────────
  bool _isVerifying = false;
  Map<String, dynamic>? _result;
  String? _error;
  String? _selectedFileName;
  List<int>? _selectedFileBytes;

  // ── File picking ───────────────────────────────────────────
  void _pickFile() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*,video/*'
      ..click();

    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = (reader.result as List<int>);
          _result = null;
          _error = null;
        });
      });
    });
  }

  // ── Verification call ──────────────────────────────────────
  Future<void> _verify() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    setState(() {
      _isVerifying = true;
      _error = null;
      _result = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/verify'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _selectedFileBytes!,
        filename: _selectedFileName!,
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          _result = jsonDecode(body) as Map<String, dynamic>;
          _isVerifying = false;
        });
      } else {
        setState(() {
          _error = 'Backend returned ${response.statusCode}: $body';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e\n\nMake sure the backend is running on port 8000.';
        _isVerifying = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;
      _result = null;
      _error = null;
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/verify',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded, color: AppColors.secondary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Verify Ownership',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ── Info banner ─────────────────────────────────
            _buildInfoBanner(),
            const SizedBox(height: 28),

            // ── Two columns on wide screens ──────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 720) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildUploadCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 7, child: _buildHowItWorksCard()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildUploadCard(),
                    const SizedBox(height: 24),
                    _buildHowItWorksCard(),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Error ────────────────────────────────────────
            if (_error != null) _buildErrorCard(),

            // ── Result ───────────────────────────────────────
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppColors.secondary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.secondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upload a file you suspect is a piracy copy — or re-upload your '
              'own protected file to confirm ownership. INDELIBLE runs '
              'DWT+Reed-Solomon extraction and HMAC signature verification '
              'against the creator registry.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload card ────────────────────────────────────────────
  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload File',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isVerifying ? null : _pickFile,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFileName != null
                      ? AppColors.secondary.withValues(alpha: 0.4)
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFileName != null
                        ? Icons.check_circle_outline_rounded
                        : Icons.search_rounded,
                    size: 40,
                    color: _selectedFileName != null
                        ? AppColors.secondary
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFileName ?? 'Tap to select file',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _selectedFileName != null
                          ? AppColors.secondary
                          : AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedFileName != null && !_isVerifying)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _verify,
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Run Verification'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.close,
                      color: AppColors.onSurfaceVariant),
                  tooltip: 'Clear',
                ),
              ],
            ),
          if (_isVerifying)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Running forensic analysis…',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── How it works ───────────────────────────────────────────
  Widget _buildHowItWorksCard() {
    final steps = [
      ('DWT Extraction', 'Discrete Wavelet Transform decodes embedded LL-subband bits.'),
      ('Reed-Solomon', '64-symbol error correction recovers payload even after compression.'),
      ('HMAC Verification', 'SHA-256 signature is checked against SECRET_KEY — unforgeble.'),
      ('Registry Lookup', 'Creator fingerprint matched against creator_registry.json.'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How Verification Works',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final (label, desc) = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Error card ─────────────────────────────────────────────
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppColors.errorContainer.withValues(alpha: 0.6),
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: AppColors.errorContainer,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(onPressed: _reset, child: const Text('Dismiss')),
        ],
      ),
    );
  }

  // ── Result card ─────────────────────────────────────────────
  Widget _buildResultCard() {
    final status = _result!['status'] as String? ?? 'unknown';
    final confidence = _result!['confidence'] as num? ?? 0;
    final proofReport =
        _result!['proof_report'] as Map<String, dynamic>? ?? {};
    final isMatch = status == 'match_found';

    final statusColor = isMatch ? AppColors.primary : AppColors.secondary;
    final statusIcon = isMatch ? Icons.verified_rounded : Icons.gpp_bad_rounded;
    final statusText = isMatch ? 'Match Found — Ownership Verified' : 'No Match — Watermark Not Found';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Confidence: ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(confidence * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: 20),

          // ── Proof report ──
          if (isMatch) ...[
            Text(
              'Forensic Proof Report',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _ProofRow('Creator Fingerprint',
                proofReport['creator_fingerprint'] ?? '—',
                mono: true, highlight: true),
            _ProofRow('Original Timestamp',
                proofReport['original_timestamp'] ?? '—'),
            _ProofRow('HMAC Verified',
                proofReport['hmac_verified']?.toString() ?? '—'),
            _ProofRow('Forensic Strength',
                proofReport['forensic_strength'] ?? '—'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Possible reasons:',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BulletItem('The file was not protected by INDELIBLE.'),
                  _BulletItem(
                      'The file was heavily edited, cropped, or re-encoded beyond RS correction tolerance.'),
                  _BulletItem(
                      'The creator is not registered in the local registry.'),
                  if (proofReport['error'] != null)
                    _BulletItem('Backend detail: ${proofReport['error']}'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Verify Another File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.outlineVariant),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────

class _ProofRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool highlight;
  const _ProofRow(this.label, this.value,
      {this.mono = false, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: mono
                  ? GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color:
                          highlight ? AppColors.secondary : AppColors.onSurface,
                      letterSpacing: 0.8,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant, fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
