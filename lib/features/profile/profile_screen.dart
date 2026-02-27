import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  _buildKycStatus(isDark),
                  SizedBox(height: 32.h),
                  _buildSectionTitle('Personal Information', isDark),
                  SizedBox(height: 16.h),
                  _buildProfileTile(Icons.person_outline, 'Full Name',
                      'Lord Alexander', isDark),
                  _buildProfileTile(Icons.alternate_email, 'Email Address',
                      'alexander@luxury.com', isDark),
                  _buildProfileTile(Icons.phone_iphone, 'Mobile Number',
                      '+91 98765 43210', isDark),
                  SizedBox(height: 32.h),
                  _buildSectionTitle('Security & Privacy', isDark),
                  SizedBox(height: 16.h),
                  _buildProfileTile(Icons.lock_outline, 'Change MPIN',
                      'Last updated 2 days ago', isDark,
                      isAction: true),
                  _buildProfileTile(
                      Icons.fingerprint, 'Biometric Login', 'Enabled', isDark,
                      isAction: true),
                  _buildProfileTile(Icons.description_outlined, 'KYC Documents',
                      'Verified', isDark,
                      isAction: true),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 240.h,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black, size: 20.sp),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.arcticBlue.withOpacity(0.8),
                    AppTheme.auroraPurple.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text('LA',
                          style: GoogleFonts.outfit(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.arcticBlue)),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Lord Alexander',
                    style: GoogleFonts.outfit(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  Text(
                    'Investor ID: #A98765',
                    style: GoogleFonts.outfit(
                        fontSize: 14.sp, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycStatus(bool isDark) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.electricCyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppTheme.electricCyan.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: AppTheme.electricCyan, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KYC Verified',
                      style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.electricCyan)),
                  Text('Your account is fully compliant and secure.',
                      style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white60 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppTheme.arcticBlue),
    );
  }

  Widget _buildProfileTile(
      IconData icon, String title, String value, bool isDark,
      {bool isAction = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isDark ? Colors.white38 : Colors.black38, size: 22.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white38 : Colors.black38)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          if (isAction)
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.black26),
        ],
      ),
    );
  }
}
