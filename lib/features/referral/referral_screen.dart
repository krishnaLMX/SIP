import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Refer & Earn',
            style: GoogleFonts.outfit(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            _buildHeroSection(isDark),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('How it works', isDark),
                  SizedBox(height: 20.h),
                  _buildStep(Icons.share_outlined, 'Share your code',
                      'Invite friends via your unique link.', 1),
                  _buildStep(Icons.person_add_outlined, 'Friend joins',
                      'They sign up and complete gold KYC.', 2),
                  _buildStep(Icons.card_giftcard_outlined, 'Get Rewarded',
                      'Both get ₹250 worth of digital gold.', 3),
                  SizedBox(height: 40.h),
                  _buildReferralCodeCard(isDark),
                  SizedBox(height: 32.h),
                  _buildStatsRow(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      child: Column(
        children: [
          FadeInAnimation(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.arcticBlue.withOpacity(0.1),
                border: Border.all(
                    color: AppTheme.arcticBlue.withOpacity(0.2), width: 2),
              ),
              child: Icon(Icons.group_add_rounded,
                  size: 80.sp, color: AppTheme.arcticBlue),
            ),
          ),
          SizedBox(height: 32.h),
          Text('Spread the Wealth',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black)),
          SizedBox(height: 12.h),
          Text('Earn ₹250 Digital Gold\nfor every friend you invite.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title,
        style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87));
  }

  Widget _buildStep(IconData icon, String title, String desc, int step) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
                color: AppTheme.arcticBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r)),
            child: Center(
                child: Text(step.toString(),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.arcticBlue))),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.arcticBlue)),
                Text(desc,
                    style: GoogleFonts.outfit(
                        fontSize: 13.sp, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12, width: 1.5),
      ),
      child: Column(
        children: [
          Text('YOUR CODE',
              style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.5)),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LX-GOLD-2024',
                  style: GoogleFonts.outfit(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87)),
              IconButton(
                  icon: Icon(Icons.copy_rounded,
                      color: AppTheme.arcticBlue, size: 20.sp),
                  onPressed: () {}),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.arcticBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text('Invite Friends',
                  style: GoogleFonts.outfit(
                      fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _buildStatCard('12', 'Referrals', isDark),
        SizedBox(width: 16.w),
        _buildStatCard('₹3,000', 'Earned', isDark),
      ],
    );
  }

  Widget _buildStatCard(String val, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            Text(val,
                style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.arcticBlue)),
            Text(label,
                style: GoogleFonts.outfit(fontSize: 12.sp, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
