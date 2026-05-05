import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_router.dart';
import '../../core/security/session_manager.dart';
import '../../core/security/secure_logger.dart';
import '../../main.dart' show navigatorKey;

/// Premium full-screen session invalidated dialog.
///
/// Shown when the server returns **409 Conflict** with
/// `code: "session_invalidated"`.
///
/// The dialog is non-dismissible — the user MUST tap
/// "Log In Again" which clears all session data and
/// navigates to the login screen.
class SessionInvalidatedDialog {
  SessionInvalidatedDialog._();

  /// Guard flag — prevents stacking multiple dialogs if several
  /// 409 responses arrive simultaneously.
  static bool _isShowing = false;

  /// Show the session-invalidated overlay.
  ///
  /// [message] is the human-readable string from the server's
  /// error response. Falls back to a default if empty/null.
  static Future<void> show({String? message}) async {
    if (_isShowing) return; // already displayed
    _isShowing = true;

    // Clear session first so no further API calls succeed
    await SessionManager.logout();
    SecureLogger.d('SESSION: Invalidated — storage cleared.');

    final nav = navigatorKey.currentState;
    final ctx = navigatorKey.currentContext;
    if (nav == null || ctx == null || !nav.mounted) {
      _isShowing = false;
      return;
    }

    await showGeneralDialog(
      context: ctx,
      barrierDismissible: false,
      barrierLabel: 'session_invalidated',
      barrierColor: Colors.transparent, // we draw our own blur backdrop
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, anim, __) {
        return _SessionInvalidatedOverlay(
          message: message,
          animation: anim,
        );
      },
    );

    _isShowing = false;
  }
}

class _SessionInvalidatedOverlay extends StatelessWidget {
  final String? message;
  final Animation<double> animation;

  const _SessionInvalidatedOverlay({
    this.message,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final displayMsg = (message != null && message!.trim().isNotEmpty)
        ? message!
        : 'You have been logged out because your account was logged in from another device. Please log in again to continue.';

    return PopScope(
      // Block back button — user must tap the button
      canPop: false,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Stack(
            children: [
              // ── Frosted glass backdrop ──
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12 * animation.value,
                    sigmaY: 12 * animation.value,
                  ),
                  child: Container(
                    color: const Color(0xFF0A1628)
                        .withValues(alpha: 0.75 * animation.value),
                  ),
                ),
              ),

              // ── Centered dialog card ──
              Center(
                child: FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: _buildDialogCard(context, displayMsg),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogCard(BuildContext context, String displayMsg) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.08),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Shield icon with gradient ring ──
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF1F0),
                  Color(0xFFFFE0DE),
                  Color(0xFFFFF5F5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring
                Container(
                  width: 68.r,
                  height: 68.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.12),
                      width: 2,
                    ),
                  ),
                ),
                // Inner icon circle
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF6B6B), Color(0xFFE53935)],
                    ),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── Title ──
          Text(
            'Session Expired',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),

          SizedBox(height: 6.h),

          // ── Subtitle badge ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFFE53935).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.devices_other_rounded,
                  size: 12.sp,
                  color: const Color(0xFFE53935),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Logged in on another device',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE53935),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // ── Message ──
          Text(
            displayMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 13.sp,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),

          SizedBox(height: 28.h),

          // ── Divider ──
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // ── Login button ──
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B882C), Color(0xFF003716)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B882C).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to login and clear entire navigation stack
                  navigatorKey.currentState?.pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  );
                },
                icon: Icon(Icons.login_rounded,
                    size: 18.sp, color: Colors.white),
                label: Text(
                  'Log In Again',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
