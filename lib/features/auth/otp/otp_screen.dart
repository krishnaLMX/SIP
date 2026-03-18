import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:screen_protector/screen_protector.dart';
import '../controller/auth_controller.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/theme/app_theme.dart';

import '../../../core/localization/language_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String countryCode;
  final String otpReferenceId;

  const OtpScreen({
    super.key,
    required this.mobile,
    required this.countryCode,
    required this.otpReferenceId,
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
    Future.microtask(() {
      if (mounted) ref.read(authControllerProvider.notifier).clearError();
    });
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

  Future<void> _resendOtp() async {
    // Clear existing OTP and errors
    _otpController.clear();
    ref.read(authControllerProvider.notifier).clearError();

    final success = await ref.read(authControllerProvider.notifier).sendOtp(
          widget.mobile,
          widget.countryCode,
          type: 'RESEND',
        );

    if (success && mounted) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.tr('otpResendSuccess')),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    final authState = ref.watch(authControllerProvider);
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 22.sp),
                          onPressed: () => Navigator.pop(context),
                        ),

                        SizedBox(height: 12.h),

                        // Center-Aligned Luxury Branding
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 100),
                          child: Center(
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/header.png',
                                  height: 36.h,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  ref.tr('appName'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4.0,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 48.h),

                        FadeInAnimation(
                          delay: const Duration(milliseconds: 200),
                          child: Center(
                            child: Text(
                              ref.tr('otpTitle'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 42.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                height: 1.05,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        FadeInAnimation(
                          delay: const Duration(milliseconds: 300),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  ref.tr('otpSubtitle'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15.sp,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  widget.mobile,
                                  style: GoogleFonts.outfit(
                                    fontSize: 17.sp,
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
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: defaultPinTheme.copyWith(
                              decoration: defaultPinTheme.decoration!.copyWith(
                                color: isDark
                                    ? AppTheme.arcticBlue.withOpacity(0.08)
                                    : Colors.white,
                                border: Border.all(
                                    color: AppTheme.arcticBlue, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.arcticBlue.withOpacity(0.12),
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
                                      ref.tr('resendLabel', args: {
                                        'seconds': _timerSeconds.toString()
                                      }),
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _resendOtp,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.arcticBlue,
                                      ),
                                      child: Text(
                                        ref.tr('resendButton'),
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
                            text: ref.tr('confirmAndFinalize'),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOtp(String otp) async {
    final authData = ref.read(authControllerProvider).data;
    // Use the latest reference ID from state if available (e.g., after a resend)
    final latestRefId = authData?['otp_reference_id'] ?? widget.otpReferenceId;

    final success = await ref.read(authControllerProvider.notifier).verifyOtp(
          widget.mobile,
          otp,
          latestRefId,
        );

    if (success && mounted) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
              {};
      final String? actionType = args['actionType'];

      if (actionType == 'add_upi') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('UPI ID added successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
        return;
      }

      final authState = ref.read(authControllerProvider);
      final isNewUser = authState.data?['is_new_user'] == true;
      final mpinEnabled = authState.data?['mpin_enabled'] == true;

      if (isNewUser) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.registration,
          arguments: {
            'mobile': widget.mobile,
            'tempToken': authState.data?['temp_token'] ?? '',
          },
        );
      } else {
        if (mpinEnabled) {
          Navigator.pushReplacementNamed(
            context,
            AppRouter.mpin,
            arguments: {'mobile': widget.mobile},
          );
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.home);
        }
      }
    }
  }
}
