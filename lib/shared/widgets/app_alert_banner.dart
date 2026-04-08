import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/app_control_model.dart';

/// Global alert banner for maintenance, warnings, or info messages.
/// Slides in beneath the offline banner.
class AppAlertBanner extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onDismiss;

  const AppAlertBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (alert.type) {
      'warning' => (const Color(0xFFD97706), Icons.warning_amber_rounded),
      'maintenance' => (const Color(0xFF6366F1), Icons.build_circle_outlined),
      _ => (const Color(0xFF0EA5E9), Icons.info_outline_rounded), // info
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: color.withOpacity(0.12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alert.title.isNotEmpty)
                  Text(
                    alert.title,
                    style: GoogleFonts.lora(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                Text(
                  alert.message,
                  style: GoogleFonts.lora(
                    fontSize: 12.sp,
                    color: color.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (!alert.isMaintenance)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 18.sp, color: color),
            ),
        ],
      ),
    );
  }
}
