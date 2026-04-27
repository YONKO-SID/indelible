import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indelible/src/config/themes/app_colors.dart';
import 'package:indelible/src/screens/layouts/dashboard_layout.dart';
import 'package:indelible/src/screens/sections/hero_section.dart';
import 'package:indelible/src/screens/sections/stats_grid.dart';
import 'package:indelible/src/screens/sections/quick_actions.dart';
import 'package:indelible/src/screens/sections/recent_assets_list.dart';
import 'package:indelible/src/screens/sections/upload_log_section.dart';
import 'package:indelible/src/screens/sections/piracy_scanner_card.dart';
import 'package:indelible/src/services/auth_service.dart';
import 'package:indelible/src/services/api_service.dart';
import 'package:indelible/src/models/alert.dart';
import 'package:indelible/src/screens/sections/piracy_alert_banner.dart';
import 'dart:async';

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
  String _userName = 'Creator';
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  Timer? _alertTimer;
  List<PiracyAlert> _alerts = [];
  bool _isCheckingAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startAlertPolling();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  void _startAlertPolling() {
    // Check for alerts every 15 seconds
    _alertTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkAlerts();
    });
    // Initial check
    _checkAlerts();
  }

  Future<void> _checkAlerts() async {
    final user = _authService.currentUser;
    if (user == null || _isCheckingAlerts) return;

    _isCheckingAlerts = true;
    try {
      final alerts = await _apiService.fetchAlerts(user.uid);
      if (mounted) {
        setState(() {
          _alerts = alerts;
        });
      }
    } catch (e) {
      debugPrint('Error checking alerts: $e');
    } finally {
      _isCheckingAlerts = false;
    }
  }

  void _showDMCAContext(PiracyAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('AI-Generated Takedown Notice',
            style: TextStyle(color: Colors.redAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: Verified via DWT & HMAC',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.dmcaDraft ?? 'No draft generated.',
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              // Mock action
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Takedown Notice Sent to Platform')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Send Notice'),
          ),
        ],
      ),
    );
  }

  /// Extracts user name from Firebase Auth and generates initials
  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Creator';
      });
    }
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
            if (_alerts.isNotEmpty)
              ..._alerts.map((alert) => PiracyAlertBanner(
                    alert: alert,
                    onDismiss: () {
                      setState(() {
                        _alerts.removeWhere((a) => a.id == alert.id);
                      });
                    },
                    onViewDetails: () => _showDMCAContext(alert),
                  )),
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
            // ── Network Status Footer ──────────────────────────
            const SizedBox(height: 48),
            _buildNetworkStatus(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatus() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary, blurRadius: 8, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'NETWORK STATUS: NOMINAL',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatusRow('ENCRYPTION', 'AES-256 GCM'),
          const SizedBox(height: 12),
          _buildStatusRow('LATENCY', '14ms'),
          const SizedBox(height: 12),
          _buildStatusRow('IP ADDR', '192.168.1.104'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: label == 'ENCRYPTION' ? AppColors.tertiary : AppColors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
