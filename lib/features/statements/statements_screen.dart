import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';

class StatementsScreen extends StatelessWidget {
  const StatementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, isDark),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            FadeInAnimation(
              delay: const Duration(milliseconds: 100),
              child: _buildFeaturedDownload(isDark),
            ),
            SizedBox(height: 32.h),
            _buildSectionHeader('Reports & Logs', isDark),
            SizedBox(height: 16.h),
            _buildStatementItem(
                Icons.receipt_long_outlined,
                'Transaction History',
                'All your gold purchases & sales',
                isDark),
            _buildStatementItem(Icons.pie_chart_outline, 'Portfolio Insights',
                'Monthly performance breakdown', isDark),
            _buildStatementItem(Icons.account_balance_wallet_outlined,
                'Capital Gains', 'Tax-ready profit/loss reports', isDark),
            _buildStatementItem(Icons.history_edu_outlined, 'E-Statements',
                'Official monthly holding statements', isDark),
            SizedBox(height: 32.h),
            _buildSectionHeader('Fiscal Year 2023-24', isDark),
            SizedBox(height: 16.h),
            _buildDownloadCard('Annual Tax Report', 'FY 2023-2024', isDark),
            _buildDownloadCard('Dividend Summary', 'FY 2023-2024', isDark),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black, size: 20.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Statements',
        style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildFeaturedDownload(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.arcticBlue, AppTheme.auroraPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
              color: AppTheme.arcticBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Text('LATEST',
                style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1)),
          ),
          SizedBox(height: 16.h),
          Text('Capital Gains Statement',
              style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 4.h),
          Text('Get your ready-to-file tax report for FY 23-24',
              style: GoogleFonts.outfit(
                  fontSize: 13.sp, color: Colors.white.withOpacity(0.8))),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.arcticBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            icon: const Icon(Icons.file_download_outlined),
            label: Text('Download PDF',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(title,
        style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87));
  }

  Widget _buildStatementItem(
      IconData icon, String title, String subtitle, bool isDark) {
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
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
                color: AppTheme.arcticBlue.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.arcticBlue, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white38 : Colors.black54)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(String title, String period, bool isDark) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(period,
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: AppTheme.arcticBlue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.file_download_outlined,
                color: AppTheme.arcticBlue, size: 22.sp),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
