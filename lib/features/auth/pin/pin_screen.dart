import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../controller/auth_controller.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/theme/app_theme.dart';

class PinScreen extends ConsumerStatefulWidget {
  final String mobile;
  const PinScreen({super.key, required this.mobile});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 64.w,
      height: 72.h,
      textStyle: GoogleFonts.outfit(
        fontSize: 32.sp,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12, width: 1),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
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
                      'Welcome\nBack',
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
                    child: Text(
                      'Enter your 4-digit security PIN to access your vault.',
                      style: GoogleFonts.outfit(
                        fontSize: 17.sp,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: 80.h),
                  Center(
                    child: FadeInAnimation(
                      delay: const Duration(milliseconds: 300),
                      child: Pinput(
                        length: 4,
                        controller: _pinController,
                        obscureText: true,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            color: isDark
                                ? AppTheme.arcticBlue.withOpacity(0.08)
                                : Colors.white,
                            border: Border.all(color: AppTheme.arcticBlue, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.arcticBlue.withOpacity(0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                        onCompleted: _handleVerifyPin,
                      ),
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
                    delay: const Duration(milliseconds: 400),
                    child: CustomButton(
                      text: 'Unlock Vault',
                      isLoading: authState.isLoading,
                      onPressed: _pinController.text.length == 4
                          ? () => _handleVerifyPin(_pinController.text)
                          : null,
                      backgroundColor: _pinController.text.length == 4
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

  Future<void> _handleVerifyPin(String pin) async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyPin(widget.mobile, pin);

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRouter.home, (route) => false);
    } else {
      _pinController.clear();
    }
  }
}
