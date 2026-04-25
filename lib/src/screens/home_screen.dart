import 'package:flutter/material.dart';
import 'package:indelible/src/screens/layouts/dashboard_layout.dart';
import 'package:indelible/src/screens/sections/hero_section.dart';
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
    return DashboardLayout(
      currentRoute: '/',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroSection(
              userName: _userName,
              accessLevel: 'Curator Access Level Tier III',
            ),
            const SizedBox(height: 32),
            const StatsGrid(),
            const SizedBox(height: 32),
            // ── Quick Actions + Recent Assets ──────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
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
            const SizedBox(height: 32),
            // ── AI Piracy Scanner ─────────────────────────────
            const PiracyScannerCard(),
            const SizedBox(height: 32),
            // ── Live Upload Logs ──────────────────────────────
            const UploadLogSection(),
          ],
        ),
      ),
    );
  }
}
