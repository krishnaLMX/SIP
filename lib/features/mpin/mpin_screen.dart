import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../core/services/mpin_service.dart';
import '../../routes/app_router.dart';
import '../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/custom_button.dart';

class MpinScreen extends ConsumerStatefulWidget {
  const MpinScreen({super.key});

  @override
  ConsumerState<MpinScreen> createState() => _MpinScreenState();
}

class _MpinScreenState extends ConsumerState<MpinScreen>
    with WidgetsBindingObserver {
  List<String> _shuffledNumbers = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shuffleKeypad();
    _secureScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shuffleKeypad();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _shuffleKeypad();
    }
  }

  void _shuffleKeypad() {
    final List<String> digits = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9'
    ];
    digits.shuffle();
    if (mounted) {
      setState(() {
        _shuffledNumbers = List.from(digits);
      });
    }
    debugPrint('MPIN Numpad Randomized: $_shuffledNumbers');
  }

  Future<void> _secureScreen() async {
    if (!kIsWeb) {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    }
  }

  Future<void> _releaseScreen() async {
    if (!kIsWeb) {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageWithBlurOff();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mpinState = ref.watch(mpinProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0B1120), const Color(0xFF020617)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: Stack(
          children: [
            // 2. Animated Background Aurora Orbs (Abstract Luxury)
            if (isDark) ...[
              _buildAuroraOrb(
                  top: -100.h,
                  right: -100.w,
                  color: AppTheme.arcticBlue.withOpacity(0.12),
                  size: 450.w),
              _buildAuroraOrb(
                  bottom: -150.h,
                  left: -100.w,
                  color: AppTheme.auroraPurple.withOpacity(0.08),
                  size: 500.w),
            ],

            SafeArea(
              bottom: true,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        key: ValueKey(_shuffledNumbers.join()),
                        children: [
                          SizedBox(height: 32.h),

                          // Center-Aligned Luxury Branding
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 100),
                            child: Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/header.png',
                                    height: 40.h,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    AppConstants.companyName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 5.0,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 40.h),

                          // 3. Luxury Branding Header
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 100),
                            child: Column(
                              children: [
                                Text(
<<<<<<< HEAD
                                  AppConstants.mpinTitle,
=======
                                  'SECURE YOUR VAULT',
>>>>>>> parent of 388af03 (Register page and Mpin settings page configure)
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
<<<<<<< HEAD
                                  AppConstants.mpinSubtitle,
=======
                                  'Create your 4-digit signature to authorize encrypted transactions.',
>>>>>>> parent of 388af03 (Register page and Mpin settings page configure)
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black45,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 28.h),

                          // 4. Premium Glowing PIN Indicators
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 300),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                bool filled = index < mpinState.mpin.length;
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(
                                      begin: 1.0, end: filled ? 1.2 : 1.0),
                                  duration: const Duration(milliseconds: 200),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 14.w),
                                        height: 16.w,
                                        width: 16.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: filled
                                              ? AppTheme.arcticBlue
                                              : (isDark
                                                  ? Colors.white
                                                      .withOpacity(0.1)
                                                  : Colors.black
                                                      .withOpacity(0.05)),
                                          boxShadow: filled
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.arcticBlue
                                                        .withOpacity(0.6),
                                                    blurRadius: 20,
                                                    spreadRadius: 2,
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    blurRadius: 5,
                                                  )
                                                ]
                                              : [],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                          ),

                          if (mpinState.error != null)
                            _buildErrorMessage(mpinState.error!),

                          SizedBox(height: 32.h),

                          // 5. Glassmorphic Keypad Card
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 400),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32.r),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  key: UniqueKey(),
                                  padding: EdgeInsets.all(24.w),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.035)
                                        : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(32.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.black.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildNumRow(
                                          _shuffledNumbers.sublist(0, 3)),
                                      SizedBox(height: 20.h),
                                      _buildNumRow(
                                          _shuffledNumbers.sublist(3, 6)),
                                      SizedBox(height: 20.h),
                                      _buildNumRow(
                                          _shuffledNumbers.sublist(6, 9)),
                                      SizedBox(height: 20.h),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildBiometricHint(),
                                          _buildNumberKey(_shuffledNumbers[9]),
                                          _buildBackspaceKey(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),

                  // 8. CTA Section (Matches Login Screen)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                    child: FadeInAnimation(
                      delay: const Duration(milliseconds: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomButton(
                            text: 'ACTIVATE SECURE PIN',
                            isLoading: mpinState.isLoading,
                            onPressed:
                                mpinState.isComplete ? _handleSetMpin : null,
                            backgroundColor: mpinState.isComplete
                                ? AppTheme.arcticBlue
                                : (isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05)),
                          ),

                          SizedBox(height: 28.h),

                          // Auth Verification Row + Forgot PIN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  size: 16.sp, color: AppTheme.electricCyan),
                              SizedBox(width: 10.w),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Forgot PIN?',
                                  style: GoogleFonts.outfit(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuroraOrb(
      {double? top,
      double? right,
      double? bottom,
      double? left,
      required Color color,
      required double size}) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Text(
        error,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 13.sp),
      ),
    );
  }

  Widget _buildBiometricHint() {
    return SizedBox(
      height: 68.w,
      width: 68.w,
      child: Center(
          child: Icon(Icons.fingerprint, color: Colors.white24, size: 28.sp)),
    );
  }

  Future<void> _handleSetMpin() async {
    debugPrint('Attempting to set MPIN... Current pattern: $_shuffledNumbers');
    final success = await ref.read(mpinProvider.notifier).setMpin();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else {
      _shuffleKeypad();
      // this is for testing purpose
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  Widget _buildNumRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumberKey(n)).toList(),
    );
  }

  Widget _buildNumberKey(String number) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: () => ref.read(mpinProvider.notifier).addKey(number),
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 68.w,
            width: 68.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 1,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.01),
                        blurRadius: 10,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.outfit(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackspaceKey() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(mpinProvider.notifier).backspace();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 68.w,
        width: 68.w,
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 26.sp,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
      ),
    );
  }
}
