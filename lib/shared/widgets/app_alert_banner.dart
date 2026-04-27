import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/app_control_model.dart';

/// Premium global alert banner for maintenance, warnings, or info messages.
///
/// Features:
///   • Swipe (left/right) to dismiss
///   • Close (×) button always visible
///   • Glassmorphism-style design with gradient accent
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
    final scheme = _AlertScheme.from(alert.type);

    return Dismissible(
      key: ValueKey('alert_${alert.type}_${alert.title}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismiss(),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.bgStart,
              scheme.bgEnd,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: scheme.accent.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.accent.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Stack(
            children: [
              // ── Decorative gradient bar on left ──
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.accent, scheme.accentLight],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // ── Content ──
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 10.h),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: scheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        scheme.icon,
                        color: scheme.accent,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (alert.title.isNotEmpty)
                            Text(
                              alert.title,
                              style: GoogleFonts.lora(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: scheme.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (alert.title.isNotEmpty) SizedBox(height: 2.h),
                          Text(
                            alert.message,
                            style: GoogleFonts.lora(
                              fontSize: 11.sp,
                              color: scheme.textSecondary,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Close button — always visible for all types
                    GestureDetector(
                      onTap: onDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: scheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14.sp,
                            color: scheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual scheme for each alert type — keeps the build method clean.
class _AlertScheme {
  final Color accent;
  final Color accentLight;
  final Color bgStart;
  final Color bgEnd;
  final Color textPrimary;
  final Color textSecondary;
  final IconData icon;

  const _AlertScheme({
    required this.accent,
    required this.accentLight,
    required this.bgStart,
    required this.bgEnd,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
  });

  factory _AlertScheme.from(String type) {
    return switch (type) {
      'warning' => const _AlertScheme(
          accent: Color(0xFFD97706),
          accentLight: Color(0xFFF59E0B),
          bgStart: Color(0xFFFFFBEB),
          bgEnd: Color(0xFFFEF3C7),
          textPrimary: Color(0xFF92400E),
          textSecondary: Color(0xFFB45309),
          icon: Icons.warning_amber_rounded,
        ),
      'maintenance' => const _AlertScheme(
          accent: Color(0xFF7C3AED),
          accentLight: Color(0xFFA78BFA),
          bgStart: Color(0xFFF5F3FF),
          bgEnd: Color(0xFFEDE9FE),
          textPrimary: Color(0xFF5B21B6),
          textSecondary: Color(0xFF6D28D9),
          icon: Icons.build_circle_rounded,
        ),
      _ => const _AlertScheme(
          // info
          accent: Color(0xFF0284C7),
          accentLight: Color(0xFF38BDF8),
          bgStart: Color(0xFFF0F9FF),
          bgEnd: Color(0xFFE0F2FE),
          textPrimary: Color(0xFF075985),
          textSecondary: Color(0xFF0369A1),
          icon: Icons.info_outline_rounded,
        ),
    };
  }
}
