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
import '../../../shared/widgets/app_toast.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/masking_utils.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String mobile;
  final String countryCode;
  final String idCountry;
  final String otpReferenceId;

  const OtpScreen({
    super.key,
    required this.mobile,
    required this.countryCode,
    required this.idCountry,
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
    _otpController.clear();
    ref.read(authControllerProvider.notifier).clearError();

    final success = await ref.read(authControllerProvider.notifier).sendOtp(
          widget.mobile,
          widget.countryCode,
          widget.idCountry,
          type: 'RESEND',
        );

    if (success && mounted) {
      _startTimer();
      AppToast.show(context, ref.tr('otpResendSuccess'),
          type: ToastType.success);
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
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error && mounted) {
        AppToast.show(context, next.error!, type: ToastType.error);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF333333);
    final accentGreen = const Color(0xFF064E3B);
    final accentOrange = const Color(0xFFE67E22);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF666666);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable Content ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            size: 24.sp, color: primaryTextColor),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),

                      SizedBox(height: 32.h),

                      // Primary Headers
                      FadeInAnimation(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify now.',
                              style: GoogleFonts.lora(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              'Secure your Gold.',
                              style: GoogleFonts.lora(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              'We sent an OTP to',
                              style: GoogleFonts.lora(
                                fontSize: 16.sp,
                                color: secondaryTextColor,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Text(
                                  '${widget.countryCode} ${MaskingUtils.maskMobile(widget.mobile)} ',
                                  style: GoogleFonts.lora(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Edit',
                                    style: GoogleFonts.lora(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: accentOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // OTP Input Field
                      FadeInAnimation(
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                                color: primaryTextColor.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Pinput(
                            length: 6,
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            preFilledWidget: Text(
                              '•',
                              style: GoogleFonts.lora(
                                fontSize: 22.sp,
                                color: primaryTextColor.withOpacity(0.25),
                              ),
                            ),
                            defaultPinTheme: PinTheme(
                              width: 45.w,
                              height: 60.h,
                              textStyle: GoogleFonts.lora(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                              decoration: const BoxDecoration(),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 45.w,
                              height: 60.h,
                              textStyle: GoogleFonts.lora(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: accentGreen,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: accentGreen, width: 2)),
                              ),
                            ),
                            onCompleted: _verifyOtp,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Resend Timer
                      FadeInAnimation(
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          children: [
                            Text(
                              "Didn’t receive the OTP? ",
                              style: GoogleFonts.lora(
                                  fontSize: 14.sp, color: secondaryTextColor),
                            ),
                            _timerSeconds > 0
                                ? Text(
                                    'Request a new one in ${_timerSeconds}s',
                                    style: GoogleFonts.lora(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: accentGreen,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _resendOtp,
                                    child: Text(
                                      'Resend Code',
                                      style: GoogleFonts.lora(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: accentGreen,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),

            // ── Pinned Footer ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: FadeInAnimation(
                delay: const Duration(milliseconds: 400),
                child: CustomButton(
                  text: 'Verify OTP',
                  isLoading: authState.isLoading,
                  onPressed: _otpController.text.length == 6
                      ? () => _verifyOtp(_otpController.text)
                      : null,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: _otpController.text.length == 6
                        ? const [Color(0xFF1B882C), Color(0xFF003716)]
                        : [
                            const Color(0xFF1B882C).withOpacity(0.5),
                            const Color(0xFF003716).withOpacity(0.5),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8F4C05).withOpacity(0.06),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                  textColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp(String otp) async {
    final authData = ref.read(authControllerProvider).data;
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

      // ── UPI verification flow ──
      if (actionType == 'add_upi') {
        Navigator.pop(context, true);
        return;
      }

      // ── Forgot PIN flow: OTP verified → go to MPIN reset screen ──
      if (actionType == 'forgot_pin') {
        final authState = ref.read(authControllerProvider);
        final tempToken = authState.data?['temp_token'] ??
            authState.data?['access_token'] ?? '';
        Navigator.pushReplacementNamed(
          context,
          AppRouter.mpin,
          arguments: {
            'type': 'reset_pin',
            'temp_token': tempToken,
            'mobile': widget.mobile,
          },
        );
        return;
      }

      final authState = ref.read(authControllerProvider);
      final isNewUser = authState.data?['is_new_user'] == true;
      final mpinEnabled = authState.data?['mpin_enabled'] == true;

      if (isNewUser) {
        // New user → registration form
        Navigator.pushReplacementNamed(
          context,
          AppRouter.registration,
          arguments: {
            'mobile': widget.mobile,
            'tempToken': authState.data?['temp_token'] ?? '',
          },
        );
      } else if (mpinEnabled) {
        // Existing user with PIN → verify PIN
        Navigator.pushReplacementNamed(
          context,
          AppRouter.mpin,
          arguments: {'mobile': widget.mobile},
        );
      } else {
        // SECURITY: Existing user without PIN → force PIN setup
        // This covers the edge case where register succeeded but PIN
        // creation failed or was interrupted.
        Navigator.pushReplacementNamed(
          context,
          AppRouter.mpin,
          arguments: {'type': 'setup', 'mobile': widget.mobile},
        );
      }
    }
  }
}
