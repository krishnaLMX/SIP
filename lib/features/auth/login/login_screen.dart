import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  String _countryCode = '+91';

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bool isValid =
        Validators.validateMobile(_mobileController.text) == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            ),
          ),

          // Strategic Depth Orbs
          Positioned(
            top: -100.h,
            right: -100.w,
            child: Container(
              width: 400.w,
              height: 400.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.arcticBlue.withOpacity(0.12),
                    AppTheme.arcticBlue.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 50.h,
            left: -150.w,
            child: Container(
              width: 500.w,
              height: 500.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.auroraPurple.withOpacity(0.08),
                    AppTheme.auroraPurple.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),

                  // Label Accessory
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppTheme.arcticBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100.r),
                        border: Border.all(
                            color: AppTheme.arcticBlue.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Secure Gate',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.arcticBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Bold Premium Title
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Access Your\nFinancial Hub',
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
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Seamless entry into the modern market.',
                      style: GoogleFonts.outfit(
                        fontSize: 17.sp,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  SizedBox(height: 60.h),

                  // Glass Input
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      height: 72.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: authState.error != null
                              ? Colors.redAccent.withOpacity(0.5)
                              : (isDark ? Colors.white12 : Colors.black12),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            value: _countryCode,
                            underline: const SizedBox(),
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                size: 20.sp, color: Colors.grey),
                            items: ['+91', '+1', '+44'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18.sp,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _countryCode = val);
                              }
                            },
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            width: 1.5,
                            height: 28.h,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          SizedBox(width: 18.w),
                          Expanded(
                            child: TextField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: GoogleFonts.outfit(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              onChanged: (_) {
                                if (authState.error != null) {
                                  ref.read(authProvider.notifier).clearError();
                                }
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: '00000 00000',
                                hintStyle: GoogleFonts.outfit(
                                  color:
                                      isDark ? Colors.white10 : Colors.black12,
                                  letterSpacing: 2.5,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (authState.error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 14.h, left: 10.w),
                      child: Text(authState.error!,
                          style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500)),
                    ),

                  const Spacer(),

                  // CTA Section
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Initiate Secure Login',
                          isLoading: authState.isLoading,
                          onPressed: isValid ? _handleLogin : null,
                          backgroundColor: isValid
                              ? AppTheme.arcticBlue
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05)),
                        ),
                        SizedBox(height: 28.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                size: 16.sp, color: AppTheme.electricCyan),
                            SizedBox(width: 10.w),
                            Text(
                              'Authorized Access Only',
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                      ],
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

  Future<void> _handleLogin() async {
    final success = await ref.read(authProvider.notifier).sendOtp(
          _mobileController.text,
          _countryCode,
        );

    if (success && mounted) {
      final authData = ref.read(authProvider).data;
      Navigator.pushNamed(
        context,
        AppRouter.otp,
        arguments: {
          'mobile': _mobileController.text,
          'otpSessionId': authData?['otpSessionId'] ?? '',
        },
      );
    }
  }
}
