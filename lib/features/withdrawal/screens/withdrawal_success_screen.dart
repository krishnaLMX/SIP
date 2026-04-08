import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startgold/shared/widgets/animations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routes/app_router.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/home_dashboard_provider.dart';
import '../../profile/profile_controller.dart';
import '../../../shared/widgets/custom_button.dart';

class WithdrawalSuccessScreen extends ConsumerWidget {
  final Map<String, dynamic> data;

  const WithdrawalSuccessScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Success Animation / Icon
                  ScaleAnimation(
                    child: Container(
                      padding: EdgeInsets.all(32.w),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.greenAccent,
                        size: 80.sp,
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  FadeInAnimation(
                    child: Text(
                      'Redemption Initiated!',
                      style: GoogleFonts.lora(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  FadeInAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Your request for ₹${data['amount']} is being processed. The amount will be credited to your account within 24-48 hours.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 15.sp,
                        color: isDark ? Colors.white54 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Transaction Summary Card
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Transaction ID',
                              data['txnId'] ?? 'TXN_9823412', isDark),
                          Divider(
                              height: 32.h,
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05)),
                          _buildDetailRow('Target Account',
                              data['account'] ?? 'UPI Handle', isDark),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFooter(context, ref),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: CustomButton(
        text: 'Done',
        onPressed: () {
          final container = ProviderScope.containerOf(context);

          // Refresh all Home APIs before navigating
          container.read(portfolioProvider.notifier).fetchPortfolio();
          container.invalidate(homeDashboardProvider);
          container.invalidate(profileProvider);

          // Navigate to home (fresh stack since success screen cleared it)
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.home,
            (route) => false,
          );
        },
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1B882C), Color(0xFF003716)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B882C).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        textColor: Colors.white,
      ),
    ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 14.sp,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lora(
            fontSize: 14.sp,
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
