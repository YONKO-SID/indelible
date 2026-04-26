import 'package:flutter/material.dart';
import '../sections/left_sidebar.dart';
import '../sections/top_app_bar.dart';
import '../../config/themes/app_colors.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isDesktop ? null : Drawer(child: LeftSidebar(currentRoute: currentRoute)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) LeftSidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                const TopAppBar(),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        currentIndex: _getSelectedIndex(currentRoute),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'VAULT'),
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security), label: 'PROTECT'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'ACTIVITY'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'SETTINGS'),
        ],
      ),
    );
  }

  int _getSelectedIndex(String route) {
    switch (route) {
      case '/': return 0;
      case '/protect': return 1;
      case '/activity': return 2;
      case '/settings': return 3;
      default: return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    String route = '/';
    switch (index) {
      case 0: route = '/'; break;
      case 1: route = '/protect'; break;
      case 2: route = '/activity'; break;
      case 3: route = '/settings'; break;
    }
    if (currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}
