import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/gradient_header.dart';

class ContentScreen extends ConsumerWidget {
  final String title;
  final FutureProvider<Map<String, dynamic>> provider;

  const ContentScreen({
    super.key,
    required this.title,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentAsync = ref.watch(provider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(title: title),
          Expanded(
            child: contentAsync.when(
              data: (data) {
                final content = data['content'] ?? 'No content available.';
                return SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Text(
                    content,
                    style: GoogleFonts.lora(
                      fontSize: 13.sp,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Failed to load content. Please try again later.')),
            ),
          ),
        ],
      ),
    );
  }
}
