import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/commodity_provider.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/market_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/withdrawal_provider.dart';
import '../models/withdrawal_method.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../market/models/market_rates.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCommodity = ref.watch(commodityProvider);
    final portfolio = ref.watch(portfolioProvider);
    final user = ref.watch(userProvider);
    final market = ref.watch(marketRatesStreamProvider);
    final withdrawalState = ref.watch(withdrawalProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(AppConstants.withdrawTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(isDark, portfolio, selectedCommodity, market),
            SizedBox(height: 32.h),
            _buildAmountInput(
                isDark, withdrawalState, market, selectedCommodity),
            SizedBox(height: 32.h),
            if (user?.isKycVerified ?? false) ...[
              _buildUPISelection(isDark, withdrawalState),
              SizedBox(height: 32.h),
            ] else
              _buildKycBlockingUI(isDark),
          ],
        ),
      ),
      bottomNavigationBar: (user?.isKycVerified ?? false)
          ? Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
              child: _buildActionButtons(
                  user, portfolio, market, selectedCommodity, withdrawalState),
            )
          : null,
    );
  }

  Widget _buildBalanceCard(bool isDark, AsyncValue<PortfolioData> portfolio,
      CommodityType type, AsyncValue<MarketRates> market) {
    return portfolio.when(
      data: (data) {
        final balance = data.summary.balance;

        return market.when(
          data: (rates) {
            final sellRate =
                type == CommodityType.gold ? rates.goldSell : rates.silverSell;
            final inrValue = balance * sellRate;
            final isGold = type == CommodityType.gold;

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isGold
                      ? [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF16213E),
                          const Color(0xFF0F3460),
                        ]
                      : [
                          const Color(0xFF0F2027),
                          const Color(0xFF203A43),
                          const Color(0xFF2C5364),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isGold
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6))
                        .withOpacity(0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: Stack(
                  children: [
                    // Decorative glow blob
                    Positioned(
                      top: -60,
                      right: -60,
                      child: Container(
                        width: 200.r,
                        height: 200.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isGold
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF3B82F6))
                                  .withOpacity(0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Row 1: Label + Purity Badge ──────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(7.r),
                                    decoration: BoxDecoration(
                                      color: (isGold
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFF3B82F6))
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isGold
                                          ? Icons.workspace_premium_rounded
                                          : Icons.layers_rounded,
                                      color: isGold
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF60A5FA),
                                      size: 16.sp,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'AVAILABLE ${isGold ? rates.goldName : rates.silverName}'
                                        .toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white60,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              // Purity badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: (isGold
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF3B82F6))
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: (isGold
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF3B82F6))
                                        .withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  isGold ? '24K · 999.9' : '999 Fine',
                                  style: GoogleFonts.outfit(
                                    color: isGold
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF60A5FA),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          // ── Row 2: Main balance ──────────────────────────
                          Text(
                            '${balance.toStringAsFixed(4)} g',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Text(
                                '≈ ₹${inrValue.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Est. value',
                                style: GoogleFonts.outfit(
                                  color: Colors.white30,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20.h),

                          // Stats Strip (Restored)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SELL RATE',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white38,
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1)),
                                    Text('₹${sellRate.toStringAsFixed(2)}',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                Container(
                                    width: 1,
                                    height: 24.h,
                                    color: Colors.white10),
                                _buildFluctuationBadge(
                                    isGold ? rates.goldChange : rates.silverChange,
                                    isGold
                                        ? rates.goldPercentage
                                        : rates.silverPercentage,
                                    true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => _buildPortfolioLoading(isDark),
          error: (_, __) => const SizedBox(),
        );
      },
      loading: () => _buildPortfolioLoading(isDark),
      error: (_, __) => _buildPortfolioError(isDark),
    );
  }

  Widget _buildPortfolioLoading(bool isDark) {
    return Container(
      height: 180.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPortfolioError(bool isDark) {
    return Container(
      height: 180.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
      ),
      child: Center(
        child: Text(
          'Failed to load portfolio',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(bool isDark, WithdrawalState state,
      AsyncValue<dynamic> market, CommodityType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppConstants.enterAmount,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 16.sp)),
            TextButton(
              onPressed: () =>
                  ref.read(withdrawalProvider.notifier).toggleInputType(),
              child: Text(state.isGrams ? 'Switch to INR' : 'Switch to Grams',
                  style: GoogleFonts.outfit(
                      color: AppTheme.electricCyan,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) => ref
              .read(withdrawalProvider.notifier)
              .updateAmount(double.tryParse(val) ?? 0),
          style:
              GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: '0.00',
            suffixText: state.isGrams ? 'grams' : 'INR',
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none),
            contentPadding: EdgeInsets.all(20.w),
          ),
        ),
        if (state.amount > 0) ...[
          SizedBox(height: 12.h),
          market.when(
            data: (rates) {
              final price = type == CommodityType.gold
                  ? rates.goldSell
                  : rates.silverSell;
              final converted =
                  state.isGrams ? state.amount * price : state.amount / price;
              return Text(
                state.isGrams
                    ? '≈ ₹${converted.toStringAsFixed(2)}'
                    : '≈ ${converted.toStringAsFixed(4)} grams',
                style: GoogleFonts.outfit(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w600),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ],
    );
  }

  Widget _buildUPISelection(bool isDark, WithdrawalState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppConstants.selectBank,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 16.sp)),
        SizedBox(height: 16.h),
        ...state.savedMethods.map((method) => _buildUPICard(
            isDark, method, state.selectedMethod?.id == method.id)),
        SizedBox(height: 16.h),
        InkWell(
          onTap: _showAddUpiSheet,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppTheme.arcticBlue.withOpacity(0.3), width: 1.5),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.arcticBlue),
                SizedBox(width: 8.w),
                Text(AppConstants.addUPI,
                    style: GoogleFonts.outfit(
                        color: AppTheme.arcticBlue,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUPICard(bool isDark, WithdrawalMethod method, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(withdrawalProvider.notifier).selectMethod(method),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: isSelected ? AppTheme.arcticBlue : Colors.transparent,
              width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: AppTheme.arcticBlue.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.account_balance_rounded,
                  color: AppTheme.arcticBlue, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.upiId,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                Text(method.bankName,
                    style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppTheme.arcticBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      UserProfile? user,
      AsyncValue<PortfolioData> portfolio,
      AsyncValue<dynamic> market,
      CommodityType type,
      WithdrawalState state) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: (state.amount > 0 && state.selectedMethod != null)
            ? () => _handleWithdraw(portfolio, market, type)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.arcticBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 0,
        ),
        child: Text(AppConstants.withdrawNow,
            style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
  }

  Widget _buildKycBlockingUI(bool isDark) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.lock_person_rounded,
                color: Colors.redAccent, size: 32.sp),
          ),
          SizedBox(height: 24.h),
          Text(
            AppConstants.kycRequired,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 20.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12.h),
          Text(
            AppConstants.kycRequiredDesc,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          CustomButton(
            text: 'START VERIFICATION',
            onPressed: () => Navigator.pushNamed(context, AppRouter.kyc),
            backgroundColor: AppTheme.arcticBlue,
          ),
        ],
      ),
    );
  }

  void _showAddUpiSheet() {
    final TextEditingController upiController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
            24.w, 24.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add UPI ID',
                style: GoogleFonts.outfit(
                    fontSize: 24.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text('A verification code will be sent to your mobile.',
                style: GoogleFonts.outfit(
                    color: isDark ? Colors.white54 : Colors.black54)),
            SizedBox(height: 32.h),
            TextField(
              controller: upiController,
              autofocus: true,
              style: GoogleFonts.outfit(
                  fontSize: 18.sp, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'user@upi',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none),
                contentPadding: EdgeInsets.all(20.w),
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () {
                  if (upiController.text.contains('@')) {
                    final user = ref.read(userProvider);
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.otp, arguments: {
                      'mobile': user?.mobile ?? '',
                      'otpSessionId': 'mock_session',
                      'actionType': 'add_upi',
                      'upiHandle': upiController.text,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.arcticBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                ),
                child: const Text('GET OTP',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleWithdraw(AsyncValue<PortfolioData> portfolio,
      AsyncValue<dynamic> market, CommodityType type) {
    if (ref.read(withdrawalProvider).selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a bank account/UPI'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final rates = market.value;
    final portfolioData = portfolio.value;
    if (rates == null || portfolioData == null) return;

    final balanceGrams = portfolioData.summary.balance;
    final sellPrice =
        type == CommodityType.gold ? rates.goldSell : rates.silverSell;

    final error =
        ref.read(withdrawalProvider.notifier).validate(balanceGrams, sellPrice);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
      return;
    }

    Navigator.pushNamed(context, AppRouter.withdrawalConfirmation);
  }

  Widget _buildFluctuationBadge(double change, double percentage, bool isDark) {
    if (change == 0) return const SizedBox.shrink();

    final isUp = change > 0;
    final color = isUp ? Colors.greenAccent : Colors.redAccent;
    final icon =
        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14.sp),
        SizedBox(width: 4.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isUp ? "+" : ""}${change.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(2)}%',
              style: GoogleFonts.outfit(
                color: color.withOpacity(0.7),
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
