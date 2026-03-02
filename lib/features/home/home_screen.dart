import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../routes/app_router.dart';

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
                _buildAppBar(context, isDark),
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

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'Lord Alexander',
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openEndDrawer(),
            child: Container(
              margin: EdgeInsets.only(right: 24.w),
              height: 44.w,
              width: 44.w,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12, width: 1),
              ),
              child: Icon(Icons.menu_rounded,
                  size: 22.sp, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
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
              icon: Icons.history_rounded,
              title: 'Order Tracking',
              subtitle: 'Track Your Gold',
              route: AppRouter.statements,
            ),
            _buildMenuItem(
              context,
              icon: Icons.card_giftcard_outlined,
              title: 'Refer & Earn',
              subtitle: 'Win Gold Rewards',
              route: AppRouter.referral,
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'MPIN & Security',
              route: AppRouter.settings,
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

  // demo

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
