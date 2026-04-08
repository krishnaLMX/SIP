import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Toast type determines color palette and icon.
enum ToastType { success, error, warning, info }

/// AppToast
///
/// Premium floating overlay toast with:
///   • fade-in + upward slide entry
///   • auto-dismiss after [duration]
///   • fade-out exit
///   • success / error / warning / info variants
///
/// Usage:
/// ```dart
/// AppToast.show(context, 'Withdrawal Successful!', type: ToastType.success);
/// AppToast.show(context, 'Network error', type: ToastType.error);
/// ```
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2800),
    bool showAtBottom = true,
  }) {
    // Dismiss any active toast immediately
    _dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        showAtBottom: showAtBottom,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final bool showAtBottom;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.showAtBottom,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // Slide up from bottom, or slide down from top
    _slide = Tween<Offset>(
      begin: widget.showAtBottom
          ? const Offset(0, 0.35)
          : const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _ToastStyle get _style => _resolveStyle(widget.type);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPad = mediaQuery.padding.bottom;
    final topPad = mediaQuery.padding.top;

    return Positioned(
      left: 20.w,
      right: 20.w,
      bottom: widget.showAtBottom ? bottomPad + 24.h : null,
      top: !widget.showAtBottom ? topPad + 12.h : null,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: _buildCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 480.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _style.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _style.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _style.shadow,
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon pill
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: _style.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(_style.icon, color: _style.iconColor, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          // Message
          Flexible(
            child: Text(
              widget.message,
              style: GoogleFonts.lora(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w500,
                color: _style.textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ToastStyle _resolveStyle(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastStyle(
          background: const Color(0xFFF0FDF4),
          border: const Color(0xFFBBF7D0),
          shadow: const Color(0xFF16A34A).withOpacity(0.18),
          iconBackground: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          icon: Icons.check_circle_rounded,
          textColor: const Color(0xFF14532D),
        );
      case ToastType.error:
        return _ToastStyle(
          background: const Color(0xFFFFF1F2),
          border: const Color(0xFFFECDD3),
          shadow: const Color(0xFFDC2626).withOpacity(0.18),
          iconBackground: const Color(0xFFFFE4E6),
          iconColor: const Color(0xFFDC2626),
          icon: Icons.error_rounded,
          textColor: const Color(0xFF7F1D1D),
        );
      case ToastType.warning:
        return _ToastStyle(
          background: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          shadow: const Color(0xFFD97706).withOpacity(0.18),
          iconBackground: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          icon: Icons.warning_amber_rounded,
          textColor: const Color(0xFF78350F),
        );
      case ToastType.info:
        return _ToastStyle(
          background: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
          shadow: const Color(0xFF2563EB).withOpacity(0.18),
          iconBackground: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF2563EB),
          icon: Icons.info_rounded,
          textColor: const Color(0xFF1E3A5F),
        );
    }
  }
}

class _ToastStyle {
  final Color background;
  final Color border;
  final Color shadow;
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
  final Color textColor;

  const _ToastStyle({
    required this.background,
    required this.border,
    required this.shadow,
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
    required this.textColor,
  });
}
