import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/services/mpin_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../../routes/app_router.dart';
import '../../shared/theme/app_theme.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/app_toast.dart';

class MpinScreen extends ConsumerStatefulWidget {
  const MpinScreen({super.key});

  @override
  ConsumerState<MpinScreen> createState() => _MpinScreenState();
}

class _MpinScreenState extends ConsumerState<MpinScreen>
    with WidgetsBindingObserver {
  bool _isMpinEnabledCount = false;
  bool _isBiometricEnabled = false;
  bool _isLoadingStatus = true;
  final LocalAuthentication _localAuth = LocalAuthentication();
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
    Future.microtask(() {
      ref.read(mpinProvider.notifier).clear();
    });
    // Defer to post-frame so ModalRoute.of(context) is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMpinStatus();
    });
    _shuffleKeypad();
    _secureScreen();
  }

  Future<void> _loadMpinStatus() async {
    final enabled = await SecureStorageService.isMpinEnabled();
    final bioEnabled = await SecureStorageService.isBiometricEnabled();

    // Also verify device capability
    bool canUseBiometrics = false;
    try {
      canUseBiometrics = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('Biometric check failed: $e');
    }

    debugPrint('── MPIN Screen Status ──');
    debugPrint('  mpinEnabled: $enabled');
    debugPrint('  bioEnabled (storage): $bioEnabled');
    debugPrint('  canUseBiometrics (device): $canUseBiometrics');
    debugPrint('  final _isBiometricEnabled: ${bioEnabled && canUseBiometrics}');

    if (mounted) {
      setState(() {
        _isMpinEnabledCount = enabled;
        _isBiometricEnabled = bioEnabled && canUseBiometrics;
        _isLoadingStatus = false;
      });

      // Auto-trigger biometric on app open / biometric enable flow
      // Excluded: withdrawal_pin (must use MPIN), verify_only (proving identity)
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
              {};
      final String? type = args['type'];

      debugPrint('  route type: $type');
      debugPrint('  will auto-trigger: ${_isBiometricEnabled && _isMpinEnabledCount && type != 'withdrawal_pin' && type != 'verify_only'}');
      debugPrint('── End ──');

      if (_isBiometricEnabled &&
          _isMpinEnabledCount &&
          type != 'withdrawal_pin' &&
          type != 'verify_only') {
        _authenticateBiometric();
      }
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate && mounted) {
        final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>? ??
            {};
        final String? type = args['type'];

        if (type == 'authorize_withdrawal') {
          _showSuccessDialog();
        } else if (type == 'verify_only') {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.main);
        }
      }
    } on Exception catch (e) {
      debugPrint('Biometric Auth Error: $e');
      // Fallback: user can use MPIN keypad naturally.
    }
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
    // Use Random.secure() for banking-grade security
    final random = Random.secure();
    for (var i = digits.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = digits[i];
      digits[i] = digits[j];
      digits[j] = temp;
    }
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
    if (_isLoadingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mpinState = ref.watch(mpinProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<MpinState>(mpinProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error && mounted) {
        AppToast.show(context, next.error!, type: ToastType.error);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
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
                            child: SvgPicture.asset(
                              'assets/images/startGold.svg',
                              height: 80.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // 3. Luxury Branding Header
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 100),
                          child: Builder(builder: (context) {
                            final args = ModalRoute.of(context)
                                    ?.settings
                                    .arguments as Map<String, dynamic>? ??
                                {};
                            final String? routeType = args['type'];
                            final isWithdrawal =
                                routeType == 'withdrawal_pin' ||
                                    routeType == 'authorize_withdrawal';

                            return Column(
                              children: [
                                Text(
                                  isWithdrawal
                                      ? 'AUTHORIZE WITHDRAWAL'
                                      : routeType == 'setup'
                                          ? 'SET YOUR PIN'
                                          : routeType == 'reset_pin'
                                              ? 'RESET YOUR PIN'
                                              : AppConstants.mpinTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lora(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  isWithdrawal
                                      ? 'Enter your 4-digit PIN to securely authorize this transaction.'
                                      : routeType == 'setup'
                                          ? 'Create a 4-digit PIN for quick & secure access.'
                                          : routeType == 'reset_pin'
                                              ? 'Enter your new 4-digit security PIN.'
                                              : AppConstants.mpinSubtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lora(
                                    fontSize: 14.sp,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black45,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            );
                          }),
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
                                tween:
                                    Tween(begin: 1.0, end: filled ? 1.2 : 1.0),
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
                                                ? Colors.white.withOpacity(0.1)
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

                        SizedBox(height: 32.h),

                        // 5. Glassmorphic Keypad Card
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 400),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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

                // 8. CTA Section
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: FadeInAnimation(
                    delay: const Duration(milliseconds: 500),
                    child: Builder(
                      builder: (context) {
                        // Read the route type to know which context we're in
                        final args = ModalRoute.of(context)?.settings.arguments
                                as Map<String, dynamic>? ??
                            {};
                        final String? routeType = args['type'];

                        // "Forgot PIN?" is only relevant during app-unlock.
                        // Hide it when opened from Profile (verify_only) or
                        // from Withdrawal (authorize_withdrawal).
                        // "Forgot PIN?" only in unlock mode (no route type)
                        final bool showForgotPin = routeType == null;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomButton(
                              text: routeType == 'withdrawal_pin' ||
                                      routeType == 'authorize_withdrawal'
                                  ? 'CONFIRM WITHDRAWAL'
                                  : routeType == 'verify_only'
                                      ? 'VERIFY IDENTITY'
                                      : routeType == 'setup'
                                          ? 'ACTIVATE SECURE PIN'
                                          : routeType == 'reset_pin'
                                              ? 'RESET PIN'
                                              : 'UNLOCK APP',
                              isLoading: mpinState.isLoading,
                              onPressed:
                                  (mpinState.isComplete && !mpinState.isLocked)
                                      ? _handleAction
                                      : null,
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: routeType == 'withdrawal_pin' ||
                                        routeType == 'authorize_withdrawal'
                                    ? (mpinState.isComplete
                                        ? const [
                                            Color(0xFF1B882C),
                                            Color(0xFF003716)
                                          ]
                                        : [
                                            Color(0xFF1B882C).withOpacity(0.4),
                                            Color(0xFF003716).withOpacity(0.4)
                                          ])
                                    : (mpinState.isComplete
                                        ? const [
                                            Color(0xFF1B882C),
                                            Color(0xFF003716)
                                          ]
                                        : [
                                            Color(0xFF1B882C).withOpacity(0.35),
                                            Color(0xFF003716).withOpacity(0.35)
                                          ]),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF8F4C05).withOpacity(0.06),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                              textColor: Colors.white,
                            ),
                            if (showForgotPin) ...[
                              SizedBox(height: 28.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_user_outlined,
                                      size: 16.sp,
                                      color: AppTheme.electricCyan),
                                  SizedBox(width: 10.w),
                                  GestureDetector(
                                    onTap: _handleForgotPin,
                                    child: Text(
                                      'Forgot PIN?',
                                      style: GoogleFonts.lora(
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
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildBiometricHint() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    final String? type = args['type'];

    // Hide biometric icon for withdrawal (must use MPIN) and verify_only
    if (!_isBiometricEnabled ||
        !_isMpinEnabledCount ||
        type == 'withdrawal_pin' ||
        type == 'verify_only') {
      return SizedBox(height: 68.w, width: 68.w);
    }

    return GestureDetector(
      onTap: _authenticateBiometric,
      child: SizedBox(
        height: 68.w,
        width: 68.w,
        child: Center(
            child: Icon(Icons.fingerprint,
                color: AppTheme.arcticBlue.withOpacity(0.8), size: 32.sp)),
      ),
    );
  }

  Future<void> _handleAction() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    final String? type = args['type'];

    if (type == 'setup') {
      // ── SETUP MODE → POST /mpin/create ──
      // User registered but PIN was never created (interrupted flow)
      final success = await ref.read(mpinProvider.notifier).setMpin();
      if (success && mounted) {
        await SecureStorageService.setMpinEnabled(true);
        Navigator.pushNamedAndRemoveUntil(
            context, AppRouter.main, (route) => false);
      } else {
        _shuffleKeypad();
      }
    } else if (type == 'reset_pin') {
      // ── RESET MODE → POST /mpin/reset ──
      // User verified identity via OTP, now setting a new PIN
      final tempToken = args['temp_token'] ?? '';
      final mobile = args['mobile'] as String?;
      final success =
          await ref.read(mpinProvider.notifier).resetMpin(tempToken, mobile: mobile);
      if (success && mounted) {
        await SecureStorageService.setMpinEnabled(true);
        // Navigate to MPIN verify — user must validate new PIN
        // before reaching Home (where dashboard/summary APIs fire)
        Navigator.pushReplacementNamed(
          context,
          AppRouter.mpin,
          arguments: {'mobile': mobile},
        );
      } else {
        _shuffleKeypad();
      }
    } else {
      // ── VERIFY MODE → POST /mpin/validate ──
      // App unlock, withdrawal authorization, biometric verification
      final success = await ref.read(mpinProvider.notifier).verifyMpin();
      if (success && mounted) {
        await SecureStorageService.setMpinEnabled(true);
        if (type == 'authorize_withdrawal') {
          _showSuccessDialog();
        } else if (type == 'withdrawal_pin') {
          final pin = ref.read(mpinProvider).mpin;
          Navigator.pop(context, pin);
        } else if (type == 'verify_only') {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.main);
        }
      } else {
        _shuffleKeypad();
      }
    }
  }

  /// Forgot PIN flow: Send OTP → verify identity → reset PIN
  Future<void> _handleForgotPin() async {
    final mobile = await SecureStorageService.getMobile();
    if (mobile == null || mobile.isEmpty) {
      if (mounted) {
        AppToast.show(
            context, 'Unable to verify identity. Please login again.',
            type: ToastType.error);
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final authService = AuthService();
      final result = await authService.sendOtp(
        mobile: mobile,
        countryCode: '+91',
        idCountry: '101',
        type: 'FORGOT_PIN',
      );

      if (mounted) Navigator.pop(context); // dismiss loading

      if (result['success'] == true && mounted) {
        final otpRefId = result['data']?['otp_reference_id'] ?? '';
        Navigator.pushReplacementNamed(
          context,
          AppRouter.otp,
          arguments: {
            'mobile': mobile,
            'countryCode': '+91',
            'idCountry': '101',
            'otpReferenceId': otpRefId,
            'actionType': 'forgot_pin',
          },
        );
      } else if (mounted) {
        AppToast.show(
            context, result['message'] ?? 'Failed to send OTP.',
            type: ToastType.error);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // dismiss loading
      if (mounted) {
        AppToast.show(context, 'Failed to send OTP. Please try again.',
            type: ToastType.error);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.greenAccent[400], size: 48.sp),
            ),
            SizedBox(height: 24.h),
            Text('Withdrawal Successful',
                style: GoogleFonts.lora(
                    fontSize: 20.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 12.h),
            Text(
                'Your funds will be credited to your account within 24-48 hours.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.lora(fontSize: 14.sp, color: Colors.black54)),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRouter.main, (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.arcticBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('BACK TO HOME',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
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
      onTap: () {
        ref.read(mpinProvider.notifier).addKey(number);
      },
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
                style: GoogleFonts.lora(
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
