import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../config/themes/app_colors.dart';
import '../../services/api_service.dart';

/// Action buttons for primary app functions like protecting assets.
class QuickActions extends StatefulWidget {
  const QuickActions({super.key});

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {

  /// Returns the logged-in user's Firebase UID, or "anonymous" as fallback.
  String get _userUid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  Future<void> _handleUpload(String endpoint, String actionName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
      );

      if (result != null && result.files.single.bytes != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading to $actionName engine...'),
              backgroundColor: AppColors.primary,
            ),
          );
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiService.baseUrl}/$endpoint'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  void _downloadFile(String url) async {
    final downloadUrl = url.startsWith('/') ? '${ApiService.baseUrl}$url' : url;
    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIMARY COMMANDS',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          title: 'Upload Media',
          subtitle: 'Encrypted tunnel for new assets',
          icon: Icons.cloud_upload_rounded,
          accentColor: AppColors.tertiary,
          onTap: () => _handleUpload('protect', 'Protection'),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          title: 'Verify Ownership',
          subtitle: 'Blockchain timestamp validation',
          icon: Icons.verified_user_rounded,
          accentColor: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/verify'),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          title: 'Activity Log',
          subtitle: 'Full audit trail & telemetry',
          icon: Icons.history_rounded,
          accentColor: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, '/activity'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left Accent Bar
            Positioned(
              left: 0,
              top: 15,
              bottom: 15,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, color: AppColors.tertiary, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
