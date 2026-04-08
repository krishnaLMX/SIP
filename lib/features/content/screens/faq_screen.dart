import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startgold/core/services/content_service.dart';
import 'package:startgold/shared/theme/app_theme.dart';
import 'package:startgold/shared/widgets/gradient_header.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqsAsync = ref.watch(faqsProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // ── Gradient Header (same as Instant Saving page) ──
            GradientHeader(title: 'FAQ'),

            // ── Body ──
            Expanded(
              child: faqsAsync.when(
                data: (faqs) {
                  if (faqs.isEmpty) {
                    return Center(
                      child: Text(
                        'No FAQs currently available.',
                        style: GoogleFonts.lora(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return _buildFaqItem(
                          faq['question'], faq['answer'], isDark);
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Text(
                      'Failed to load FAQs.\nPlease try again later.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String ques, String ans, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        title: Text(ques,
            style: GoogleFonts.lora(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87)),
        iconColor: AppTheme.arcticBlue,
        collapsedIconColor: isDark ? Colors.white38 : Colors.black38,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
        children: [
          Text(ans,
              style: GoogleFonts.lora(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5)),
        ],
      ),
    );
  }
}
