import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../routes/app_router.dart';
import '../../core/providers/market_provider.dart';
import '../market/models/market_rates.dart';
import '../../core/providers/commodity_provider.dart';
import '../../core/providers/portfolio_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/shared_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/language_provider.dart';

import '../../core/network/native_socket_service.dart';
import '../auth/controller/auth_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedDailyAmount = '₹100';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCommodity = ref.watch(commodityProvider);
    final userProfile = ref.watch(userProvider);
    final portfolioState = ref.watch(portfolioProvider);
    final marketRates = ref.watch(marketRatesStreamProvider);
    final socketStatus =
        ref.watch(socketStatusProvider).value ?? SocketStatus.disconnected;

    final String customerName =
        userProfile?.name ?? ref.tr('investorLabel', fallback: 'Investor');
    final String mobile = userProfile?.mobile ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      endDrawer: _buildSideMenu(context,
          name: customerName, mobile: mobile, photoUrl: userProfile?.photoUrl),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(portfolioProvider.notifier).fetchPortfolio(),
              color: AppTheme.arcticBlue,
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  _buildPremiumHeader(
                      context, isDark, customerName, userProfile?.photoUrl),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 24.h),
                          _buildCommoditySelector(
                              isDark, selectedCommodity, marketRates),
                          SizedBox(height: 24.h),
                          _buildLiveRateCard(isDark, marketRates, socketStatus,
                              selectedCommodity),
                          SizedBox(height: 32.h),
                          portfolioState.when(
                            data: (data) => data.isNewCustomer
                                ? _buildJoinBanner(isDark)
                                : _buildPortfolioOverview(isDark, data,
                                    selectedCommodity, marketRates),
                            loading: () => _buildPortfolioLoading(isDark),
                            error: (e, st) => _buildPortfolioError(isDark),
                          ),
                          SizedBox(height: 48.h),
                          _buildSectionHeader(
                              ref.tr('artisanalHeader'), isDark),
                          SizedBox(height: 24.h),
                          _buildCategoryGrid(isDark),
                          SizedBox(height: 120.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isDark,
      String customerName, String? photoUrl) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: PremiumHomeHeader(
        expandedHeight: statusBarHeight + 175.h,
        statusBarHeight: statusBarHeight,
        isDark: isDark,
        customerName: customerName,
        welcomeText: ref.tr('welcome'),
        photoUrl: photoUrl,
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context,
      {required String name, required String mobile, String? photoUrl}) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),
                      _buildDrawerHeader(isDark, name, photoUrl),
                      SizedBox(height: 40.h),
                      
                      _buildDrawerSection(ref.tr('accountSection', fallback: 'ACCOUNT'), isDark),
                      _buildMenuItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: ref.tr('myProfile'),
                        subtitle: ref.tr('kycSettingsSubtitle'),
                        route: AppRouter.profile,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        title: ref.tr('statements'),
                        subtitle: ref.tr('reportsTaxSubtitle'),
                        route: AppRouter.statements,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.card_giftcard_outlined,
                        title: ref.tr('referEarn'),
                        subtitle: ref.tr('winGoldRewardsSubtitle'),
                        route: AppRouter.referral,
                      ),

                      Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 32.h, indent: 24.w, endIndent: 24.w),
                      
                      _buildDrawerSection(ref.tr('supportSection', fallback: 'SUPPORT & HELP'), isDark),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: ref.tr('faqTitle', fallback: 'FAQs'),
                        subtitle: ref.tr('faqSubtitle', fallback: 'Common questions & answers'),
                        route: AppRouter.faq,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.contact_support_outlined,
                        title: ref.tr('contactUsTitle', fallback: 'Contact Us'),
                        subtitle: ref.tr('contactUsSubtitle', fallback: 'Get in touch with us'),
                        route: AppRouter.contact,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.question_answer_outlined,
                        title: ref.tr('myEnquiriesTitle', fallback: 'My Enquiries'),
                        subtitle: ref.tr('myEnquiriesSubtitle', fallback: 'Track your support history'),
                        route: AppRouter.enquiryList,
                      ),

                      Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 32.h, indent: 24.w, endIndent: 24.w),

                      _buildDrawerSection(ref.tr('legalSection', fallback: 'LEGAL & ABOUT'), isDark),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: ref.tr('aboutUsTitle', fallback: 'About Us'),
                        subtitle: ref.tr('aboutUsSubtitle', fallback: 'Our mission and story'),
                        route: AppRouter.about,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.description_outlined,
                        title: ref.tr('termsTitle', fallback: 'Terms & Conditions'),
                        subtitle: ref.tr('termsSubtitle', fallback: 'Read our usage terms'),
                        route: AppRouter.terms,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: ref.tr('privacyTitle', fallback: 'Privacy Policy'),
                        subtitle: ref.tr('privacySubtitle', fallback: 'How we protect your data'),
                        route: AppRouter.privacy,
                      ),

                      Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 32.h, indent: 24.w, endIndent: 24.w),

                      _buildDrawerSection(ref.tr('preferencesSection', fallback: 'PREFERENCES'), isDark),
                      _buildLanguageSelector(context),
                      
                      SizedBox(height: 32.h),
                      _buildMenuItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: ref.tr('logout'),
                        subtitle: ref.tr('secureSignOutSubtitle'),
                        onTap: () => _handleLogout(context),
                        isDestructive: true,
                      ),
                      SizedBox(height: 48.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

<<<<<<< Updated upstream
  // demo

  Widget _buildDrawerHeader(bool isDark) {
=======
  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(builder: (context, ref, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ref.tr('languageSelector', fallback: 'Change Language'),
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  )),
              SizedBox(height: 8.h),
              Text(
                ref.tr('chooseLanguagePref',
                    fallback: 'Choose your preferred language'),
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 24.h),
              _buildLangOption(context, ref, 'English', 'en', isDark),
              _buildLangOption(context, ref, 'தமிழ் (Tamil)', 'ta', isDark),
              _buildLangOption(context, ref, 'తెలుగు (Telugu)', 'te', isDark),
              SizedBox(height: 16.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLangOption(BuildContext context, WidgetRef ref, String title,
      String code, bool isDark) {
    final currentCode = ref.watch(languageProvider).currentLocale;
    final isSelected = currentCode == code;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? AppTheme.arcticBlue
                : (isDark ? Colors.white70 : Colors.black87),
          )),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppTheme.arcticBlue)
          : null,
      onTap: () {
        ref.read(languageProvider.notifier).setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: () => _showLanguageBottomSheet(context),
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      leading: Icon(
        Icons.language_rounded,
        color: isDark ? Colors.white70 : Colors.black54,
        size: 26.sp,
      ),
      title: Text(
        ref.tr('languageTitle', fallback: 'Language'),
        style: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        ref.tr('languageSubtitle', fallback: 'English / தமிழ் / తెలుగు'),
        style: GoogleFonts.outfit(
          fontSize: 12.sp,
          color: isDark ? Colors.white54 : Colors.black45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDark, String name, String? photoUrl) {
>>>>>>> Stashed changes
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
              image: photoUrl != null && photoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null || photoUrl.isEmpty
                ? Icon(Icons.person, color: Colors.white, size: 30.sp)
                : null,
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                ref.tr('verifiedMember'),
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

  Widget _buildDrawerSection(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            ref.tr('exploreAll', fallback: AppConstants.exploreAll),
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
        childAspectRatio: 0.82,
        children: [
          _buildCategoryCard(
              ref.tr('artisanalGold'),
              ref.tr('purest24KT'),
              'https://images.unsplash.com/photo-1599643477877-530eb83abc8e?q=80&w=800&auto=format&fit=crop',
              isDark),
          _buildCategoryCard(
              ref.tr('silverElite'),
              ref.tr('hallmark999'),
              'https://images.unsplash.com/photo-1535556116002-6281ff3e9f36?q=80&w=800&auto=format&fit=crop',
              isDark),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, String desc, String image, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(27.r)),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  child: Icon(Icons.image_rounded,
                      color: isDark ? Colors.white24 : Colors.black12),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRouter.login, (route) => false);
    }
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

  Widget _buildCommoditySelector(bool isDark, CommodityType selected,
      AsyncValue<MarketRates> marketRates) {
    final goldLabel = marketRates.valueOrNull?.goldName ?? 'Gold';
    final silverLabel = marketRates.valueOrNull?.silverName ?? 'Silver';

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          _buildPill(isDark, goldLabel, selected == CommodityType.gold, true,
              () {
            ref
                .read(commodityProvider.notifier)
                .setCommodity(CommodityType.gold);
          }),
          _buildPill(
              isDark, silverLabel, selected == CommodityType.silver, false, () {
            ref
                .read(commodityProvider.notifier)
                .setCommodity(CommodityType.silver);
          }),
        ],
      ),
    );
  }

  Widget _buildPill(bool isDark, String label, bool isSelected, bool isGold,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            gradient: isSelected
                ? (isGold
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                      ))
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.white54 : Colors.grey[700]),
              fontSize: 15.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveRateCard(bool isDark, AsyncValue<MarketRates> marketRates,
      SocketStatus status, CommodityType type) {
    return marketRates.when(
      data: (rates) {
        final price =
            type == CommodityType.gold ? rates.goldSell : rates.silverSell;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF6366F1))
                    .withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: AppTheme.arcticBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.arcticBlue.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        ref.tr('liveMarketRate'),
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  _buildFluctuationBadge(
                      type == CommodityType.gold
                          ? rates.goldChange
                          : rates.silverChange,
                      type == CommodityType.gold
                          ? rates.goldPercentage
                          : rates.silverPercentage,
                      isDark),
                ],
              ),
              SizedBox(height: 20.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF020617),
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Per 1 gram',
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ),
                  Text(
                    '${AppConstants.lastUpdated} ${TimeOfDay.fromDateTime(rates.timestamp).format(context)}',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildPortfolioLoading(isDark),
      error: (e, st) => _buildPortfolioError(isDark),
    );
  }

  Widget _buildJoinBanner(bool isDark) {
    final denominations = ref.watch(amountDenominationsProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF4F46E5), const Color(0xFF312E81)]
              : [const Color(0xFF6366F1), const Color(0xFF4338CA)],
        ),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Aura
          Positioned(
            top: -50.h,
            right: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(28.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref.tr('saveDailyMessage', args: {'amount': '50'}),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            ref.tr('goldCoinsReward',
                                args: {'count': '3', 'duration': '1 Year'}),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_graph_rounded,
                          color: Colors.white, size: 20.sp),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24.r),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12.w,
                            height: 2.h,
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              ref.tr('chooseInvestment'),
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 12.w,
                            height: 2.h,
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      denominations.when(
                        data: (list) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: list.take(4).map((denom) {
                              final amt = '₹${denom.value.toInt()}';
                              final isSelected = amt == _selectedDailyAmount;
                              return Padding(
                                padding: EdgeInsets.only(right: 12.w),
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedDailyAmount = amt),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 12.h),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      amt,
                                      style: GoogleFonts.outfit(
                                        color: isSelected
                                            ? const Color(0xFF4F46E5)
                                            : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white70)),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  height: 60.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.instantSaving,
                        arguments: {
                          'initialAmount':
                              _selectedDailyAmount.replaceAll('₹', ''),
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              ref.tr('startDailySaving'),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 17.sp,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_ios_rounded,
                              size: 14.sp, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioOverview(bool isDark, PortfolioData data,
      CommodityType selected, AsyncValue<MarketRates> market) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF312E81)],
        ),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: 40,
            child: Opacity(
              opacity: 0.3,
              child:
                  Icon(Icons.auto_awesome, color: Colors.white, size: 120.sp),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            market.maybeWhen(
                              data: (rates) =>
                                  'Your ${selected == CommodityType.gold ? rates.goldName : rates.silverName} Savings',
                              orElse: () =>
                                  'Your ${selected == CommodityType.gold ? "Gold" : "Silver"} Savings',
                            ),
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${data.summary.balance.toStringAsFixed(4)} g',
                                style: GoogleFonts.outfit(
                                    fontSize: 42.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    height: 1)),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      '${ref.tr('totalInvestedLabel')}: ₹${data.summary.totalInvested.toStringAsFixed(0)}',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500)),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  data.summary.returns >= 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: data.summary.returns >= 0
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  '₹${data.summary.returns.abs().toStringAsFixed(0)} (${data.summary.returnsPercentage.toStringAsFixed(2)}%)',
                                  style: GoogleFonts.outfit(
                                      color: data.summary.returns >= 0
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        if (data.summary.hasActiveAccount) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, AppRouter.withdrawal),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.1),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    side: const BorderSide(
                                        color: Colors.white24)),
                                elevation: 0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(ref.tr('withdraw'),
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16.sp)),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRouter.instantSaving),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r)),
                              elevation: 0,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on, size: 16.sp),
                                  SizedBox(width: 4.w),
                                  Text(ref.tr('saveInstantly'),
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15.sp)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioLoading(bool isDark) =>
      Center(child: CircularProgressIndicator(color: AppTheme.arcticBlue));
  Widget _buildPortfolioError(bool isDark) => Center(
      child: Text(ref.tr('portfolioError',
          fallback: 'Failed to load portfolio context.')));

  Widget _buildFluctuationBadge(double change, double percentage, bool isDark) {
    if (change == 0) return const SizedBox.shrink();

    final isUp = change > 0;
    // Premium theme colors
    final baseColor = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: baseColor.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: baseColor, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            '${isUp ? "+" : ""}${percentage.toStringAsFixed(2)}%',
            style: GoogleFonts.outfit(
              color: baseColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumHomeHeader extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double statusBarHeight;
  final bool isDark;
  final String customerName;
  final String welcomeText;
  final String? photoUrl;

  PremiumHomeHeader({
    required this.expandedHeight,
    required this.statusBarHeight,
    required this.isDark,
    required this.customerName,
    required this.welcomeText,
    this.photoUrl,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double range = maxExtent - minExtent;
    final double percent =
        range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 0.0;
    final double opacity = (1 - percent).clamp(0.0, 1.0);
    final double reverseOpacity = percent.clamp(0.0, 1.0);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: reverseOpacity * 10, sigmaY: reverseOpacity * 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF020617).withOpacity(0.8 + (percent * 0.2))
                : Colors.white.withOpacity(0.8 + (percent * 0.2)),
            border: Border(
              bottom: BorderSide(
                color: reverseOpacity > 0.1
                    ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))
                    : Colors.transparent,
                width: 1,
              ),
            ),
            boxShadow: [
              if (reverseOpacity > 0.5)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            children: [
              if (opacity > 0.1)
                Positioned.fill(
                  child: Opacity(
                    opacity: opacity,
                    child: const IgnorePointer(child: LiquidGoldAura()),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                    top: statusBarHeight, left: 24.w, right: 24.w),
                child: Column(
                  children: [
                    SizedBox(
                      height: 60.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo Left
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/header.png',
                                height: 28.h + (opacity * 4.h),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.diamond_rounded,
                                        color: AppTheme.arcticBlue,
                                        size: 24.sp),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                AppConstants.companyName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          // Actions Right
                          Row(
                            children: [
                              _buildNotificationIcon(isDark),
                              SizedBox(width: 16.w),
                              Builder(
                                builder: (context) => GestureDetector(
                                  onTap: () =>
                                      Scaffold.of(context).openEndDrawer(),
                                  child: photoUrl != null &&
                                          photoUrl!.isNotEmpty
                                      ? Container(
                                          width: 36.r,
                                          height: 36.r,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppTheme.arcticBlue
                                                    .withOpacity(0.3),
                                                width: 1.5),
                                            image: DecorationImage(
                                              image: NetworkImage(photoUrl!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : _buildActionIcon(
                                          Icons.menu_rounded, isDark),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (opacity > 0.5)
                      Expanded(
                        child: Opacity(
                          opacity: ((opacity - 0.5) / 0.5).clamp(0.0, 1.0),
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    welcomeText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    customerName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: -1,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildNotificationIcon(bool isDark) {
    return Stack(
      children: [
        _buildActionIcon(Icons.notifications_none_rounded, isDark),
        Positioned(
          right: 4.w,
          top: 4.h,
          child: Container(
            width: 8.r,
            height: 8.r,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
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
      ),
      child: Icon(
        icon,
        size: 20.sp,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => statusBarHeight + 80.h;

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
