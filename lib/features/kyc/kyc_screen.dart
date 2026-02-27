import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/custom_button.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  @override
  Widget build(BuildContext context) {
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

                  // Verification List
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildKycStep(
                          'PAN Card Verification',
                          'Essential for tax compliance and regulatory protocols.',
                          Icons.credit_card_rounded,
                          isDark,
                          true, // Completed
                        ),
                        SizedBox(height: 24.h),
                        _buildKycStep(
                          'Identity Proof',
                          'Submit Aadhaar or Passport for identity confirmation.',
                          Icons.person_pin_outlined,
                          isDark,
                          false, // Pending
                        ),
                        SizedBox(height: 24.h),
                        _buildKycStep(
                          'Wealth Declaration',
                          'Self-declaration of income for high-limit accounts.',
                          Icons.monetization_on_outlined,
                          isDark,
                          false, // Pending
                        ),
                      ],
                    ),
                  ),

                  CustomButton(
                    text: 'Commence Verification',
                    onPressed: () {},
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

  Widget _buildKycStep(
      String title, String desc, IconData icon, bool isDark, bool isCompleted) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isCompleted
                ? AppTheme.arcticBlue.withOpacity(0.3)
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
                    ? AppTheme.arcticBlue.withOpacity(0.1)
                    : (isDark ? Colors.white10 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
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
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
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
                    desc,
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
    );
  }
}
