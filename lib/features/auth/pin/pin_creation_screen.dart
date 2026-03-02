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

class PinCreationScreen extends ConsumerStatefulWidget {
  final String mobile;
  const PinCreationScreen({super.key, required this.mobile});

  @override
  ConsumerState<PinCreationScreen> createState() => _PinCreationScreenState();
}

class _PinCreationScreenState extends ConsumerState<PinCreationScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isConfirming = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
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
                    onPressed: () {
                      if (_isConfirming) {
                        setState(() {
                          _isConfirming = false;
                          _confirmPinController.clear();
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  SizedBox(height: 32.h),
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      _isConfirming ? 'Verify Your\nPIN' : 'Secure Your\nAccount',
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
                      _isConfirming
                          ? 'Enter the 4-digit PIN again to confirm.'
                          : 'Create a 4-digit PIN for quick & secure access.',
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
                        controller:
                            _isConfirming ? _confirmPinController : _pinController,
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
                        onCompleted: (pin) {
                          if (!_isConfirming) {
                            setState(() => _isConfirming = true);
                          } else {
                            _handleSetPin();
                          }
                        },
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
                      text: _isConfirming ? 'Complete Setup' : 'Next Step',
                      isLoading: authState.isLoading,
                      onPressed: () {
                        if (!_isConfirming && _pinController.text.length == 4) {
                          setState(() => _isConfirming = true);
                        } else if (_isConfirming &&
                            _confirmPinController.text.length == 4) {
                          _handleSetPin();
                        }
                      },
                      backgroundColor: AppTheme.arcticBlue,
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

  Future<void> _handleSetPin() async {
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match!')),
      );
      _confirmPinController.clear();
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .setPin(widget.mobile, _pinController.text);

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRouter.home, (route) => false);
    }
  }
}
