import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip/core/services/content_service.dart';
import 'package:sip/shared/theme/app_theme.dart';

class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactInfoAsync = ref.watch(contactUsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Contact Us',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: contactInfoAsync.when(
        data: (data) => SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              _buildContactCard(
                Icons.email_outlined,
                'Email Us',
                data['email'] ?? 'support@startgold.com',
                isDark,
              ),
              SizedBox(height: 16.h),
              _buildContactCard(
                Icons.phone_outlined,
                'Call Us',
                data['phone'] ?? '+91 9876543210',
                isDark,
              ),
              SizedBox(height: 16.h),
              _buildContactCard(
                Icons.location_on_outlined,
                'Visit Us',
                data['address'] ?? '123 Gold Street, Bullion City',
                isDark,
              ),
              SizedBox(height: 16.h),
              _buildContactCard(
                Icons.access_time,
                'Working Hours',
                data['working_hours'] ?? '10 AM - 7 PM',
                isDark,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
      ),
    );
  }

  Widget _buildContactCard(
      IconData icon, String title, String value, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
                color: AppTheme.arcticBlue.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.arcticBlue, size: 24.sp),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
