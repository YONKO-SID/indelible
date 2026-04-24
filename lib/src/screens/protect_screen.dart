import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/themes/app_colors.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════════════════════
/// Protect Screen — Upload an image or video to embed a forensic
/// watermark. Shows a 5-step pipeline visualization that animates
/// as the backend processes the asset.
// ═══════════════════════════════════════════════════════════════
class ProtectScreen extends StatefulWidget {
  const ProtectScreen({super.key});

  @override
  State<ProtectScreen> createState() => _ProtectScreenState();
}

class _ProtectScreenState extends State<ProtectScreen> {
  // ── State ──────────────────────────────────────────────────
  bool _isDragOver = false;
  bool _isProcessing = false;
  int _currentStep = -1; // -1 = idle, 0-4 = pipeline step
  Map<String, dynamic>? _result;
  String? _error;
  String? _selectedFileName;
  List<int>? _selectedFileBytes;

  final AuthService _authService = AuthService();

  static const _steps = [
    ('Upload', 'Sending file to backend', Icons.upload_file_rounded),
    ('Extract', 'FFmpeg frame extraction', Icons.photo_film_rounded),
    ('DWT', 'Wavelet transform (LL-band)', Icons.waves_rounded),
    ('Watermark', 'QIM + HMAC embedding', Icons.fingerprint_rounded),
    ('Store', 'Writing .meta sidecar', Icons.save_rounded),
  ];

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
          _currentStep = -1;
        });
      });
    });
  }

  // ── Protection pipeline ────────────────────────────────────
  Future<void> _protect() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _result = null;
      _currentStep = 0;
    });

    // Animate steps 0-3 locally (visual only — real work is in backend)
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
    }

    try {
      final uid = _authService.currentUser?.uid ?? 'anonymous';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/protect'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _selectedFileBytes!,
        filename: _selectedFileName!,
      ));
      request.fields['user_uid'] = uid;

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          _result = jsonDecode(body) as Map<String, dynamic>;
          _currentStep = 5; // all complete
          _isProcessing = false;
        });
      } else {
        setState(() {
          _error = 'Backend error ${response.statusCode}: $body';
          _currentStep = -1;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed: $e\n\nMake sure the backend is running on port 8000.';
        _currentStep = -1;
        _isProcessing = false;
      });
    }
  }

  void _downloadProtected() {
    final url = _result?['download_url'] as String?;
    if (url == null) return;
    html.AnchorElement(href: url)
      ..setAttribute('download', '')
      ..click();
  }

  void _reset() {
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;
      _result = null;
      _error = null;
      _currentStep = -1;
      _isProcessing = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Protect Asset',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Intro banner ────────────────────────────────
            _InfoBanner(
              icon: Icons.info_outline_rounded,
              color: AppColors.primary,
              text:
                  'Upload your creative asset. INDELIBLE embeds an invisible '
                  'DWT+QIM forensic watermark tied to your unique creator '
                  'fingerprint (INDL-XXXX-XXXX-XXXX). The protected file is '
                  'returned to you with a .meta sidecar for 100% accurate '
                  'future verification.',
            ),
            const SizedBox(height: 28),

            // ── Upload zone ─────────────────────────────────
            _buildUploadZone(),
            const SizedBox(height: 28),

            // ── Pipeline visualization ───────────────────────
            _buildPipeline(),
            const SizedBox(height: 28),

            // ── Error ────────────────────────────────────────
            if (_error != null) _buildErrorCard(),

            // ── Result card ──────────────────────────────────
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  // ── Upload Zone ────────────────────────────────────────────
  Widget _buildUploadZone() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isProcessing ? null : _pickFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
          decoration: BoxDecoration(
            color: _isDragOver
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragOver
                  ? AppColors.primary
                  : _selectedFileName != null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: _isDragOver ? 2 : 1.5,
              style: _selectedFileName != null
                  ? BorderStyle.solid
                  : BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _selectedFileName != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.upload_file_rounded,
                size: 52,
                color: _selectedFileName != null
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _selectedFileName ?? 'Drop file here or click to browse',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _selectedFileName != null
                      ? AppColors.primary
                      : AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFileName != null
                    ? 'Tap the button below to start protection'
                    : 'Supported: JPG · PNG · MP4 · WEBM · MOV',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedFileName != null && !_isProcessing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _protect,
                      icon: const Icon(Icons.shield_rounded, size: 18),
                      label: const Text('Start Protection'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              if (_isProcessing)
                Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Processing...',
                      style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pipeline steps ─────────────────────────────────────────
  Widget _buildPipeline() {
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
            'Protection Pipeline',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Wrap to vertical list on small screens
              if (constraints.maxWidth < 500) {
                return Column(
                  children: List.generate(_steps.length, (i) {
                    return _buildPipelineStepVertical(i);
                  }),
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    // connector
                    final stepIndex = i ~/ 2;
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: stepIndex < _currentStep
                            ? AppColors.primary
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    );
                  }
                  return _buildPipelineStep(i ~/ 2);
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep(int index) {
    final (label, desc, icon) = _steps[index];
    final isCompleted = _currentStep > index;
    final isActive = _currentStep == index;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : isActive
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceContainerHigh,
            border: Border.all(
              color: isCompleted || isActive
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            size: 20,
            color: isCompleted
                ? AppColors.onPrimary
                : isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isCompleted || isActive
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          desc,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPipelineStepVertical(int index) {
    final (label, desc, icon) = _steps[index];
    final isCompleted = _currentStep > index;
    final isActive = _currentStep == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.primary
                  : isActive
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceContainerHigh,
              border: Border.all(
                color: isCompleted || isActive
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              size: 16,
              color: isCompleted
                  ? AppColors.onPrimary
                  : isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isActive
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
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
          TextButton(
            onPressed: _reset,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  // ── Result card ─────────────────────────────────────────────
  Widget _buildResultCard() {
    final fp = _result!['creator_fingerprint'] ?? _result!['creator_id'] ?? '—';
    final hash = _result!['payload_hash'] ?? '—';
    final ts = _result!['timestamp'] ?? '—';
    final tx = _result!['blockchain_tx'] ?? '—';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Success header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset Protected Successfully',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Forensic watermark embedded. Download the protected file.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: 20),

          // ── Forensic data ──
          _DataRow('Creator Fingerprint', fp, mono: true, highlight: true),
          _DataRow('Payload Hash', hash, mono: true),
          _DataRow('Timestamp', ts),
          _DataRow('Blockchain TX', tx, mono: true),
          _DataRow('Message', _result!['message'] ?? '—'),
          const SizedBox(height: 20),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _downloadProtected,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download Protected File'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Protect Another'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ──────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoBanner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
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
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool highlight;
  const _DataRow(this.label, this.value,
      {this.mono = false, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: mono
                  ? GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: highlight ? AppColors.primary : AppColors.onSurface,
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
