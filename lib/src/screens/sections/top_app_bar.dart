import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../../config/themes/app_colors.dart';
import '../../services/auth_service.dart';
// ═══════════════════════════════════════════════════════════
/// Top application bar matching FlareLine style.
/// Displays search bar, status indicators, and profile menu.
// ═══════════════════════════════════════════════════════════
class TopAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  State<TopAppBar> createState() => _TopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _TopAppBarState extends State<TopAppBar> {
  final AuthService _authService = AuthService();
  bool _isBackendOnline = true;
  Timer? _pingTimer;
  String _userName = 'Creator';
  String _userEmail = 'Developer';
  String _userInitials = 'CR';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBackendStatus();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkBackendStatus());
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Creator';
        _userEmail = user.email ?? 'Developer';
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
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBackendStatus() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.49:8000/logs')).timeout(const Duration(seconds: 3));
      if (mounted && !_isBackendOnline && response.statusCode == 200) {
        setState(() => _isBackendOnline = true);
      } else if (mounted && response.statusCode != 200) {
        setState(() => _isBackendOnline = false);
      }
    } catch (_) {
      if (mounted && _isBackendOnline) {
        setState(() => _isBackendOnline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final showSearchBar = width > 700;
    final showIcons = width > 600;
    final showStatusBadge = width > 500;

    return Container(
      height: widget.preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
          ],
          
          // Search Bar
          if (showSearchBar)
            Expanded(
              child: Container(
                height: 40,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        style: GoogleFonts.inter(color: AppColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search or type keyword',
                          hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!showSearchBar) const Spacer(),
          if (showSearchBar) const Spacer(),

          // Backend Status Badge
          if (showStatusBadge) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isBackendOnline 
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isBackendOnline ? AppColors.success : AppColors.errorContainer,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isBackendOnline ? AppColors.success : AppColors.errorContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isBackendOnline ? 'System Online' : 'System Offline',
                    style: GoogleFonts.inter(
                      color: _isBackendOnline ? AppColors.success : AppColors.errorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Icons
          if (showIcons) ...[
            _buildIconButton(Icons.light_mode_outlined),
            const SizedBox(width: 12),
            _buildIconButton(Icons.notifications_none_outlined, hasBadge: true),
            const SizedBox(width: 12),
            _buildIconButton(Icons.chat_bubble_outline_rounded),
            const SizedBox(width: 20),
          ],

          // Profile
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            child: Row(
              children: [
                if (width > 600) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userName,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _userEmail,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _userInitials,
                    style: GoogleFonts.inter(
                      color: AppColors.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {bool hasBadge = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          if (hasBadge)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
