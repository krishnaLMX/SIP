import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../home/home_screen.dart';
import '../instant_saving/instant_saving_screen.dart';
import '../history/screens/transaction_history_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/providers/home_dashboard_provider.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/instant_saving/controller/saving_controller.dart';
import '../../features/history/controller/history_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../features/auth/controller/auth_controller.dart';

/// Shared provider so any child screen can switch tabs
final selectedTabProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Reset to Home tab after mount when navigating from payment success.
    // Deferred via addPostFrameCallback to avoid !_doingMountOrUpdate crash.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['resetTab'] == true) {
        // Direct state set — no provider invalidation here.
        // Each screen manages its own data refresh.
        ref.read(selectedTabProvider.notifier).state = 0;
      }

      // Rehydrate auth state from SecureStorage first.
      // The forgot PIN flow's OTP verify may overwrite sessionData with
      // temp_token (no user.id_customer), causing userProvider to return null
      // and dashboard/portfolio APIs to not fire.
      await ref.read(authControllerProvider.notifier).rehydrateFromStorage();

      // Force fresh API calls on MainScreen mount (e.g. after MPIN verify).
      ref.invalidate(homeDashboardProvider);
      ref.invalidate(portfolioProvider);
      ref.invalidate(profileProvider);
    });
  }

  /// Called ONLY from user-initiated tab taps — never during navigation.
  /// This is the safe place to refresh providers without causing
  /// !_doingMountOrUpdate assertion errors.
  void _onTabTapped(int index) {
    final current = ref.read(selectedTabProvider);
    ref.read(selectedTabProvider.notifier).state = index;
    if (current == index) return; // same tab — no refresh needed
    switch (index) {
      case 0:
        ref.invalidate(homeDashboardProvider);
        ref.invalidate(profileProvider);
        break;
      case 1:
        // InstantSavingScreen auto-refreshes its own providers
        ref.invalidate(savingConfigProvider);
        break;
      case 2:
        ref.invalidate(historyProvider);
        ref.invalidate(portfolioProvider);
        break;
      case 3:
        ref.invalidate(profileProvider);
        break;
    }
  }

  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedTabProvider);

    // Mark current tab as visited
    if (!_visitedTabs.contains(selectedIndex)) {
      _visitedTabs.add(selectedIndex);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // If not on Home tab, go to Home instead of exiting
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(selectedTabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: selectedIndex,
              children: [
                const HomeScreen(),
                _visitedTabs.contains(1)
                    ? const InstantSavingScreen()
                    : const SizedBox.shrink(),
                _visitedTabs.contains(2)
                    ? const TransactionHistoryScreen()
                    : const SizedBox.shrink(),
                _visitedTabs.contains(3)
                    ? const ProfileScreen()
                    : const SizedBox.shrink(),
              ],
            ),
            if (selectedIndex == 0) _buildBottomNav(ref, selectedIndex, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(WidgetRef ref, int selectedIndex, bool isDark) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Positioned(
      bottom: bottomPadding + 16.h,
      left: 16.w,
      right: 16.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.6)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(ref, Icons.home_rounded, 'Home',
                    selectedIndex == 0, isDark, 0,
                    svgAsset: 'assets/footer/home.svg'),
                _buildNavItem(ref, Icons.bolt_rounded, 'Invest',
                    selectedIndex == 1, isDark, 1,
                    svgAsset: 'assets/footer/invest.svg'),
                _buildNavItem(ref, Icons.history_rounded, 'History',
                    selectedIndex == 2, isDark, 2,
                    svgAsset: 'assets/footer/history.svg'),
                _buildNavItem(ref, Icons.person_outline_rounded, 'Profile',
                    selectedIndex == 3, isDark, 3,
                    svgAsset: 'assets/footer/profile.svg'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(WidgetRef ref, IconData icon, String label,
      bool isActive, bool isDark, int index,
      {String? svgAsset}) {
    final inactiveColor = isDark ? Colors.white54 : const Color(0xFF666666);

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(20.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            child: svgAsset != null
                ? SvgPicture.asset(
                    svgAsset,
                    width: 22.sp,
                    height: 22.sp,
                    colorFilter: isActive
                        ? null
                        : ColorFilter.mode(
                            inactiveColor,
                            BlendMode.srcIn,
                          ),
                  )
                : Icon(
                    icon,
                    color: isActive ? AppTheme.primaryGreen : inactiveColor,
                    size: 22.sp,
                  ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppTheme.primaryGreen : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
