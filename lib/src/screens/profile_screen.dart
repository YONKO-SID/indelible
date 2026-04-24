import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/themes/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/protection_stats.dart';
import '../widgets/animations/animation_builders.dart';

/// Enhanced Profile Screen with real user stats and smooth animations
///
/// Features:
/// - User avatar with stats summary
/// - Real protection statistics
/// - Advanced security settings
/// - Animated transitions
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  late Future<ProtectionStats> _statsFuture;
  
  String _userName = 'Creator';
  String _userEmail = 'creator@indelible.io';
  String _userInitials = 'CR';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _statsFuture = _apiService.fetchProtectionStats();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Creator';
        _userEmail = user.email ?? 'No email provided';
        _userInitials = _getInitials(_userName);
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
        title: Text(
          'Profile & Statistics',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile header with stats
            SlideInAnimation(
              child: _buildProfileHeader(),
            ),
            const SizedBox(height: 48),

            // Real statistics section
            SlideInAnimation(
              duration: const Duration(milliseconds: 700),
              begin: const Offset(0, 0.3),
              child: _buildStatsSection(),
            ),
            const SizedBox(height: 48),

            // Security settings
            SlideInAnimation(
              duration: const Duration(milliseconds: 900),
              begin: const Offset(0, 0.3),
              child: _buildSecuritySettings(),
            ),
            const SizedBox(height: 48),

            // Advanced options
            SlideInAnimation(
              duration: const Duration(milliseconds: 1100),
              begin: const Offset(0, 0.3),
              child: _buildAdvancedOptions(),
            ),
            const SizedBox(height: 48),

            // Sign out button
            SlideInAnimation(
              duration: const Duration(milliseconds: 1300),
              begin: const Offset(0, 0.3),
              child: _buildSignOutButton(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with pulse animation
        PulseAnimation(
          duration: const Duration(seconds: 3),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _userInitials,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _userName,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _userEmail,
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protection Statistics',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<ProtectionStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stats = snapshot.data!;
              return StaggeredListAnimation(
                itemDelay: const Duration(milliseconds: 100),
                children: [
                  _buildStatRow(
                    'Total Assets Protected',
                    stats.totalAssets.toString(),
                    Icons.shield_rounded,
                    AppColors.primary,
                  ),
                  _buildStatRow(
                    'Successful Verifications',
                    stats.successfulVerifications.toString(),
                    Icons.verified_user_rounded,
                    AppColors.secondary,
                  ),
                  _buildStatRow(
                    'Success Rate',
                    '${stats.successRate.toStringAsFixed(1)}%',
                    Icons.trending_up_rounded,
                    AppColors.tertiary,
                  ),
                  _buildStatRow(
                    'Storage Used',
                    stats.storageDisplay,
                    Icons.storage_rounded,
                    AppColors.primary.withValues(alpha: 0.7),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load statistics',
                  style: GoogleFonts.inter(color: AppColors.errorContainer),
                ),
              );
            } else {
              return Column(
                children: List.generate(4, (index) => const Shimmer()),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Settings',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingTile(
          icon: Icons.key_rounded,
          title: 'Forensic Keys & Wallet',
          subtitle: 'Manage your DWT-DCT secret keys',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Key management coming soon',
                  style: GoogleFonts.inter(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          icon: Icons.gavel_rounded,
          title: 'Legal Auto-Takedown',
          subtitle: 'Configure automated C&D settings',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Takedown configuration coming soon',
                  style: GoogleFonts.inter(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Options',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingTile(
          icon: Icons.history_rounded,
          title: 'Audit Log Export',
          subtitle: 'Download complete system traces',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Export feature coming soon',
                  style: GoogleFonts.inter(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          icon: Icons.delete_forever_rounded,
          title: 'Delete Account',
          subtitle: 'Permanently remove all your data',
          onTap: () {
            _showDeleteConfirmation();
          },
          isDanger: true,
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? AppColors.errorContainer : AppColors.primary;

    return ScaleInAnimation(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
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
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          await _authService.signOut();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        },
        icon: const Icon(Icons.logout, color: AppColors.errorContainer),
        label: Text(
          'SIGN OUT',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.errorContainer,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.errorContainer),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          'Delete Account?',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account deletion not yet implemented',
                    style: GoogleFonts.inter(),
                  ),
                ),
              );
            },
            child: Text(
              'Delete',
              style: GoogleFonts.spaceGrotesk(color: AppColors.errorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) => Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            color: AppColors.surfaceBright.withValues(alpha: _opacity.value),
          ),
        ),
      ),
    );
  }
}
