import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../sections/left_sidebar.dart';
import '../sections/top_app_bar.dart';
import '../../config/themes/app_colors.dart';
import '../../services/auth_service.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool isMenuOpen = false;
  final AuthService _authService = AuthService();

  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    if (isDesktop) {
      // Classic Desktop Layout
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LeftSidebar(currentRoute: widget.currentRoute),
            Expanded(
              child: Column(
                children: [
                  const TopAppBar(),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Slide-out Drawer Menu Layout for Mobile / Tablet
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // --- LAYER 1: Hidden Slide Menu Drawer ---
          _buildHiddenDrawer(context),

          // --- LAYER 2: Main Content Card ---
          _buildMainContentCard(context),
        ],
      ),
    );
  }

  Widget _buildHiddenDrawer(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            AppColors.surfaceContainerLow,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Logo / Title
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 32.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'INDELIBLE',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerHeader('MENU'),
                    _buildDrawerTile(
                      title: 'Dashboard',
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      route: '/dashboard',
                    ),
                    _buildDrawerTile(
                      title: 'Vault',
                      icon: Icons.shield_outlined,
                      activeIcon: Icons.shield,
                      route: '/vault',
                    ),
                    _buildDrawerTile(
                      title: 'Protect Asset',
                      icon: Icons.security_outlined,
                      activeIcon: Icons.security,
                      route: '/protect',
                    ),
                    _buildDrawerTile(
                      title: 'Verify Asset',
                      icon: Icons.radar_outlined,
                      activeIcon: Icons.radar,
                      route: '/verify',
                    ),
                    _buildDrawerHeader('OTHERS'),
                    _buildDrawerTile(
                      title: 'Profile',
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      route: '/profile',
                    ),
                    _buildDrawerTile(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      route: '/settings',
                    ),
                  ],
                ),
              ),

              // Bottom User Profile Info & Sign Out
              const Divider(color: AppColors.outline, height: 1),
              const SizedBox(height: 16),
              _buildBottomProfileSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required String route,
  }) {
    final isActive = widget.currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          toggleMenu();
          if (!isActive) {
            if (route == '/vault') {
              Navigator.of(context).pushNamedAndRemoveUntil('/vault', (r) => false);
            } else {
              Navigator.of(context).pushReplacementNamed(route);
            }
          }
        },
      ),
    );
  }

  Widget _buildBottomProfileSection(BuildContext context) {
    final user = _authService.currentUser;
    final name = user?.displayName ?? user?.email?.split('@')[0] ?? 'Creator';
    final email = user?.email ?? 'creator@indelible.io';

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceContainerHighest,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                email,
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.errorContainer,
            size: 20,
          ),
          tooltip: 'Sign Out',
          onPressed: () async {
            toggleMenu();
            final navigator = Navigator.of(context);
            await _authService.signOut();
            navigator.pushReplacementNamed('/auth');
          },
        ),
      ],
    );
  }

  Widget _buildMainContentCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // Apply Matrix4 Translation and Scaling on open (using non-deprecated APIs)
      transform: isMenuOpen
          ? (Matrix4.translationValues(240.0, 40.0, 0.0) *
              Matrix4.diagonal3Values(0.82, 0.82, 1.0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(isMenuOpen ? 24 : 0),
        border: isMenuOpen
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
        boxShadow: isMenuOpen
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMenuOpen ? 24 : 0),
        child: Stack(
          children: [
            // The actual page Scaffold
            Scaffold(
              backgroundColor: AppColors.surface,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: TopAppBar(
                  onMenuPressed: toggleMenu,
                ),
              ),
              body: widget.child,
              bottomNavigationBar: BottomNavigationBar(
                backgroundColor: AppColors.surfaceContainerLow,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.onSurfaceVariant,
                type: BottomNavigationBarType.fixed,
                currentIndex: _getSelectedIndex(widget.currentRoute),
                onTap: (index) => _onItemTapped(context, index),
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.shield_outlined),
                      activeIcon: Icon(Icons.shield),
                      label: 'VAULT'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.security_outlined),
                      activeIcon: Icon(Icons.security),
                      label: 'PROTECT'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.analytics_outlined),
                      activeIcon: Icon(Icons.analytics),
                      label: 'ACTIVITY'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings),
                      label: 'SETTINGS'),
                ],
              ),
            ),

            // Tap-to-Close overlay and slight dimming
            if (isMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: toggleMenu,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getSelectedIndex(String route) {
    switch (route) {
      case '/vault':
        return 0;
      case '/protect':
        return 1;
      case '/activity':
        return 2;
      case '/settings':
        return 3;
      default:
        // Dashboard and other routes don't correspond to a bottom tab — clamp to 0
        return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    String route;
    switch (index) {
      case 0:
        route = '/vault';
        break;
      case 1:
        route = '/protect';
        break;
      case 2:
        route = '/activity';
        break;
      case 3:
        route = '/settings';
        break;
      default:
        route = '/vault';
    }
    if (widget.currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}
