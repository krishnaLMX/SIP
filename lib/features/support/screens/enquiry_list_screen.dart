import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip/features/support/enquiry_service.dart';
import 'package:sip/shared/theme/app_theme.dart';
import 'package:sip/shared/widgets/animations.dart';

class EnquiryListScreen extends ConsumerWidget {
  const EnquiryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enquiriesAsync = ref.watch(enquiriesProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('My Enquiries', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/enquiry-form'),
            icon: Icon(Icons.add_comment_outlined, color: AppTheme.arcticBlue, size: 24.sp),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: enquiriesAsync.when(
        data: (enquiries) {
          if (enquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent_outlined, size: 64.sp, color: isDark ? Colors.white12 : Colors.black12),
                  SizedBox(height: 16.h),
                  Text(
                    'No enquiries found.',
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/enquiry-form'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.arcticBlue),
                    child: const Text('Start New Enquiry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(enquiriesProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(24.w),
              itemCount: enquiries.length,
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final enquiry = enquiries[index];
                return FadeInAnimation(
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildEnquiryCard(enquiry, isDark),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.arcticBlue)),
        error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
      ),
    );
  }

  Widget _buildEnquiryCard(Enquiry enquiry, bool isDark) {
    Color statusColor;
    switch (enquiry.status.toUpperCase()) {
      case 'OPEN':
        statusColor = AppTheme.electricCyan;
        break;
      case 'RESOLVED':
        statusColor = Colors.greenAccent;
        break;
      case 'REJECTED':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  enquiry.status,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                enquiry.createdAt,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            enquiry.subject,
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Enquiry ID: #${enquiry.enquiryId}',
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              color: isDark ? Colors.white24 : Colors.black26,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.update_rounded, size: 14.sp, color: isDark ? Colors.white38 : Colors.black38),
              SizedBox(width: 4.w),
              Text(
                'Last updated at: ${enquiry.lastUpdate}',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
