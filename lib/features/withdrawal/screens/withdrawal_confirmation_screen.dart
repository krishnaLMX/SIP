import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/commodity_provider.dart';
import '../../../core/providers/market_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/withdrawal_provider.dart';
import '../models/withdrawal_method.dart';
import '../../../routes/app_router.dart';

class WithdrawalConfirmationScreen extends ConsumerStatefulWidget {
  const WithdrawalConfirmationScreen({super.key});

  @override
  ConsumerState<WithdrawalConfirmationScreen> createState() =>
      _WithdrawalConfirmationScreenState();
}

class _WithdrawalConfirmationScreenState
    extends ConsumerState<WithdrawalConfirmationScreen> {
  int _timeLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _showExpiryDialog();
      }
    });
  }

  void _showExpiryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Rate Expired',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: const Text(
            'The market rate has expired. Please try again to get the latest rate.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('BACK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final withdrawal = ref.watch(withdrawalProvider);
    final market = ref.watch(marketRatesStreamProvider);
    final type = ref.watch(commodityProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(AppConstants.confirmWithdrawal,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: market.when(
        data: (rates) {
          final price =
              type == CommodityType.gold ? rates.goldSell : rates.silverSell;
          final amountInINR = withdrawal.isGrams
              ? withdrawal.amount * price
              : withdrawal.amount;
          final amountInGrams = withdrawal.isGrams
              ? withdrawal.amount
              : withdrawal.amount / price;

          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                _buildTimerSection(),
                SizedBox(height: 32.h),
                _buildSummaryCard(
                    isDark, amountInINR, amountInGrams, price, type),
                SizedBox(height: 32.h),
                _buildDestinationCard(isDark, withdrawal.selectedMethod),
                const Spacer(),
                _buildFinalAction(context),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error loading market rates')),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: Colors.amber[700], size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            '${AppConstants.rateLocked}: $_timeLeft ${AppConstants.seconds}',
            style: GoogleFonts.outfit(
                color: Colors.amber[900], fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, double amountINR, double amountGrams,
      double rate, CommodityType type) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Text('You will receive',
              style: GoogleFonts.outfit(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Text('₹${amountINR.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.arcticBlue)),
          SizedBox(height: 24.h),
          const Divider(),
          SizedBox(height: 24.h),
          _buildSummaryRow(
              'Selling weight', '${amountGrams.toStringAsFixed(4)} g', isDark),
          SizedBox(height: 16.h),
          _buildSummaryRow(
              'Selling rate', '₹${rate.toStringAsFixed(2)} / g', isDark),
          SizedBox(height: 16.h),
          _buildSummaryRow('Commodity',
              type == CommodityType.gold ? 'Gold 24KT' : 'Silver 999', isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: isDark ? Colors.white54 : Colors.black54)),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildDestinationCard(bool isDark, WithdrawalMethod? method) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: isDark ? Colors.white70 : Colors.black54),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CREDIT TO',
                    style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : Colors.black38)),
                Text(method?.upiId ?? 'N/A',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalAction(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.security, color: Colors.greenAccent[400], size: 16.sp),
            SizedBox(width: 8.w),
            Text('Secure Bank Transfer',
                style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: Colors.greenAccent[700],
                    fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          height: 60.h,
          child: ElevatedButton(
            onPressed: () => _confirmMPIN(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.arcticBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
            ),
            child: Text('Confirm Sale & Transfer',
                style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _confirmMPIN(BuildContext context) {
    // Navigate to MPIN screen for final authorization
    Navigator.pushNamed(context, AppRouter.mpin,
        arguments: {'type': 'authorize_withdrawal'});
  }
}
