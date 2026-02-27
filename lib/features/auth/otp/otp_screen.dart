import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String otpSessionId;

  const OtpScreen({
    super.key,
    required this.mobile,
    required this.otpSessionId,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  int _timerSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  void _startTimer() {
    setState(() => _timerSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _releaseScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 68.h,
      textStyle: GoogleFonts.outfit(
        fontSize: 26.sp,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12, width: 1),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Midnight Background Layer
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22.sp),
                    onPressed: () => Navigator.pop(context),
                  ),

                  SizedBox(height: 32.h),

                  FadeInAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Verify Your\nIdentity',
                      style: GoogleFonts.outfit(
                        fontSize: 42.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.05,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  FadeInAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 17.sp,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          const TextSpan(text: 'Security code dispatched to '),
                          TextSpan(
                            text: widget.mobile,
                            style: TextStyle(
                              color: AppTheme.arcticBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),

                  // High-End 6-Box Input
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 300),
                    child: Pinput(
                      length: 6,
                      controller: _otpController,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          color: isDark
                              ? AppTheme.arcticBlue.withOpacity(0.08)
                              : Colors.white,
                          border:
                              Border.all(color: AppTheme.arcticBlue, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.arcticBlue.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      onCompleted: _verifyOtp,
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Interactive Feedback
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _timerSeconds > 0
                            ? Text(
                                'Request new code in ${_timerSeconds}s',
                                style: GoogleFonts.outfit(
                                  color: Colors.grey,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : TextButton(
                                onPressed: _startTimer,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.arcticBlue,
                                ),
                                child: Text(
                                  'Resend Verification Now',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
                              ),
                      ],
                    ),
                  ),

                  if (authState.error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 32.h),
                      child: Center(
                        child: Text(authState.error!,
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),

                  const Spacer(),

                  FadeInAnimation(
                    delay: const Duration(milliseconds: 500),
                    child: CustomButton(
                      text: 'Confirm & Finalize',
                      isLoading: authState.isLoading,
                      onPressed: _otpController.text.length == 6
                          ? () => _verifyOtp(_otpController.text)
                          : null,
                      backgroundColor: _otpController.text.length == 6
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

  Future<void> _verifyOtp(String otp) async {
    final success = await ref.read(authProvider.notifier).verifyOtp(
          widget.mobile,
          otp,
          widget.otpSessionId,
        );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else {
      _otpController.clear();
      //this is for testing purpose
      Navigator.pushReplacementNamed(context, AppRouter.mpin);
    }
  }
}
