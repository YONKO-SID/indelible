import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/themes/app_colors.dart';
import 'layouts/dashboard_layout.dart';
import '../widgets/animations/animation_builders.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoLockEnabled = false;
  final String _currentLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Settings',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('SECURITY'),
            _buildSwitchTile(
              icon: Icons.lock_outline,
              title: 'Auto-Lock Vault',
              subtitle: 'Lock the app after 5 minutes of inactivity',
              value: _autoLockEnabled,
              onChanged: (v) => setState(() => _autoLockEnabled = v),
            ),
            _buildActionTile(
              icon: Icons.key_outlined,
              title: 'API Configuration',
              subtitle: 'Manage your vault access keys',
              onTap: () {},
            ),

            const SizedBox(height: 32),

            _buildSectionHeader('PREFERENCES'),
            _buildSwitchTile(
              icon: Icons.notifications_none,
              title: 'Push Notifications',
              subtitle: 'Receive alerts for asset verifications',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            _buildActionTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: _currentLanguage,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            _buildSectionHeader('SYSTEM'),
            _buildActionTile(
              icon: Icons.info_outline,
              title: 'About Indelible',
              subtitle: 'Version 1.0.0-stable',
              onTap: () {},
            ),
            _buildActionTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Documentation and contact',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SlideInAnimation(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.onSurfaceVariant),
          title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SlideInAnimation(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.onSurfaceVariant),
          title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          trailing: Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
