import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip/shared/theme/app_theme.dart';
import 'package:sip/shared/widgets/animations.dart';
import 'package:sip/shared/widgets/custom_button.dart';
import 'package:sip/features/kyc/providers/kyc_provider.dart';
import 'package:sip/features/kyc/models/kyc_step.dart';

class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kycState = ref.watch(kycStepsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Layer
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
                      'Account\nVerification',
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
                      'Complete verification to unlock elite investment categories and higher transfer limits.',
                      style: GoogleFonts.outfit(
                        fontSize: 17.sp,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  SizedBox(height: 48.h),

                  // Verification List (Dynamic)
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: kycState.steps.length,
                      itemBuilder: (context, index) {
                        final step = kycState.steps[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: _buildKycStep(context, step, isDark),
                        );
                      },
                    ),
                  ),

                  CustomButton(
                    text: 'Commence Verification',
                    onPressed: kycState.steps.isEmpty
                        ? null
                        : () {
                            // Navigate to the first pending step
                            final firstPending = kycState.steps.firstWhere(
                              (s) => s.status == KycStatus.pending,
                              orElse: () => kycState.steps.first,
                            );
                            Navigator.pushNamed(context, firstPending.route);
                          },
                    backgroundColor: AppTheme.arcticBlue,
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

  Widget _buildKycStep(BuildContext context, KycStep step, bool isDark) {
    final isCompleted = step.status == KycStatus.verified;

    return FadeInAnimation(
      delay: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, step.route),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.arcticBlue.withValues(alpha: 0.3)
                  : (isDark ? Colors.white12 : Colors.black12),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.arcticBlue.withValues(alpha: 0.1)
                      : (isDark ? Colors.white10 : Colors.black12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.icon,
                  color: isCompleted
                      ? AppTheme.arcticBlue
                      : (isDark ? Colors.white24 : Colors.black26),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Icon(Icons.check_circle_rounded,
                              color: AppTheme.arcticBlue, size: 20.sp),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      step.description,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white38 : Colors.black38,
                        height: 1.4,
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
}
