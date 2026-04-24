import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';
import 'package:indelible/src/screens/sections/hero_section.dart';
import 'package:indelible/src/screens/sections/top_app_bar.dart';
import 'package:indelible/src/screens/sections/stats_grid.dart';
import 'package:indelible/src/screens/sections/quick_actions.dart';
import 'package:indelible/src/screens/sections/recent_assets_list.dart';
import 'package:indelible/src/screens/sections/upload_log_section.dart';
import 'package:indelible/src/screens/sections/piracy_scanner_card.dart';
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
      drawer: _buildDrawer(),
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
                    // ── Quick Actions + Recent Assets ──────────────────
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
                    const SizedBox(height: 48),
                    // ── AI Piracy Scanner ─────────────────────────────
                    const PiracyScannerCard(),
                    const SizedBox(height: 48),
                    // ── Live Upload Logs ──────────────────────────────
                    const UploadLogSection(),
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surfaceContainer,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(_userInitials, style: GoogleFonts.inter(color: AppColors.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text(_userName, style: GoogleFonts.spaceGrotesk(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppColors.primary),
            title: Text('Dashboard', style: GoogleFonts.inter(color: AppColors.primary)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.onSurfaceVariant),
            title: Text('Settings', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: AppColors.outlineVariant),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.errorContainer),
            title: Text('Sign Out', style: GoogleFonts.inter(color: AppColors.errorContainer)),
            onTap: () {
              Navigator.pop(context);
              _handleSignOut();
            },
          ),
        ],
      ),
    );
  }

  /// Bottom navigation with 4 tabs: Home, Protect, Detect, Proof
  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.05),
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
