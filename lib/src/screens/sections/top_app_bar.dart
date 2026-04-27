import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../../config/themes/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
/// Top application bar with status indicators and profile menu.
class TopAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  State<TopAppBar> createState() => _TopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _TopAppBarState extends State<TopAppBar> {
  bool _isBackendOnline = true;
  Timer? _pingTimer;

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkBackendStatus());
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBackendStatus() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/logs')).timeout(const Duration(seconds: 3));
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
    final showStatusBadge = width > 500;

    return Container(
      height: widget.preferredSize.height,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Logo or Hamburger
          if (isMobile)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: AppColors.onSurface),
            )
          else
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'VAULT',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          const Spacer(),
          
          // Centered Search Bar
          if (showSearchBar)
            Expanded(
              flex: 3,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 18),
                    ),
                    Expanded(
                      child: TextField(
                        style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search archives...',
                          hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Profile / Status
          Row(
            children: [
              if (showStatusBadge && _isBackendOnline)
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
              const SizedBox(width: 20),
              _UserAvatar(),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Standalone user-initial avatar ─────────────────────────────
class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    final name = user?.displayName ?? user?.email?.split('@')[0] ?? 'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != '/profile') {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceContainerHighest,
        child: Text(
          initial,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
