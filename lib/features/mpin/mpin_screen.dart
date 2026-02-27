import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../core/services/mpin_service.dart';
import '../../routes/app_router.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/custom_button.dart';

class MpinScreen extends ConsumerStatefulWidget {
  const MpinScreen({super.key});

  @override
  ConsumerState<MpinScreen> createState() => _MpinScreenState();
}

class _MpinScreenState extends ConsumerState<MpinScreen> {
  @override
  void initState() {
    super.initState();
    _secureScreen();
  }

  Future<void> _secureScreen() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  Future<void> _releaseScreen() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageWithBlurOff();
  }

  @override
  void dispose() {
    _releaseScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mpinState = ref.watch(mpinProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Midnight Background
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 40.h),

                  FadeInAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Secure Your\nAccount',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  FadeInAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Create a 4-digit security PIN to\nprotect your luxury assets.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),

                  // PIN Display dots
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 300),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool filled = index < mpinState.mpin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: 12.w),
                          height: 18.w,
                          width: 18.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? AppTheme.arcticBlue
                                : (isDark ? Colors.white10 : Colors.black12),
                            boxShadow: filled
                                ? [
                                    BoxShadow(
                                      color:
                                          AppTheme.arcticBlue.withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                        );
                      }),
                    ),
                  ),

                  if (mpinState.error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: Text(
                        mpinState.error!,
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Custom Premium Numpad
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Column(
                        children: [
                          _buildNumRow(['1', '2', '3']),
                          SizedBox(height: 24.h),
                          _buildNumRow(['4', '5', '6']),
                          SizedBox(height: 24.h),
                          _buildNumRow(['7', '8', '9']),
                          SizedBox(height: 24.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(height: 72, width: 72),
                              _buildNumberKey('0'),
                              _buildBackspaceKey(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  FadeInAnimation(
                    delay: const Duration(milliseconds: 500),
                    child: CustomButton(
                      text: 'Set Secure PIN',
                      isLoading: mpinState.isLoading,
                      onPressed: mpinState.isComplete ? _handleSetMpin : null,
                      backgroundColor: mpinState.isComplete
                          ? AppTheme.arcticBlue
                          : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05)),
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSetMpin() async {
    final success = await ref.read(mpinProvider.notifier).setMpin();
    if (success && mounted) {
      // Navigate to home or next step
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
      onTap: () => ref.read(mpinProvider.notifier).addKey(number),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72.w,
        width: 72.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.03),
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 28.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => ref.read(mpinProvider.notifier).backspace(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 72.w,
        width: 72.w,
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 24.sp,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ),
    );
  }
}
