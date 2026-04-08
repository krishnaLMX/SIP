import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/commodity_provider.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/market_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../instant_saving/controller/saving_controller.dart';
import '../../instant_saving/models/saving_models.dart';
import '../providers/withdrawal_provider.dart';
import '../services/withdrawal_service.dart';
import '../../../routes/app_router.dart';
import '../../market/models/market_rates.dart';
import '../../../shared/widgets/loaders.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/utils/no_leading_zeros_formatter.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset amount so stale state from previous withdrawal doesn't persist
    Future.microtask(() {
      ref.read(withdrawalProvider.notifier).updateAmount(0);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCommodity = ref.watch(commodityProvider);
    final portfolio = ref.watch(portfolioProvider);
    final withdrawalState = ref.watch(withdrawalProvider);
    final timerState = ref.watch(buyRateTimerProvider);

    // Watch config to trigger the API fetch
    final configAsync = ref.watch(savingConfigProvider);

    // Sync timer with config
    ref.listen<AsyncValue<SavingConfig>>(savingConfigProvider, (prev, next) {
      if (next.hasValue &&
          next.value != null &&
          !ref.read(buyRateTimerProvider).isActive) {
        ref
            .read(buyRateTimerProvider.notifier)
            .startOrRefresh(next.value!.buyRateLockSeconds);
      }
    });

    // Also start timer immediately if config is already loaded
    if (configAsync.hasValue &&
        configAsync.value != null &&
        !timerState.isActive) {
      Future.microtask(() {
        ref
            .read(buyRateTimerProvider.notifier)
            .startOrRefresh(configAsync.value!.buyRateLockSeconds);
      });
    }

    // Reset amount when commodity switches
    ref.listen(commodityProvider, (prev, next) {
      if (prev != next) {
        _amountController.clear();
        ref.read(withdrawalProvider.notifier).updateAmount(0);
      }
    });

    final market = timerState.isActive
        ? AsyncData(timerState.lockedRates!)
        : ref.watch(marketRatesStreamProvider);

    if (portfolio.isLoading && !portfolio.hasValue) {
      return AppLoaders.fullScreenLoader(context);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Gradient Header ────────────────────────────────────────────
          GradientHeader(
            title: 'Withdraw Funds',
            onBack: () => Navigator.pop(context),
          ),
          // ── Scrollable Body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 24.h),
                  _buildLiveRateSection(selectedCommodity, market, timerState),
                  SizedBox(height: 24.h),
                  _buildCommodityTabs(selectedCommodity),
                  SizedBox(height: 24.h),
                  _buildMainInputCard(
                      portfolio, selectedCommodity, market, withdrawalState),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _buildFooter(withdrawalState, portfolio, market, selectedCommodity),
    );
  }

  Widget _buildLiveRateSection(CommodityType type,
      AsyncValue<MarketRates> market, TimerState timerState) {
    return market.when(
      data: (rates) {
        final price =
            type == CommodityType.gold ? rates.goldBuy : rates.silverBuy;

        final minutes = timerState.remainingSeconds ~/ 60;
        final seconds = timerState.remainingSeconds % 60;
        final timeStr =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Live Buying Price',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                              color: const Color(0xFF064E3B).withOpacity(0.1)),
                        ),
                        child: Text(
                          type == CommodityType.gold
                              ? '24K Gold'
                              : 'Pure Silver',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF064E3B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (timerState.isActive)
                    Text(
                      'Valid for : $timeStr',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '₹ ${price.toStringAsFixed(2)}/gm',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildCommodityTabs(CommodityType current) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabItem('Gold', current == CommodityType.gold, () {
                if (current != CommodityType.gold) {
                  _amountController.clear();
                  ref.read(withdrawalProvider.notifier).updateAmount(0);
                  ref
                      .read(commodityProvider.notifier)
                      .setCommodity(CommodityType.gold);
                }
              }),
            ),
            Expanded(
              child:
                  _buildTabItem('Silver', current == CommodityType.silver, () {
                if (current != CommodityType.silver) {
                  _amountController.clear();
                  ref.read(withdrawalProvider.notifier).updateAmount(0);
                  ref
                      .read(commodityProvider.notifier)
                      .setCommodity(CommodityType.silver);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment(-0.87, -0.5),
                  end: Alignment(0.87, 0.5),
                  colors: [Color(0xFF1B882C), Color(0xFF003716)],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B882C).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF064E3B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInputCard(
      AsyncValue<PortfolioData> portfolio,
      CommodityType type,
      AsyncValue<MarketRates> market,
      WithdrawalState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Holding',
                style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            portfolio.when(
              data: (data) {
                final balance = data.summary.balance;
                final rate = type == CommodityType.gold
                    ? market.valueOrNull?.goldBuy ?? 0
                    : market.valueOrNull?.silverBuy ?? 0;
                final inrValue = balance * rate;
                return Row(
                  children: [
                    Text('${balance.toStringAsFixed(4)} gm',
                        style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Container(
                          width: 1.5, height: 20.h, color: Colors.black12),
                    ),
                    Text('₹ ${inrValue.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading holding'),
            ),
            SizedBox(height: 24.h),
            Divider(color: Colors.black.withOpacity(0.05)),
            SizedBox(height: 24.h),
            Text('Enter your amount',
                style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Text('₹',
                      style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        const NoLeadingZerosFormatter(allowDecimal: false),
                      ],
                      onChanged: (val) {
                        final doubleValue =
                            val.isEmpty ? 0.0 : double.tryParse(val) ?? 0.0;
                        ref
                            .read(withdrawalProvider.notifier)
                            .updateAmount(doubleValue);
                      },
                      style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                      decoration: const InputDecoration(
                          border: InputBorder.none, hintText: '0'),
                    ),
                  ),
                  if (state.amount > 0)
                    market.when(
                      data: (rates) {
                        final price = type == CommodityType.gold
                            ? rates.goldBuy
                            : rates.silverBuy;
                        final grams = state.amount / price;
                        return Text('${grams.toStringAsFixed(4)}gm',
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.black45,
                                fontWeight: FontWeight.w600));
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
      WithdrawalState withdrawalState,
      AsyncValue<PortfolioData> portfolio,
      AsyncValue<MarketRates> market,
      CommodityType type) {
    final isEnabled =
        withdrawalState.amount > 0 && !withdrawalState.isProcessing;
    return SafeArea(
      top: false,
      child: Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.black38, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Only one buy order per metal is allowed per calendar day for security reasons.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black54,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Gradient button
          CustomButton(
            text: 'Withdrawal',
            isLoading: withdrawalState.isProcessing,
            loadingText: 'Processing...',
            onPressed: isEnabled
                ? () => _handleWithdraw(portfolio, market, type)
                : null,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isEnabled
                  ? const [Color(0xFF1B882C), Color(0xFF003716)]
                  : [
                      const Color(0xFF1B882C).withOpacity(0.45),
                      const Color(0xFF003716).withOpacity(0.45),
                    ],
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF1B882C).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
            textColor: Colors.white,
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _handleWithdraw(AsyncValue<PortfolioData> portfolio,
      AsyncValue<MarketRates> market, CommodityType type) async {
    final rates = market.valueOrNull;
    final portfolioData = portfolio.valueOrNull;
    if (rates == null || portfolioData == null) return;

    final balanceGrams = portfolioData.summary.balance;
    final buyBackPrice =
        type == CommodityType.gold ? rates.goldBuy : rates.silverBuy;

    final notifier = ref.read(withdrawalProvider.notifier);
    final error = notifier.validate(balanceGrams, buyBackPrice);

    if (error != null) {
      AppToast.show(context, error, type: ToastType.error);
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) return;

    notifier.setProcessing(true);

    try {
      final nextStep =
          await ref.read(withdrawalServiceProvider).checkEligibility(
                customerId: user.id,
                mobile: user.mobile,
                amount: ref.read(withdrawalProvider).amount,
                metalId: ref.read(selectedMetalIdProvider), // dynamic from API
              );

      if (!mounted) return;
      notifier.setProcessing(false);

      if (nextStep == 'KYC_REQUIRED') {
        Navigator.pushNamed(context, AppRouter.dynamicKyc,
            arguments: {'request_from': 'withdraw'});
      } else if (nextStep == 'UPI_LIST' || nextStep == null) {
        Navigator.pushNamed(context, AppRouter.upiSelection);
      } else {
        Navigator.pushNamed(context, AppRouter.upiSelection);
      }
    } catch (e) {
      if (mounted) {
        notifier.setProcessing(false);
        AppToast.show(context, 'Something went wrong. Please try again.',
            type: ToastType.error);
      }
    }
  }
}
