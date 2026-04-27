import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/session_manager.dart';
import '../../core/services/content_service.dart';
import '../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingContentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: onboardingAsync.when(
        data: (slides) {
          final pages = slides.isNotEmpty
              ? slides
                  .map((slide) => OnboardingModel(
                        title: slide['title'] ?? '',
                        description: slide['desc'] ?? '',
                        image: slide['image'] ?? '',
                      ))
                  .toList()
              : [
                  OnboardingModel(
                    title: 'Artisanal Security',
                    description:
                        'Your wealth, protected by the most advanced digital vault system.',
                    image: 'https://cdn.gold.com/slides/1.png',
                  ),
                ];

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(data: pages[index]);
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
                        pages.length,
                        (index) => buildDot(index, pages.length, isDark),
                      ),
                    ),
                    SizedBox(height: 48.h),
                    CustomButton(
                      text: _currentPage == pages.length - 1
                          ? 'Begin Your Legacy'
                          : 'Advance Forward',
                      svgIconPath: 'assets/buttons/getstart.svg',
                      gradient: AppTheme.greenGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      onPressed: () async {
                        if (_currentPage == pages.length - 1) {
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
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.arcticBlue),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16.h),
              Text(
                'Failed to load content',
                style: GoogleFonts.lora(color: Colors.white, fontSize: 18.sp),
              ),
              TextButton(
                onPressed: () => ref.refresh(onboardingContentProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDot(int index, int total, bool isDark) {
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
                    style: GoogleFonts.lora(
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
                    style: GoogleFonts.lora(
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

