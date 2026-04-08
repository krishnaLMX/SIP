import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../controller/auth_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shared_service.dart';
import '../../../shared/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  String _countryCode = '+91';
  String _selectedCountryId = '101';
  final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _termsRecognizer.onTap = () {
      Navigator.pushNamed(context, AppRouter.terms);
    };
    _privacyRecognizer.onTap = () {
      Navigator.pushNamed(context, AppRouter.privacy);
    };
    Future.microtask(() {
      if (mounted) ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<CountryCode>>>(countryCodesProvider,
        (previous, next) {
      next.whenData((codes) {
        if (codes.isNotEmpty && !codes.any((c) => c.prefix == _countryCode)) {
          setState(() {
            _countryCode = codes.first.prefix;
            _selectedCountryId = codes.first.id;
          });
        }
      });
    });

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error && mounted) {
        AppToast.show(context, next.error!, type: ToastType.error);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final countryCodesAsync = ref.watch(countryCodesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isValid =
        Validators.validateMobile(_mobileController.text) == null;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF333333);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF666666);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
        ),
        child: SafeArea(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SvgPicture.asset(
                              'assets/images/startGold.svg',
                              height: 85.h,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        SizedBox(height: 48.h),
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to',
                                style: TextStyle(
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  // "Start" — green gradient
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF49B44B),
                                        Color(0xFF1A6F2D),
                                      ],
                                    ).createShader(bounds),
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      'start',
                                      style: TextStyle(
                                        fontSize: 30.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // "GOLD" — orange gradient
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFFFB941),
                                        Color(0xFFE27903),
                                      ],
                                    ).createShader(bounds),
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      'GOLD',
                                      style: TextStyle(
                                        fontSize: 30.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // " Family" — plain color
                                  Text(
                                    ' Family',
                                    style: TextStyle(
                                      fontSize: 30.sp,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Your Gold Journey Starts the Best Way!',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 80.h),
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'Phone number*',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 300),
                          child: Container(
                            height: 64.h,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: primaryTextColor.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              children: [
                                countryCodesAsync.when(
                                  data: (codes) => _buildCountryPicker(
                                      codes, isDark, primaryTextColor),
                                  loading: () => const SizedBox(
                                      width: 40,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                  error: (_, __) => Text(_countryCode,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: primaryTextColor)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 16.h),
                                  child: Container(
                                      width: 1,
                                      color: primaryTextColor.withOpacity(0.1)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    maxLength: 10,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w500,
                                      color: primaryTextColor,
                                    ),
                                    onChanged: (v) {
                                      if (authState.error != null) {
                                        ref
                                            .read(
                                                authControllerProvider.notifier)
                                            .clearError();
                                      }
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Enter your phone number',
                                      hintStyle: TextStyle(
                                        fontSize: 16.sp,
                                        color:
                                            primaryTextColor.withOpacity(0.3),
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
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Pinned Footer ───────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInAnimation(
                      delay: const Duration(milliseconds: 400),
                      child: CustomButton(
                        text: 'Initiate Secure Login',
                        isLoading: authState.isLoading,
                        onPressed: isValid ? _handleLogin : null,
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: isValid
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
                    SizedBox(height: 20.h),
                    FadeInAnimation(
                      delay: const Duration(milliseconds: 500),
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12.sp,
                              color: secondaryTextColor,
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                  text: 'By proceeding, you accept our '),
                              TextSpan(
                                text: 'Terms and Conditions.',
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: _termsRecognizer,
                              ),
                              const TextSpan(text: '\nand '),
                              TextSpan(
                                text: 'Privacy Policy.',
                                style: const TextStyle(
                                  fontFamily: 'Lora',
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: _privacyRecognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryPicker(
      List<CountryCode> codes, bool isDark, Color textColor) {
    return DropdownButton<String>(
      value: _countryCode,
      underline: const SizedBox(),
      icon: Icon(Icons.keyboard_arrow_down,
          size: 18.sp, color: textColor.withOpacity(0.4)),
      items: codes
          .map((c) => DropdownMenuItem(
                value: c.prefix,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.flag, style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 8.w),
                    Text(c.prefix,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            color: textColor)),
                  ],
                ),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          final selected = codes.firstWhere((c) => c.prefix == val);
          setState(() {
            _countryCode = val;
            _selectedCountryId = selected.id;
          });
        }
      },
    );
  }

  Future<void> _handleLogin() async {
    ref.read(authControllerProvider.notifier).clearError();
    final success = await ref.read(authControllerProvider.notifier).sendOtp(
          _mobileController.text,
          _countryCode,
          _selectedCountryId,
        );
    if (success && mounted) {
      final authData = ref.read(authControllerProvider).data;
      Navigator.pushNamed(
        context,
        AppRouter.otp,
        arguments: {
          'mobile': _mobileController.text,
          'countryCode': _countryCode,
          'idCountry': _selectedCountryId,
          'otpReferenceId': authData?['otp_reference_id'] ?? '',
        },
      );
    }
  }
}
