import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../config/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════
/// Primary action buttons for core app functions.
///
/// Sends user's Firebase UID to the backend so that a unique
/// cryptographic fingerprint (INDL-XXXX-XXXX-XXXX) is generated
/// and embedded into the DWT-DCT watermark payload.
// ═══════════════════════════════════════════════════════════
class QuickActions extends StatefulWidget {
  const QuickActions({super.key});

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  bool _isLoading = false;

  /// Returns the logged-in user's Firebase UID, or "anonymous" as fallback.
  String get _userUid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  Future<void> _handleUpload(String endpoint, String actionName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isLoading = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Uploading to $actionName engine...'),
             backgroundColor: AppColors.primary,
           ),
        );

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.1.49:8000/$endpoint'),
        );

        // Attach the file
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          result.files.single.bytes!,
          filename: result.files.single.name,
        ));

        // Attach the user's Firebase UID for fingerprint generation
        request.fields['user_uid'] = _userUid;

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          _showResultDialog(actionName, data);
        } else {
          throw Exception('Backend error: ${response.statusCode}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Triggers a real browser download using an anchor element.
  void _downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showResultDialog(String actionName, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          '$actionName Complete',
          style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(data),
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          if (data.containsKey('download_url'))
            TextButton.icon(
              onPressed: () => _downloadFile(data['download_url']),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('DOWNLOAD ASSET'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(Icons.bolt, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            title: 'Protect New Asset',
            subtitle: 'Inject forensic DWT-DCT watermark',
            icon: Icons.shield,
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/protect'),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            title: 'Verify Asset',
            subtitle: 'Extract and decode HMAC hashes',
            icon: Icons.radar,
            color: AppColors.tertiary,
            onTap: () => Navigator.pushNamed(context, '/verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
