import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/auth_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/shared_service.dart';
import '../../../core/localization/language_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  String _countryCode = '+91';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
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
          });
        }
      });
    });

    final authState = ref.watch(authControllerProvider);
    final countryCodesAsync = ref.watch(countryCodesProvider);
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
                        SizedBox(height: 32.h),

                        // Center-Aligned Luxury Branding
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 100),
                          child: Center(
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/header.png',
                                  height: 48.h,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  ref.tr('appName'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6.0,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                // Customized Dropdown-Style Button
                                GestureDetector(
                                  onTap: () =>
                                      _showLanguageBottomSheet(context),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black12,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.language_rounded,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          _getLanguageName(ref
                                              .watch(languageProvider)
                                              .currentLocale),
                                          style: GoogleFonts.outfit(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          size: 18.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 42.h),

                        // Center-Aligned Bold Title
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 200),
                          child: Center(
                            child: Text(
                              ref.tr('loginTitle'),
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
                            child: Text(
                              ref.tr('loginSubtitle'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 17.sp,
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontWeight: FontWeight.w400,
                              ),
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
                                    : (isDark
                                        ? Colors.white12
                                        : Colors.black12),
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
                                countryCodesAsync.when(
                                  data: (codes) {
                                    // Ensure unique prefixes and check if current selection is valid
                                    final List<String> prefixes = codes
                                        .map((e) => e.prefix)
                                        .toSet()
                                        .toList();

                                    if (prefixes.isEmpty)
                                      return const SizedBox();

                                    // Validate selection
                                    final String? effectiveValue =
                                        prefixes.contains(_countryCode)
                                            ? _countryCode
                                            : prefixes.first;

                                    return DropdownButton<String>(
                                      value: effectiveValue,
                                      underline: const SizedBox(),
                                      icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 20.sp,
                                          color: Colors.grey),
                                      items: prefixes.map((String prefix) {
                                        // Get the first matching country for this prefix to show the flag
                                        final country = codes.firstWhere(
                                            (c) => c.prefix == prefix);
                                        return DropdownMenuItem<String>(
                                          value: prefix,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(country.flag,
                                                  style: TextStyle(
                                                      fontSize: 18.sp)),
                                              SizedBox(width: 8.w),
                                              Text(
                                                prefix,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18.sp,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _countryCode = val);
                                        }
                                      },
                                    );
                                  },
                                  loading: () => SizedBox(
                                    width: 40.w,
                                    height: 20.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.arcticBlue,
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    _countryCode,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18.sp,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Container(
                                  width: 1.5,
                                  height: 28.h,
                                  color:
                                      isDark ? Colors.white12 : Colors.black12,
                                ),
                                SizedBox(width: 18.w),
                                Expanded(
                                  child: TextField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
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
                                        ref
                                            .read(
                                                authControllerProvider.notifier)
                                            .clearError();
                                      }
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      hintText: '00000 00000',
                                      hintStyle: GoogleFonts.outfit(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black12,
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

                        const SizedBox(
                            height: 20.0), // Replaced Spacer with SizedBox

                        // CTA Section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 500),
                          child: Column(
                            children: [
                              CustomButton(
                                text: ref.tr('Get OTP'),
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
                                      size: 16.sp,
                                      color: AppTheme.electricCyan),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Clear any previous errors before starting a new flow
    ref.read(authControllerProvider.notifier).clearError();

    final success = await ref.read(authControllerProvider.notifier).sendOtp(
          _mobileController.text,
          _countryCode,
        );

    if (success && mounted) {
      final authData = ref.read(authControllerProvider).data;
      Navigator.pushNamed(
        context,
        AppRouter.otp,
        arguments: {
          'mobile': _mobileController.text,
          'countryCode': _countryCode,
          'otpReferenceId': authData?['otp_reference_id'] ?? '',
        },
      );
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(builder: (context, ref, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ref.tr('languageSelector'),
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  )),
              SizedBox(height: 8.h),
              Text(
                ref.tr('chooseLanguagePref'),
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 24.h),
              _buildLangOption(context, ref, 'English', 'en', isDark),
              _buildLangOption(context, ref, 'தமிழ் (Tamil)', 'ta', isDark),
              _buildLangOption(context, ref, 'తెలుగు (Telugu)', 'te', isDark),
              SizedBox(height: 16.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLangOption(BuildContext context, WidgetRef ref, String title,
      String code, bool isDark) {
    final currentCode = ref.watch(languageProvider).currentLocale;
    final isSelected = currentCode == code;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? AppTheme.arcticBlue
                : (isDark ? Colors.white70 : Colors.black87),
          )),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppTheme.arcticBlue)
          : null,
      onTap: () {
        ref.read(languageProvider.notifier).setLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}
