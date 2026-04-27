import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Premium auto-sliding image carousel with smooth page transitions,
/// animated dot indicators, and a parallax-like entrance effect.
///
/// Used in the "Learn Something New" section of the Home screen.
class LearnCarousel extends StatefulWidget {
  /// List of asset image paths to display.
  final List<String> images;

  /// Auto-slide interval in seconds.
  final int autoSlideSeconds;

  const LearnCarousel({
    super.key,
    required this.images,
    this.autoSlideSeconds = 4,
  });

  @override
  State<LearnCarousel> createState() => _LearnCarouselState();
}

class _LearnCarouselState extends State<LearnCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);

    // Progress bar animation — fills over autoSlideSeconds duration
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.autoSlideSeconds),
    );

    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _progressController.forward(from: 0);
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(
      Duration(seconds: widget.autoSlideSeconds),
      (_) => _nextPage(),
    );
  }

  void _nextPage() {
    if (!mounted) return;
    final next = (_currentPage + 1) % widget.images.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    _progressController.forward(from: 0);
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    // Reset timer on manual swipe
    _startAutoSlide();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // ── Image Carousel ──
        Container(
          height: 180.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.images.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    // Parallax + scale effect during swipe
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      final page = _pageController.page ?? _currentPage.toDouble();
                      value = (1 - (page - index).abs() * 0.15).clamp(0.85, 1.0);
                    }
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: _buildImage(widget.images[index]),
                );
              },
            ),
          ),
        ),

        SizedBox(height: 14.h),

        // ── Dot indicators with progress bar ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: isActive ? 28.w : 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.r),
                color: isActive
                    ? Colors.transparent
                    : const Color(0xFFD4A84B).withValues(alpha: 0.3),
              ),
              child: isActive
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100.r),
                      child: Stack(
                        children: [
                          // Track background
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.r),
                              color: const Color(0xFFD4A84B).withValues(alpha: 0.25),
                            ),
                          ),
                          // Animated fill
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (_, __) {
                              return FractionallySizedBox(
                                widthFactor: _progressController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100.r),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD4A84B),
                                        Color(0xFFF0A500),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : null,
            );
          }),
        ),
      ],
    );
  }

  /// Renders an image from either an asset path or a network URL.
  Widget _buildImage(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');

    final errorWidget = Container(
      color: const Color(0xFFF5F0E8),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.amber, size: 40),
      ),
    );

    if (isNetwork) {
      return Image.network(
        path,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFF5F0E8),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD4A84B),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => errorWidget,
      );
    }

    return Image.asset(
      path,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => errorWidget,
    );
  }
}
