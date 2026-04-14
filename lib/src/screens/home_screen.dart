import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';
import 'package:indelible/src/screens/sections/hero_section.dart';
import 'package:indelible/src/screens/sections/top_app_bar.dart';
import 'package:indelible/src/screens/sections/stats_grid.dart';
import 'package:indelible/src/screens/sections/quick_actions.dart';
import 'package:indelible/src/screens/sections/recent_assets_list.dart';
import 'package:indelible/src/screens/sections/recent_activity_list.dart';
import 'package:indelible/src/services/auth_service.dart';

/// Main home screen after authentication.
///
/// Assembles reusable sections:
/// - TopAppBar with user info
/// - HeroSection with dynamic username
/// - StatsGrid, QuickActions, RecentAssets, RecentActivity
/// - BottomNavBar for navigation between app sections
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _selectedIndex = 0;
  String _userName = 'Creator';
  String _userInitials = 'CR';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Extracts user name from Firebase Auth and generates initials
  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Creator';
        _userInitials = _getInitials(_userName);
      });
    }
  }

  /// Converts "John Doe" → "JD" or "john@email.com" → "J"
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
      body: SafeArea(
        child: Column(
          children: [
            TopAppBar(userName: _userName, userInitials: _userInitials),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroSection(
                      userName: _userName,
                      accessLevel: 'Curator Access Level Tier III',
                    ),
                    const SizedBox(height: 48),
                    const StatsGrid(),
                    const SizedBox(height: 48),
                    const RecentActivityList(),
                    const SizedBox(height: 48),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 1, child: QuickActions()),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: RecentAssetsList()),
                            ],
                          );
                        } else {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              QuickActions(),
                              SizedBox(height: 24),
                              RecentAssetsList(),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Bottom navigation with 4 tabs: Home, Protect, Detect, Proof
  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('Home', Icons.dashboard, 0),
          _buildNavItem('Protect', Icons.shield, 1),
          _buildNavItem('Detect', Icons.radar, 2),
          _buildNavItem('Proof', Icons.gavel, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () {
        if (index == 0) return;
        if (index == 3) {
          _handleSignOut();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label screen coming soon'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Sign Out', style: GoogleFonts.spaceGrotesk()),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                // AuthGate will rebuild and route to LoginScreen
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
