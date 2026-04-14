import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indelible/src/config/themes/app_colors.dart';
import 'package:indelible/src/screens/intro_screens/intro_screen1.dart';
import 'package:indelible/src/screens/intro_screens/intro_screen2.dart';
import 'package:indelible/src/screens/intro_screens/intro_screen3.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Marks onboarding as complete and triggers AuthGate rebuild
  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      // AuthGate will rebuild and route to LoginScreen
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = (index == 2);
              });
            },
            children: const [IntroScreen1(), IntroScreen2(), IntroScreen3()],
          ),

          // Bottom navigation row
          Container(
            alignment: const Alignment(0, 0.85),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.surfaceContainerHigh,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 8,
                    ),
                  ),

                  // Next / Done Button
                  GestureDetector(
                    onTap: () {
                      if (_isLastPage) {
                        _finishOnboarding();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isLastPage
                            ? AppColors.tertiary
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isLastPage
                                        ? AppColors.tertiary
                                        : AppColors.primary)
                                    .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _isLastPage ? 'Finish' : 'Next',
                        style: GoogleFonts.spaceGrotesk(
                          color: _isLastPage
                              ? AppColors.onSurface
                              : AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
