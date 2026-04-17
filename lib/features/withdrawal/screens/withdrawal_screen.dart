import 'dart:ui';
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
    Future.microtask(() {
      if (!mounted) return;
      // Reset amount so stale state from previous withdrawal doesn't persist
      ref.read(withdrawalProvider.notifier).updateAmount(0);

      // Always lock the freshest live buy rate on screen entry.
      // Clears any stale lock (even if timer still running) and restarts
      // with the current socket rate. Only when market is open.
      final entryType = ref.read(commodityProvider);
      final entryCommodityId = entryType == CommodityType.gold ? '1' : '3';
      final entryStatusMap =
          ref.read(marketStatusProvider).valueOrNull ?? const {};
      if (entryStatusMap[entryCommodityId] != false) {
        ref.read(buyRateTimerProvider.notifier).clear();
        final config = ref.read(savingConfigProvider).valueOrNull;
        if (config != null) {
          ref
              .read(buyRateTimerProvider.notifier)
              .startOrRefresh(config.buyRateLockSeconds);
        } else {
          ref.invalidate(savingConfigProvider);
        }
      }
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
    final rewardAsync = ref.watch(rewardBalanceProvider);

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

    // Reset amount + timer when commodity switches
    ref.listen(commodityProvider, (prev, next) {
      if (prev != next) {
        _amountController.clear();
        ref.read(withdrawalProvider.notifier).updateAmount(0);

        // Reset timer so the new commodity's market is evaluated fresh.
        // Without this, Gold's isMarketClosed=true persists on the shared
        // timer and Silver shows no countdown even though it is open.
        ref.read(buyRateTimerProvider.notifier).clear();
        final config = ref.read(savingConfigProvider).valueOrNull;
        if (config != null) {
          ref
              .read(buyRateTimerProvider.notifier)
              .startOrRefresh(config.buyRateLockSeconds);
        }
      }
    });

    // ── Per-commodity market status (from socket) ──────────────────────
    // '1' = Gold 24K, '3' = Silver. Absent from map = assume open.
    final marketStatusMap =
        ref.watch(marketStatusProvider).valueOrNull ?? const {};
    final commodityId = selectedCommodity == CommodityType.gold ? '1' : '3';
    final isCurrentMarketClosed = marketStatusMap[commodityId] == false;

    // When market transitions closed → open: restart timer immediately.
    ref.listen<AsyncValue<Map<String, bool>>>(marketStatusProvider,
        (prev, next) {
      next.whenData((statusMap) {
        final currId =
            selectedCommodity == CommodityType.gold ? '1' : '3';
        final wasOpen = prev?.valueOrNull?[currId] != false;
        final isNowOpen = statusMap[currId] != false;
        if (!wasOpen && isNowOpen && mounted) {
          ref.read(buyRateTimerProvider.notifier).clear();
          final config = ref.read(savingConfigProvider).valueOrNull;
          if (config != null) {
            ref
                .read(buyRateTimerProvider.notifier)
                .startOrRefresh(config.buyRateLockSeconds);
          }
        }
      });
    });

    // ── Race-condition guard: market-reopen vs first rate frame ─────────
    // `5|...|1` fires before `3|...` rate arrives — buyRateTimer may lock 0.
    // Restart as soon as the first valid buy rate is received from the socket.
    ref.listen<AsyncValue<MarketRates>>(marketRatesStreamProvider, (prev, next) {
      next.whenData((rates) {
        if (!mounted) return;
        final currId =
            selectedCommodity == CommodityType.gold ? '1' : '3';
        final isMarketOpen =
            (ref.read(marketStatusProvider).valueOrNull ?? {})[currId] != false;
        if (!isMarketOpen) return;
        final liveRate = selectedCommodity == CommodityType.gold
            ? rates.goldBuy
            : rates.silverBuy;
        if (liveRate <= 0) return;
        final tState = ref.read(buyRateTimerProvider);
        final lockedRate = selectedCommodity == CommodityType.gold
            ? (tState.lockedRates?.goldBuy ?? 0.0)
            : (tState.lockedRates?.silverBuy ?? 0.0);
        if (tState.isActive && lockedRate <= 0) {
          final config = ref.read(savingConfigProvider).valueOrNull;
          if (config != null) {
            ref
                .read(buyRateTimerProvider.notifier)
                .startOrRefresh(config.buyRateLockSeconds);
          }
        }
      });
    });

    // When market is closed, bypass the stale locked rate and use the live
    // socket rate (already zeroed for that commodity on closure).
    final market = (!isCurrentMarketClosed && timerState.isActive)
        ? AsyncData(timerState.lockedRates!)
        : ref.watch(marketRatesStreamProvider);

    if (portfolio.isLoading && !portfolio.hasValue) {
      return AppLoaders.fullScreenLoader(context);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Gradient Header ─────────────────────────────────────────
          GradientHeader(
            title: 'Withdraw Funds',
            onBack: () => Navigator.pop(context),
          ),

          // ── Market Closed Amber Banner ──────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isCurrentMarketClosed
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 10.h),
                    color: const Color(0xFFFEF3C7),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: const Color(0xFFB45309), size: 16.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '${selectedCommodity == CommodityType.gold ? 'Gold' : 'Silver'} market is closed. Rates resume when market opens.',
                            style: GoogleFonts.lora(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Scrollable Body ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 24.h),
                  _buildLiveRateSection(
                      selectedCommodity, market, timerState,
                      isCurrentMarketClosed),
                  SizedBox(height: 24.h),
                  _buildCommodityTabs(selectedCommodity),
                  SizedBox(height: 24.h),
                  _buildMainInputCard(
                      selectedCommodity, market, withdrawalState, rewardAsync),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          // ── Pinned Footer ─────────────────────────────────────────
          _buildFooter(
              withdrawalState, market, selectedCommodity,
              isCurrentMarketClosed),
        ],
      ),
    );
  }

  Widget _buildLiveRateSection(CommodityType type,
      AsyncValue<MarketRates> market, TimerState timerState,
      bool isCurrentMarketClosed) {
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
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Live Withdrawal Price',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                  ),
                  SizedBox(width: 8.w),
                  // Right: timer countdown OR market-closed badge
                  // Use ONLY isCurrentMarketClosed (per-commodity from socket).
                  if (isCurrentMarketClosed)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: const Color(0xFFD97706).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_mall_directory_outlined,
                              size: 12.sp, color: const Color(0xFFD97706)),
                          SizedBox(width: 4.w),
                          Text(
                            'Market Closed',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (timerState.isActive)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: const Color(0xFF064E3B).withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 12.sp, color: const Color(0xFF064E3B)),
                          SizedBox(width: 4.w),
                          SizedBox(
                            width: 38.w,
                            child: Text(
                              timeStr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF064E3B),
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '₹${price.toStringAsFixed(2)}/gm',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (err, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Text(
          err.toString().replaceAll('Exception: ', ''),
          style: TextStyle(fontSize: 14.sp, color: Colors.redAccent),
        ),
      ),
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
    final isGold = label == 'Gold';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: const Alignment(-0.87, -0.5),
                  end: const Alignment(0.87, 0.5),
                  colors: isGold
                      ? const [
                          Color(0xFFEF9B00),
                          Color(0xFFF5AC03),
                          Color(0xFFF9D522),
                          Color(0xFFF8C30D),
                          Color(0xFFF5A702),
                          Color(0xFFE78400),
                        ]
                      : const [
                          Color(0xFFABABAB),
                          Color(0xFFC2C3C5),
                          Color(0xFFDFDFDF),
                          Color(0xFFEEEEEE),
                          Color(0xFFDEDDDD),
                          Color(0xFFBDBDBD),
                          Color(0xFFAFB1AE),
                        ],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: isGold
                        ? const Color(0xFFEF9B00).withOpacity(0.35)
                        : const Color(0xFFBDBDBD).withOpacity(0.35),
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
              color: isActive
                  ? (isGold ? const Color(0xFF5C3300) : const Color(0xFF3D3D3D))
                  : const Color(0xFF064E3B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInputCard(CommodityType type, AsyncValue<MarketRates> market,
      WithdrawalState state, AsyncValue<Map<String, dynamic>> rewardAsync) {
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
            // ── Withdrawable Balance label + info icon ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Withdrawable Balance',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600)),
                rewardAsync.maybeWhen(
                  data: (reward) => GestureDetector(
                    onTap: () => _showHoldingInfoSheet(context, reward, type),
                    child: Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 15.sp,
                        color: const Color(0xFF064E3B),
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // ── Withdrawable balance from reward-balance API ──
            rewardAsync.when(
              data: (reward) {
                final withdrawable = double.tryParse(
                        reward['withdrawable_qty']?.toString() ?? '0') ??
                    0.0;
                final rate = type == CommodityType.gold
                    ? market.valueOrNull?.goldBuy ?? 0
                    : market.valueOrNull?.silverBuy ?? 0;
                final inrValue = withdrawable * rate;
                return Row(
                  children: [
                    Text('${withdrawable.toStringAsFixed(4)} gm',
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
              error: (_, __) => Text('Error loading holding',
                  style: TextStyle(fontSize: 13.sp, color: Colors.black45)),
            ),
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
                        // Guard against division by zero when market is closed
                        final grams =
                            price > 0 ? state.amount / price : 0.0;
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

  Widget _buildFooter(WithdrawalState withdrawalState,
      AsyncValue<MarketRates> market, CommodityType type,
      bool isCurrentMarketClosed) {
    // Disable button when market is closed OR no amount entered
    final isEnabled = withdrawalState.amount > 0 &&
        !withdrawalState.isProcessing &&
        !isCurrentMarketClosed;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info note — amber highlight style (same as payment methods screen)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 16.sp, color: const Color(0xFFD97706)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Only one withdrawal request per metal is allowed per calendar day for security purposes.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF92400E),
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
              onPressed: isEnabled ? () => _handleWithdraw(market, type) : null,
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

  void _showHoldingInfoSheet(
      BuildContext context, Map<String, dynamic> reward, CommodityType type) {
    final withdrawable =
        double.tryParse(reward['withdrawable_qty']?.toString() ?? '0') ?? 0.0;
    final totalQty =
        double.tryParse(reward['total_qty']?.toString() ?? '0') ?? 0.0;
    final onHold =
        double.tryParse(reward['on_hold_qty']?.toString() ?? '0') ?? 0.0;
    final commodityName = reward['commodity_name']?.toString() ??
        (type == CommodityType.gold ? 'Gold 24K' : 'Silver 999');
    final isGold = type == CommodityType.gold;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100.r),
              ),
            ),

            // ── Gradient header ──
            Container(
              margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.87, -0.5),
                  end: const Alignment(0.87, 0.5),
                  colors: isGold
                      ? const [Color(0xFFEF9B00), Color(0xFFF9D522)]
                      : const [Color(0xFF9E9E9E), Color(0xFFE0E0E0)],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGold ? Icons.diamond_outlined : Icons.auto_awesome,
                      color: isGold
                          ? const Color(0xFF5C3300)
                          : const Color(0xFF3D3D3D),
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commodityName,
                        style: GoogleFonts.lora(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isGold
                              ? const Color(0xFF3D2000)
                              : const Color(0xFF2A2A2A),
                        ),
                      ),
                      Text(
                        'Holdings Breakdown',
                        style: GoogleFonts.lora(
                          fontSize: 12.sp,
                          color: isGold
                              ? const Color(0xFF5C3300).withOpacity(0.7)
                              : const Color(0xFF3D3D3D).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Rows ──
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _holdingRow(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF1B882C),
                      bgColor: const Color(0xFF1B882C).withOpacity(0.08),
                      label: 'Withdrawable',
                      value: '${withdrawable.toStringAsFixed(4)} gm',
                      valueColor: const Color(0xFF1B882C),
                    ),
                    Divider(height: 1, color: Colors.black.withOpacity(0.05)),
                    _holdingRow(
                      icon: Icons.lock_clock_outlined,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFD97706).withOpacity(0.08),
                      label: 'On Hold',
                      value: '${onHold.toStringAsFixed(4)} gm',
                      valueColor: const Color(0xFFD97706),
                    ),
                    Divider(height: 1, color: Colors.black.withOpacity(0.05)),
                    _holdingRow(
                      icon: Icons.layers_rounded,
                      iconColor: const Color(0xFF5C3300),
                      bgColor: const Color(0xFFEF9B00).withOpacity(0.10),
                      label: 'Total Holding',
                      value: '${totalQty.toStringAsFixed(4)} gm',
                      valueColor: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),

            // ── Note ──
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 0),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 12.sp, color: Colors.black38),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'On-hold qty reflects pending orders or locks',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 28.h + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _holdingRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: iconColor),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lora(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWithdraw(
      AsyncValue<MarketRates> market, CommodityType type) async {
    final rates = market.valueOrNull;
    if (rates == null) return;

    // Use withdrawable_qty from referrals/reward-balance API for validation
    final rewardData = ref.read(rewardBalanceProvider).valueOrNull ?? {};
    final balanceGrams =
        double.tryParse(rewardData['withdrawable_qty']?.toString() ?? '0') ??
            0.0;

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
