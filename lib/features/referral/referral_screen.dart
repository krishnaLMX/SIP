import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_toast.dart';

import '../main/main_screen.dart';
import '../../routes/app_router.dart';
import 'referral_service.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    // Force fresh API call every time this screen opens
    Future.microtask(() {
      ref.invalidate(referralDataProvider);
    });
  }

  // ── Open WhatsApp with a pre-filled message ────────────────────────────────
  Future<void> _inviteViaWhatsApp(
      BuildContext context, String code, String rewardAmount) async {
    final text = Uri.encodeComponent(
      '🌟 Join me on StartGold and earn $rewardAmount in free Digital Gold!\n\n'
      'Use my referral code: *$code*\n\n'
      'Download now 👇\nhttps://startgold.com/download',
    );
    final waUrl = Uri.parse('whatsapp://send?text=$text');
    final waWebUrl = Uri.parse('https://wa.me/?text=$text');

    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl);
    } else if (await canLaunchUrl(waWebUrl)) {
      await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppToast.show(context, 'WhatsApp is not installed',
            type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralAsync = ref.watch(referralDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Gradient Header (extends to cover hero section too) ────────────
          _buildHeroHeader(context, ref, referralAsync),

          // ── White scrollable body ─────────────────────────────────────────
          Expanded(
            child: referralAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildBody(context, ref, ReferralData.empty),
              data: (data) => _buildBody(context, ref, data),
            ),
          ),
        ],
      ),
      // ── Fixed footer ─────────────────────────────────────────────────────
      bottomNavigationBar: referralAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => _buildFooter(context, '', ''),
        data: (data) => _buildFooter(context, data.referralCode, data.rewardAmount),
      ),
    );
  }

  // ── Full green hero header ─────────────────────────────────────────────────
  Widget _buildHeroHeader(
      BuildContext context, WidgetRef ref, AsyncValue<ReferralData> asyncData) {
    final rewardText = asyncData.when(
      data: (d) {
        if (d.rewardAmount.isEmpty) return '';
        // API returns just the number (e.g. "250"), prepend ₹ if not already present
        final amt = d.rewardAmount;
        return amt.startsWith('₹') ? amt : '₹$amt';
      },
      loading: () => '',
      error: (_, __) => '',
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.87, -0.5),
          end: Alignment(0.87, 0.5),
          colors: [Color(0xFF003716), Color(0xFF167525)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // nav row
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20.sp),
                  onPressed: () {
                    final routeName = ModalRoute.of(context)?.settings.name;
                    if (routeName == AppRouter.referral) {
                      Navigator.pop(context);
                    } else {
                      ref.read(selectedTabProvider.notifier).state = 0;
                    }
                  },
                ),
                Text(
                  'Refer & Earn',
                  style: GoogleFonts.lora(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Hero content — Stack so image sits bottom-right
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 16.w, 28.h),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Left: text content
                  Padding(
                    padding: EdgeInsets.only(right: 100.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title: Lora 20sp / w600 / line-height 30 ──
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.lora(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'Invite a friend and earn '),
                              TextSpan(
                                text: rewardText,
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: ' worth of Gold.'),
                            ],
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // ── Bullets: Lora 14sp / w500 / line-height 20 ──
                        _buildBullet(
                            'Share the link with friends, family, and relatives.'),
                        SizedBox(height: 10.h),
                        _buildBullet(
                            'Both you and your friend get $rewardText worth of gold.'),
                      ],
                    ),
                  ),

                  // Right: referral image (SVG)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Image.asset(
                      'assets/home/referal.png',
                      width: 110.w,
                      height: 110.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          margin: EdgeInsets.only(top: 3.h, right: 10.w),
          decoration: const BoxDecoration(
            color: Color(0xFFFDE047),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              height: 1.43, // 20px / 14px
            ),
          ),
        ),
      ],
    );
  }

  // ── White body: referral code + invite ────────────────────────────────────
  Widget _buildBody(BuildContext context, WidgetRef ref, ReferralData data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Your Referral Code ───────────────────────────────────────
          Text(
            'Your Referral Code',
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 10.h),
          _buildInputRow(
            value: data.referralCode.isNotEmpty ? data.referralCode : 'AQWYSJ',
            trailing: GestureDetector(
              onTap: () {
                final code =
                    data.referralCode.isNotEmpty ? data.referralCode : 'AQWYSJ';
                Clipboard.setData(ClipboardData(text: code));
                AppToast.show(context, 'Referral code copied!',
                    type: ToastType.success);
              },
              child: Icon(Icons.copy_outlined,
                  color: AppTheme.primaryGreen, size: 22.sp),
            ),
          ),

          SizedBox(height: 24.h),

          // ── Invite via WhatsApp label ─────────────────────────────────
          Text(
            'Invite via WhatsApp',
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 10.h),
          _buildInputRow(
            value: data.referralCode.isNotEmpty ? data.referralCode : 'AQWYSJ',
            trailing: GestureDetector(
              onTap: () => _inviteViaWhatsApp(
                  context,
                  data.referralCode.isNotEmpty ? data.referralCode : 'AQWYSJ',
                  data.rewardAmount),
              child: SvgPicture.asset(
                'assets/withdraw/whatsapp.svg',
                width: 36.w,
                height: 36.w,
              ),
            ),
          ),

          SizedBox(height: 32.h),

          // ── Stats row (hidden for now) ──────────────────────────────────
          // if (data.totalReferrals > 0 || data.totalEarned > 0) ...[
          //   Row(
          //     children: [
          //       _buildStatCard('${data.totalReferrals}', 'Friends Referred'),
          //       SizedBox(width: 16.w),
          //       _buildStatCard(
          //           '₹${data.totalEarned.toStringAsFixed(0)}', 'Total Earned'),
          //     ],
          //   ),
          // ],
        ],
      ),
    );
  }

  // ── Fixed bottom footer with Invite Friends button ──────────────────────
  Widget _buildFooter(BuildContext context, String code, String rewardAmount) {
    final effectiveCode = code.isNotEmpty ? code : 'AQWYSJ';
    final effectiveReward = rewardAmount;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _inviteViaWhatsApp(context, effectiveCode, effectiveReward),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.r)),
                elevation: 0,
              ),
              child: Text(
                'Invite Friends',
                style: GoogleFonts.lora(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow({required String value, required Widget trailing}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lora(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.lora(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.lora(
                fontSize: 12.sp,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
