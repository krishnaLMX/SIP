import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/security/session_manager.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/services/app_control_service.dart';
import '../../core/models/app_control_model.dart';
import '../../routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final minSplashDuration =
        Future.delayed(const Duration(milliseconds: 2000));

    bool loggedIn = false;
    bool mpinEnabled = false;

    try {
      loggedIn = await SessionManager.isAuthenticated();
      mpinEnabled = await SecureStorageService.isMpinEnabled();
    } catch (e) {
      debugPrint('Splash init error: $e');
    }

    // Determine normal route
    // SECURITY: If logged in but PIN was never set (mpin_enabled=false),
    // force re-authentication via login → OTP → PIN setup.
    // This covers the edge case where register succeeded but app was
    // killed before PIN creation completed.
    String nextRoute = AppRouter.login;
    if (loggedIn && mpinEnabled) {
      nextRoute = AppRouter.mpin;
    }

    // Maintenance gate
    Map<String, dynamic>? maintenanceArgs;
    try {
      final controlService = AppControlService();
      final raw = await controlService.fetchAppControl();
      if (raw != null) {
        final controlData = AppControlData.fromJson(raw);
        if (controlData.maintenance.isEnabled) {
          maintenanceArgs = {'resumeRoute': nextRoute};
          nextRoute = AppRouter.maintenance;
        }
      }
    } catch (_) {
      // Silent fail — continue normally
    }

    await minSplashDuration;

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      nextRoute,
      arguments: maintenanceArgs,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // ── Layer 1: Full background image ──
              Positioned.fill(
                child: Image.asset(
                  'assets/resources/splash_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFEF7E6), Color(0xFFF8D89C)],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Layer 2: Center animated GIF ──
              Center(
                child: Image.asset(
                  'assets/resources/Splashscreen.gif',
                  width: 100.w,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/resources/splash.png',
                    width: 220.w,
                  ),
                ),
              ),

              // ── Layer 3: Footer SVG fixed at bottom ──
              Positioned(
                left: 32.w,
                right: 32.w,
                bottom: MediaQuery.of(context).padding.bottom + 20.h,
                child: SvgPicture.asset(
                  'assets/resources/splash_footer.svg',
                  height: 28.h,
                  fit: BoxFit.contain,
                  // ignore: deprecated_member_use
                  placeholderBuilder: (_) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
