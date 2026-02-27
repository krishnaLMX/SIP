import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/security/session_manager.dart';
import '../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingModel> _pages = [
    OnboardingModel(
      title: 'Artisanal Security',
      description:
          'Your wealth, protected by the most advanced digital vault system.',
      image:
          'file:///C:/Users/admin/.gemini/antigravity/brain/ef876d95-299c-4dcc-8e4f-15ccc4594d12/diamond_necklace_onboarding_1772104068669.png',
    ),
    OnboardingModel(
      title: 'Digital Gold Rush',
      description: 'Liquidate and grow your jewelry portfolio in a few taps.',
      image:
          'file:///C:/Users/admin/.gemini/antigravity/brain/ef876d95-299c-4dcc-8e4f-15ccc4594d12/gold_ring_onboarding_1772104089487.png',
    ),
    OnboardingModel(
      title: 'Elite Prosperity',
      description:
          'Exquisite investment opportunities curated for the modern elite.',
      image:
          'file:///C:/Users/admin/.gemini/antigravity/brain/ef876d95-299c-4dcc-8e4f-15ccc4594d12/pearl_earrings_onboarding_1772104110146.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(data: _pages[index]);
            },
          ),

          // Navigation & Progress Layer
          Positioned(
            bottom: 60.h,
            left: 24.w,
            right: 24.w,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => buildDot(index, isDark),
                  ),
                ),
                SizedBox(height: 48.h),
                CustomButton(
                  text: _currentPage == _pages.length - 1
                      ? 'Begin Your Legacy'
                      : 'Advance Forward',
                  backgroundColor: AppTheme.arcticBlue,
                  onPressed: () async {
                    if (_currentPage == _pages.length - 1) {
                      await SessionManager.setOnboardingSeen();
                      if (mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRouter.login,
                        );
                      }
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.fastOutSlowIn,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 12.w),
      height: 4.h,
      width: _currentPage == index ? 32.w : 12.w,
      decoration: BoxDecoration(
        gradient: _currentPage == index
            ? LinearGradient(
                colors: [AppTheme.arcticBlue, AppTheme.electricCyan])
            : null,
        color: _currentPage == index ? null : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(100.r),
        boxShadow: _currentPage == index
            ? [
                BoxShadow(
                  color: AppTheme.arcticBlue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
    );
  }
}

class OnboardingModel {
  final String title, description, image;
  OnboardingModel({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingModel data;
  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Premium Background Image
        Positioned.fill(
          child: Image.network(
            data.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.midnightNavy,
              child: const Icon(Icons.image_outlined,
                  color: Colors.white24, size: 80),
            ),
          ),
        ),

        // Kinetic Gradient Bloom
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Glassmorphic Content Card
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 220.h, left: 24.w, right: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeInAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    data.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                FadeInAnimation(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 17.sp,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
