import 'package:flutter/material.dart';
import 'left_sidebar.dart';
import 'top_app_bar.dart';
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
    final isDesktop = MediaQuery.of(context).size.width > 900;

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
                TopAppBar(),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
