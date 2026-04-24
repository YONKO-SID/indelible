import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';

// ═══════════════════════════════════════════════════════════
/// Top application bar with navigation links and user profile.
///
/// Displays:
/// - App logo and navigation menu
/// - User initials avatar
/// - Navigation links (Dashboard, Ledger, Security, Settings)
///
/// Implements PreferredSizeWidget to work with Scaffold.appBar.
// ═══════════════════════════════════════════════════════════
class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Display name shown next to user initials
  final String userName;

  /// Two-letter initials shown in profile avatar
  final String userInitials;

  const TopAppBar({super.key, this.userName = 'User', this.userInitials = 'U'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.67),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu),
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Text(
                  'Indelible',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Navigation links (hidden on smaller screens)
            if (MediaQuery.of(context).size.width > 800) ...[
              Row(
                children: [
                  _buildNavLink('Dashboard', isActive: true),
                  _buildNavLink('Ledger'),
                  _buildNavLink('Security'),
                  _buildNavLink('Settings'),
                ],
              ),
            ],
            const SizedBox(width: 24),
            // User Profile
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/profile');
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    userInitials,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String title, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
