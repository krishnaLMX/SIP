import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:startgold/shared/widgets/animations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routes/app_router.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/home_dashboard_provider.dart';
import '../../profile/profile_controller.dart';
import '../../main/main_screen.dart';

class PurchaseSuccessScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const PurchaseSuccessScreen({super.key, required this.data});

  @override
  ConsumerState<PurchaseSuccessScreen> createState() =>
      _PurchaseSuccessScreenState();
}

class _PurchaseSuccessScreenState extends ConsumerState<PurchaseSuccessScreen>
    {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    final bool isSuccess = widget.data['isSuccess'] ?? true;
    if (isSuccess) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();

    super.dispose();
  }

  // Helper: extract readable payment mode label
  String _formatPaymentMode(String? mode) {
    if (mode == null || mode.isEmpty) return 'Online';
    switch (mode.toUpperCase()) {
      case 'WALLET':
        return 'Wallet';
      case 'UPI':
        return 'UPI';
      case 'CARD':
        return 'Card';
      case 'NET_BANKING':
        return 'Net Banking';
      default:
        return mode[0].toUpperCase() + mode.substring(1).toLowerCase();
    }
  }

  // Helper: format amount
  String _formatAmount(dynamic amount) {
    if (amount == null) return '₹0.00';
    final num val = amount is num ? amount : num.tryParse('$amount') ?? 0;
    return '₹${val.toStringAsFixed(2)}';
  }

  // Helper: format rate
  String _formatRate(dynamic rate) {
    if (rate == null) return '₹0.00/gm';
    final num val = rate is num ? rate : num.tryParse('$rate') ?? 0;
    return '₹${val.toStringAsFixed(2)}/gm';
  }

  // Helper: format weight
  String _formatWeight(dynamic weight) {
    if (weight == null) return '0.0000 gm';
    final num val = weight is num ? weight : num.tryParse('$weight') ?? 0;
    return '${val.toStringAsFixed(4)} gm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSuccess = widget.data['isSuccess'] ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Confetti Animation
          if (isSuccess)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFF1B882C),
                  Color(0xFFFFB500),
                  Color(0xFF064E3B),
                  Color(0xFFFFCA49),
                  Color(0xFF0ED500),
                  Colors.white,
                ],
                numberOfParticles: 25,
                gravity: 0.08,
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),
                        // ── Success / Failure Icon ──
                        _buildStatusIcon(isSuccess),
                        SizedBox(height: 28.h),
                        // ── Title ──
                        FadeInAnimation(
                          child: Text(
                            isSuccess
                                ? 'Purchase Successful!'
                                : 'Payment Failed',
                            style: GoogleFonts.lora(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w900,
                              color: isSuccess
                                  ? const Color(0xFF064E3B)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // ── Subtitle message ──
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 200),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Text(
                              isSuccess
                                  ? (widget.data['message'] ??
                                      'Gold has been successfully added to your locker.')
                                  : (widget.data['message'] ??
                                      'Something went wrong. Please try again.'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                fontSize: 13.sp,
                                color: isSuccess
                                    ? const Color(0xFF064E3B).withOpacity(0.6)
                                    : const Color(0xFF991B1B).withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        // ── Order Details Card (success) / Failure Card ──
                        if (isSuccess)
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 400),
                            child: _buildOrderDetailsCard(isDark),
                          )
                        else
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 400),
                            child: _buildFailureCard(),
                          ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
                // ── Bottom Button ──
                _buildBottomButton(isSuccess, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isSuccess) {
    return ScaleAnimation(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated expanding ring
          if (isSuccess)
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Container(
                  width: 130.w * value,
                  height: 130.w * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0ED500)
                          .withOpacity((1 - value).clamp(0, 1)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          // Inner glowing circle
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSuccess
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B882C), Color(0xFF064E3B)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: isSuccess
                      ? const Color(0xFF1B882C).withOpacity(0.4)
                      : const Color(0xFFDC2626).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 52.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureCard() {
    final orderId = widget.data['orderId'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: const Color(0xFF991B1B).withOpacity(0.08),
        border: Border.all(
          color: const Color(0xFF991B1B).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            if (orderId != null && orderId.toString().isNotEmpty) ...[
              // Order ID row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ID',
                    style: GoogleFonts.lora(
                      fontSize: 12.sp,
                      color: const Color(0xFF7F1D1D).withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: orderId.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order ID copied!',
                            style: GoogleFonts.lora(fontSize: 12.sp),
                          ),
                          backgroundColor: const Color(0xFF991B1B),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          orderId.toString(),
                          style: GoogleFonts.lora(
                            fontSize: 12.sp,
                            color: const Color(0xFF7F1D1D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.copy_rounded,
                          color:
                              const Color(0xFF7F1D1D).withOpacity(0.5),
                          size: 14.sp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 20.h),
            // Hint text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFF7F1D1D).withOpacity(0.5),
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'No amount has been deducted',
                  style: GoogleFonts.lora(
                    fontSize: 11.sp,
                    color: const Color(0xFF7F1D1D).withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(bool isDark) {
    final orderId = widget.data['orderId'] ?? 'N/A';
    final commodityName = widget.data['commodity_name'] ?? 'Gold 24K';
    final totalAmount = widget.data['total_amount'];
    final rate = widget.data['rate'];
    final gramsCredited = widget.data['weight'];
    final paymentMode = widget.data['payment_mode'];

    // Determine if gold or silver for accent color
    final isGold = commodityName.toString().toLowerCase().contains('gold');
    final accentColor =
        isGold ? const Color(0xFFFFB500) : const Color(0xFFC0C0C0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D3B1E).withOpacity(0.7),
            const Color(0xFF0A2D16).withOpacity(0.5),
          ],
        ),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header: Amount + Commodity Badge ──
          Container(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.12),
                  accentColor.withOpacity(0.04),
                ],
              ),
            ),
            child: Column(
              children: [
                // Commodity badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGold
                            ? Icons.auto_awesome_rounded
                            : Icons.diamond_rounded,
                        color: accentColor,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        commodityName,
                        style: GoogleFonts.lora(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Amount
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.7)],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    _formatAmount(totalAmount),
                    style: GoogleFonts.lora(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Total Amount',
                  style: GoogleFonts.lora(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Detail rows (only show items with valid data) ──
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
            child: Builder(
              builder: (context) {
                // Build list of displayable detail entries
                final entries = <Map<String, dynamic>>[
                  if (_isDisplayable(orderId))
                    {'icon': Icons.receipt_long_rounded, 'label': 'Order ID', 'value': orderId, 'copy': true},
                  if (_isDisplayable(gramsCredited))
                    {'icon': Icons.scale_rounded, 'label': 'Weight Credited', 'value': _formatWeight(gramsCredited)},
                  if (_isDisplayable(rate))
                    {'icon': Icons.trending_up_rounded, 'label': 'Buy Rate', 'value': _formatRate(rate)},
                  if (_isDisplayable(paymentMode))
                    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Payment Mode', 'value': _formatPaymentMode(paymentMode)},
                ];

                return Column(
                  children: [
                    for (int i = 0; i < entries.length; i++) ...[
                      _buildDetailItem(
                        icon: entries[i]['icon'] as IconData,
                        label: entries[i]['label'] as String,
                        value: entries[i]['value'] as String,
                        accentColor: accentColor,
                        showCopy: entries[i]['copy'] == true,
                      ),
                      if (i < entries.length - 1) _buildDivider(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Check if a value is displayable (not null, empty, or placeholder)
  bool _isDisplayable(dynamic val) {
    if (val == null) return false;
    final s = val.toString().trim();
    return s.isNotEmpty && s != 'N/A' && s != 'null';
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    bool showCopy = false,
  }) {
    // Hide row when server returns empty / placeholder data
    if (!_isDisplayable(value)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: accentColor.withOpacity(0.8),
              size: 18.sp,
            ),
          ),
          SizedBox(width: 14.w),
          // Label
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lora(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Value
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.lora(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showCopy) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order ID copied!',
                            style: GoogleFonts.lora(fontSize: 12.sp),
                          ),
                          backgroundColor: const Color(0xFF1B882C),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy_rounded,
                      color: Colors.white.withOpacity(0.4),
                      size: 16.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: EdgeInsets.only(left: 50.w),
      color: Colors.white.withOpacity(0.06),
    );
  }

  Widget _buildBottomButton(bool isSuccess, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100.r),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1B882C), Color(0xFF003716)],
              ),
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0E5723).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(100.r),
              onTap: () {
                if (isSuccess) {
                  final container = ProviderScope.containerOf(context);
                  Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name == AppRouter.main ||
                        route.settings.name == AppRouter.home ||
                        route.isFirst,
                  );
                  Future.delayed(const Duration(milliseconds: 350), () {
                    container.read(selectedTabProvider.notifier).state = 0;
                  });
                  Future.delayed(const Duration(milliseconds: 650), () {
                    container
                        .read(portfolioProvider.notifier)
                        .fetchPortfolio();
                    container.invalidate(homeDashboardProvider);
                    container.invalidate(profileProvider);
                  });
                } else {
                  final container = ProviderScope.containerOf(context);
                  Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name == AppRouter.main ||
                        route.settings.name == AppRouter.home ||
                        route.isFirst,
                  );
                  Future.delayed(const Duration(milliseconds: 350), () {
                    container.read(selectedTabProvider.notifier).state = 1;
                  });
                }
              },
              child: Center(
                child: Text(
                  isSuccess ? 'BACK TO HOME' : 'TRY AGAIN',
                  style: GoogleFonts.lora(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
