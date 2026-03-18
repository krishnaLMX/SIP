import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip/core/services/content_service.dart';
import 'package:sip/shared/theme/app_theme.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqsAsync = ref.watch(faqsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Frequently Asked Questions',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: faqsAsync.when(
        data: (faqs) {
          if (faqs.isEmpty) {
            return const Center(child: Text('No FAQs currently available.'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(24.w),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return _buildFaqItem(faq['question'], faq['answer'], isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
      ),
    );
  }

  Widget _buildFaqItem(String ques, String ans, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        title: Text(ques,
            style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87)),
        iconColor: AppTheme.arcticBlue,
        collapsedIconColor: isDark ? Colors.white38 : Colors.black38,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
        children: [
          Text(ans,
              style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5)),
        ],
      ),
    );
  }
}
