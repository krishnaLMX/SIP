import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/connectivity_provider.dart';

/// Animated offline/slow-network banner that slides in from the top.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final isVisible = connectivity.isOffline || connectivity.isSlow;

    if (isVisible) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }

    // ClipRect prevents the banner's shadow and body from
    // bleeding into the visible area while sliding off-screen.
    return ClipRect(
      child: SlideTransition(
        position: _slide,
        child: _buildBanner(connectivity, context),
      ),
    );
  }

  Widget _buildBanner(ConnectivityState connectivity, BuildContext context) {
    final isOffline = connectivity.isOffline;
    final color = isOffline ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final icon = isOffline ? Icons.wifi_off_rounded : Icons.signal_wifi_bad_rounded;
    final label = isOffline
        ? 'No internet connection'
        : 'Slow network detected';
    final sublabel = isOffline
        ? 'Check your connection and retry'
        : 'Some features may be slower than usual';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: color,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white70,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOffline)
                GestureDetector(
                  onTap: () => ref.read(connectivityProvider.notifier).recheck(),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
