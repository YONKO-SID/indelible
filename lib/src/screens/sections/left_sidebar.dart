import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/themes/app_colors.dart';

class LeftSidebar extends StatelessWidget {
  final String currentRoute;

  const LeftSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.surfaceContainerLow,
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'FlareLine', // Mocking the FlareLine style, but maybe we should use Indelible
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader('MENU'),
                _buildNavItem(
                  context: context,
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  route: '/',
                  isActive: currentRoute == '/',
                ),
                _buildNavItem(
                  context: context,
                  title: 'Protect Asset',
                  icon: Icons.security_outlined,
                  route: '/protect',
                  isActive: currentRoute == '/protect',
                ),
                _buildNavItem(
                  context: context,
                  title: 'Verify Asset',
                  icon: Icons.radar_outlined,
                  route: '/verify',
                  isActive: currentRoute == '/verify',
                ),
                _buildNavItem(
                  context: context,
                  title: 'Proof Explorer',
                  icon: Icons.explore_outlined,
                  route: '/proof',
                  isActive: currentRoute == '/proof',
                  isComingSoon: true,
                ),
                
                const SizedBox(height: 32),
                
                _buildSectionHeader('OTHERS'),
                _buildNavItem(
                  context: context,
                  title: 'Profile',
                  icon: Icons.person_outline,
                  route: '/profile',
                  isActive: currentRoute == '/profile',
                ),
                _buildNavItem(
                  context: context,
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  route: '/settings',
                  isActive: currentRoute == '/settings',
                  isComingSoon: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 16, top: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
    required bool isActive,
    bool isComingSoon = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          icon,
          color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {
          if (isComingSoon) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title coming soon'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
            );
            return;
          }
          if (!isActive) {
            if (route == '/') {
               Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
            } else {
               Navigator.of(context).pushReplacementNamed(route);
            }
          }
        },
      ),
    );
  }
}
