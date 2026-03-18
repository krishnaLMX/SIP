import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: contentAsync.when(
        data: (data) {
          final content = data['content'] ?? 'No content available.';
          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Text(
              content,
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
      ),
    );
  }
}
