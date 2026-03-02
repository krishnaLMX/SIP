import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../routes/app_router.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      endDrawer: _buildSideMenu(context),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildPremiumHeader(context, isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 32.h),
                        _buildPortfolioCard(isDark),
                        SizedBox(height: 48.h),
                        _buildSectionHeader('Artisanal Curations', isDark),
                        SizedBox(height: 24.h),
                        _buildCategoryGrid(isDark),
                        SizedBox(height: 48.h),
                        _buildSectionHeader('Exquisite Performance', isDark),
                        SizedBox(height: 24.h),
                        _buildGrowthChart(isDark),
                        SizedBox(height: 120.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isDark) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: PremiumHomeHeader(
        expandedHeight: 180.h,
        statusBarHeight: MediaQuery.of(context).padding.top,
        isDark: isDark,
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40.h),
            _buildDrawerHeader(isDark),
            SizedBox(height: 40.h),
            _buildMenuItem(
              context,
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              subtitle: 'KYC & Settings',
              route: AppRouter.profile,
            ),
            _buildMenuItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Statements',
              subtitle: 'Reports & Tax',
              route: AppRouter.statements,
            ),
            _buildMenuItem(
              context,
              icon: Icons.card_giftcard_outlined,
              title: 'Refer & Earn',
              subtitle: 'Win Gold Rewards',
              route: AppRouter.referral,
            ),
            const Spacer(),
            _buildMenuItem(
              context,
              icon: Icons.help_outline_rounded,
              title: 'Support',
              subtitle: '24/7 Assistance',
              route: AppRouter.support,
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Secure Sign out',
              onTap: () => _handleLogout(context),
              isDestructive: true,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppTheme.arcticBlue, AppTheme.electricCyan]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.white, size: 30.sp),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alexander West',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'Verified Member',
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  color: AppTheme.electricCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? route,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.redAccent
            : (isDark ? Colors.white70 : Colors.black54),
        size: 26.sp,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: isDestructive
              ? Colors.redAccent
              : (isDark ? Colors.white : Colors.black),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12.sp,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
      onTap: onTap ?? () => Navigator.pushNamed(context, route!),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pushNamedAndRemoveUntil(
        context, AppRouter.login, (route) => false);
  }

  Widget _buildPortfolioCard(bool isDark) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.all(32.w),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.arcticBlue,
              AppTheme.midnightNavy,
            ],
          ),
          borderRadius: BorderRadius.circular(40.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.arcticBlue.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL PORTFOLIO',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Icon(Icons.unfold_more_rounded,
                    color: Colors.white.withOpacity(0.6), size: 18.sp),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              '₹ 4,72,900.00',
              style: GoogleFonts.outfit(
                fontSize: 38.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 32.h),
            Row(
              children: [
                _buildPortfolioStat('+ 12.4%', 'Net Growth', true),
                Container(
                    width: 1.w,
                    height: 32.h,
                    color: Colors.white12,
                    margin: EdgeInsets.symmetric(horizontal: 24.w)),
                _buildPortfolioStat('₹ 52,100', 'Dividend', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioStat(String value, String label, bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: isPositive ? AppTheme.electricCyan : Colors.white70,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            color: Colors.white38,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            'Explore All',
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.arcticBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 400),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 20.w,
        crossAxisSpacing: 20.w,
        childAspectRatio: 0.85,
        children: [
          _buildCategoryCard(
              'Artisanal Gold',
              'Traditional Vault',
              'file:///C:/Users/admin/.gemini/antigravity/brain/ef876d95-299c-4dcc-8e4f-15ccc4594d12/gold_ring_onboarding_1772104089487.png',
              isDark),
          _buildCategoryCard(
              'Digital Elite',
              'Diamond-Backed',
              'file:///C:/Users/admin/.gemini/antigravity/brain/ef876d95-299c-4dcc-8e4f-15ccc4594d12/diamond_necklace_onboarding_1772104068669.png',
              isDark),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, String desc, String image, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(31.r)),
              child: Image.network(image,
                  fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(bool isDark) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 500),
      child: Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: Center(
          child: Text(
            'Dynamic Performance Visualization',
            style: GoogleFonts.outfit(
                color: isDark ? Colors.white24 : Colors.black12,
                fontSize: 13.sp),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Positioned(
      bottom: 24.h,
      left: 24.w,
      right: 24.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12, width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.category_rounded, true, isDark),
            _buildNavItem(Icons.pie_chart_outline_rounded, false, isDark),
            _buildNavItem(Icons.lock_person_outlined, false, isDark),
            _buildNavItem(Icons.person_outline_rounded, false, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: isActive
          ? BoxDecoration(
              color: AppTheme.arcticBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.arcticBlue.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2),
              ],
            )
          : null,
      child: Icon(
        icon,
        color: isActive
            ? Colors.white
            : (isDark ? Colors.white38 : Colors.black38),
        size: 24.sp,
      ),
    );
  }
}

class PremiumHomeHeader extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double statusBarHeight;
  final bool isDark;

  PremiumHomeHeader({
    required this.expandedHeight,
    required this.statusBarHeight,
    required this.isDark,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double percent = shrinkOffset / expandedHeight;
    final double opacity = (1 - percent).clamp(0.0, 1.0);
    final double reverseOpacity = percent.clamp(0.0, 1.0);

    return Stack(
      children: [
        // 1. Background Liquid Gold Aura
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: const LiquidGoldAura(),
          ),
        ),

        // 2. Glassmorphic Surface (Visible on scroll)
        Positioned.fill(
          child: Opacity(
            opacity: reverseOpacity,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: isDark
                      ? const Color(0xFF020617).withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),

        // 3. Animated Branding Content
        SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Stack(
              children: [
                // Centered Hero Logo
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -10.h * percent),
                        child: Transform.scale(
                          scale: (1 - (percent * 0.35)).clamp(0.65, 1.0),
                          child: Hero(
                            tag: 'header_logo',
                            child: Image.asset(
                              'assets/images/header.png',
                              height: 52.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Opacity(
                        opacity: (1 - (percent * 2)).clamp(0.0, 1.0),
                        child: Text(
                          AppConstants.companyName,
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8.0,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Left: Profile Info (Morphs into View)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: reverseOpacity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.arcticBlue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 16.r,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            child: Text(
                              'A',
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.arcticBlue,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'START GOLD',
                              style: GoogleFonts.outfit(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Welcome, Krishna',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Action Icons (Menu & Notifications)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openEndDrawer(),
                          child: _buildActionIcon(Icons.menu_rounded, isDark),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      _buildActionIcon(
                          Icons.notifications_none_rounded, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, bool isDark) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Icon(
        icon,
        size: 20.sp,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => statusBarHeight + 70.h;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}

class LiquidGoldAura extends StatefulWidget {
  const LiquidGoldAura({super.key});

  @override
  State<LiquidGoldAura> createState() => _LiquidGoldAuraState();
}

class _LiquidGoldAuraState extends State<LiquidGoldAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.8 + (_controller.value * 0.2),
                  colors: [
                    AppTheme.arcticBlue
                        .withOpacity(0.12 * (1 - _controller.value)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Floating Sparkle Particles (Simulated)
            ...List.generate(5, (index) {
              return Positioned(
                left: (20 + (index * 60)).w,
                top: (40 + (index * 20)).h,
                child: Opacity(
                  opacity: (0.1 + (_controller.value * 0.1)).clamp(0, 1),
                  child: Container(
                    width: 2.r,
                    height: 2.r,
                    decoration: const BoxDecoration(
                      color: AppTheme.arcticBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
