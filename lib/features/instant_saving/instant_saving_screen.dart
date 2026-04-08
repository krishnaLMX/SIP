import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:startgold/core/providers/market_provider.dart';
import 'package:startgold/core/providers/commodity_provider.dart';
import 'package:startgold/core/services/shared_service.dart';
import 'package:startgold/core/providers/user_provider.dart';
import 'package:startgold/core/localization/language_provider.dart';
import 'controller/saving_controller.dart';
import 'models/saving_models.dart';
import '../../routes/app_router.dart';
import 'package:startgold/core/providers/timer_provider.dart';
import '../market/models/market_rates.dart';
import '../main/main_screen.dart';

import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/gradient_header.dart';
import '../../core/security/secure_logger.dart';
import '../../shared/utils/no_leading_zeros_formatter.dart';

class InstantSavingScreen extends ConsumerStatefulWidget {
  const InstantSavingScreen({super.key});

  @override
  ConsumerState<InstantSavingScreen> createState() =>
      _InstantSavingScreenState();
}

class _InstantSavingScreenState extends ConsumerState<InstantSavingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  late AnimationController _pulseController;
  String _selectedAmount = '';
  bool _isAmountMode = true;
  bool _isBreakdownExpanded = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['initialAmount'] != null) {
        final amount = args['initialAmount'].toString();
        setState(() {
          _selectedAmount = amount;
          _amountController.text = amount;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = ref.watch(commodityProvider);
    final configAsync = ref.watch(savingConfigProvider);
    final amountDenoms = ref.watch(amountDenominationsProvider);
    final weightDenoms = ref.watch(weightDenominationsProvider);
    final timerState = ref.watch(sellRateTimerProvider);

    // FIX: Force API refresh when navigating back to this tab from footer
    ref.listen<int>(selectedTabProvider, (previous, next) {
      if (next == 1) {
        // 1 is the Invest tab
        SecureLogger.d('INVEST TAB: Refreshing all saving configuration...');
        ref.invalidate(savingConfigProvider);
        ref.invalidate(amountDenominationsProvider);
        ref.invalidate(weightDenominationsProvider);
      }
    });

    // Sync timer with config
    ref.listen<AsyncValue<SavingConfig>>(savingConfigProvider, (prev, next) {
      if (next.hasValue &&
          next.value != null &&
          !ref.read(sellRateTimerProvider).isActive) {
        ref
            .read(sellRateTimerProvider.notifier)
            .startOrRefresh(next.value!.sellRateLockSeconds);
      }
    });

    // Reset input when switching between Gold and Silver
    ref.listen<CommodityType>(commodityProvider, (prev, next) {
      if (prev != next) {
        _amountController.clear();
        _selectedAmount = '';
        // Invalidate denominations to trigger the seed listeners with new data
        ref.invalidate(amountDenominationsProvider);
        ref.invalidate(weightDenominationsProvider);
      }
    });

    // Seed popular amount denomination
    ref.listen<AsyncValue<List<AmountDenomination>>>(
        amountDenominationsProvider, (prev, next) {
      if (next.hasValue && next.value != null && _isAmountMode) {
        final denoms = next.value!;
        if (denoms.isNotEmpty) {
          final popular =
              denoms.firstWhere((d) => d.isPopular, orElse: () => denoms.first);
          final String valStr = popular.value % 1 == 0
              ? popular.value.toInt().toString()
              : popular.value.toString();
          setState(() {
            _amountController.text = valStr;
            _selectedAmount = valStr;
          });
        }
      }
    });

    // Seed popular weight denomination
    ref.listen<AsyncValue<List<WeightDenomination>>>(
        weightDenominationsProvider, (prev, next) {
      if (next.hasValue && next.value != null && !_isAmountMode) {
        final denoms = next.value!;
        if (denoms.isNotEmpty) {
          final popular =
              denoms.firstWhere((d) => d.isPopular, orElse: () => denoms.first);
          final String valStr = popular.value % 1 == 0
              ? popular.value.toInt().toString()
              : popular.value.toString();
          setState(() {
            _amountController.text = valStr;
            _selectedAmount = valStr;
          });
        }
      }
    });

    final marketState = timerState.isActive
        ? AsyncData(timerState.lockedRates!)
        : ref.watch(marketRatesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Gradient Header ────────────────────────────────────────────
          GradientHeader(
            title: ref.tr('Instant Saving'),
            onBack: () {
              final routeName = ModalRoute.of(context)?.settings.name;
              if (routeName == AppRouter.instantSaving) {
                Navigator.pop(context);
              } else {
                ref.read(selectedTabProvider.notifier).state = 0;
              }
            },
          ),

          // ── Scrollable body (cream background) ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  // Live rate — on light background per Figma
                  _buildLiveRateChip(isDark, type, marketState, timerState),
                  SizedBox(height: 20.h),
                  _buildCommodityTabs(isDark, type),
                  SizedBox(height: 16.h),
                  _buildAmountInputCard(isDark, type, marketState, configAsync,
                      amountDenoms, weightDenoms),
                  SizedBox(height: 16.h),
                  _buildTotalAmountCard(isDark, marketState, type, configAsync),
                  SizedBox(height: 24.h),
                  _buildSecurityPill(isDark),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _buildBottomAction(isDark, marketState, type, configAsync),
    );
  }

  Widget _buildLiveRateChip(bool isDark, CommodityType type,
      AsyncValue<MarketRates> market, TimerState timerState) {
    return market.when(
      data: (rates) {
        final price =
            type == CommodityType.gold ? rates.goldSell : rates.silverSell;
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
                        'Live Selling Price',
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
                      'Valid for : ${timerState.remainingSeconds ~/ 60}:${(timerState.remainingSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹ ${price.toStringAsFixed(2)}/gm',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '+3% GST',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildCommodityTabs(bool isDark, CommodityType current) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabItem(
                  'Gold', current == CommodityType.gold, isDark, () {
                ref
                    .read(commodityProvider.notifier)
                    .setCommodity(CommodityType.gold);
              }),
            ),
            Expanded(
              child: _buildTabItem(
                  'Silver', current == CommodityType.silver, isDark, () {
                ref
                    .read(commodityProvider.notifier)
                    .setCommodity(CommodityType.silver);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
      String label, bool isActive, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1B882C), Color(0xFF003716)],
                )
              : null,
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B882C).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white60 : const Color(0xFF064E3B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestModeItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF064E3B) : Colors.transparent,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF064E3B)
                    : Colors.black.withOpacity(0.15),
                width: isActive ? 0 : 1.5,
              ),
            ),
            child: isActive
                ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                : null,
          ),
          SizedBox(width: 10.w),
          Text(label,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.black : Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildAmountInputCard(
      bool isDark,
      CommodityType type,
      AsyncValue<dynamic> market,
      AsyncValue<SavingConfig> configAsync,
      AsyncValue<List<AmountDenomination>> amountDenoms,
      AsyncValue<List<WeightDenomination>> weightDenoms) {
    double inputVal = double.tryParse(_amountController.text) ?? 0.0;
    double conversion = 0.0;
    if (market.hasValue) {
      final rate = type == CommodityType.gold
          ? market.value.goldSell
          : market.value.silverSell;

      if (_isAmountMode) {
        final double gstRate = configAsync.valueOrNull?.gst ?? 3.0;
        final double goldValue = inputVal / (1 + (gstRate / 100));
        conversion = rate > 0 ? goldValue / rate : 0.0;
      } else {
        conversion = inputVal * rate;
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Select invest type ──
            Text('Select invest type',
                style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child:
                      _buildInvestModeItem('Buy in Rupees', _isAmountMode, () {
                    setState(() {
                      _isAmountMode = true;
                      _amountController.clear();
                      _selectedAmount = '';
                      final denoms =
                          ref.read(amountDenominationsProvider).valueOrNull;
                      if (denoms != null && denoms.isNotEmpty) {
                        final popular = denoms.firstWhere((d) => d.isPopular,
                            orElse: () => denoms.first);
                        final String valStr = popular.value % 1 == 0
                            ? popular.value.toInt().toString()
                            : popular.value.toString();
                        _amountController.text = valStr;
                        _selectedAmount = valStr;
                      }
                    });
                  }),
                ),
                Expanded(
                  child:
                      _buildInvestModeItem('Buy in Grams', !_isAmountMode, () {
                    setState(() {
                      _isAmountMode = false;
                      _amountController.clear();
                      _selectedAmount = '';
                      final denoms =
                          ref.read(weightDenominationsProvider).valueOrNull;
                      if (denoms != null && denoms.isNotEmpty) {
                        final popular = denoms.firstWhere((d) => d.isPopular,
                            orElse: () => denoms.first);
                        final String valStr = popular.value % 1 == 0
                            ? popular.value.toInt().toString()
                            : popular.value.toString();
                        _amountController.text = valStr;
                        _selectedAmount = valStr;
                      }
                    });
                  }),
                ),
              ],
            ),

            SizedBox(height: 16.h),
            Divider(height: 1, color: Colors.black.withOpacity(0.05)),
            SizedBox(height: 12.h),

            // ── Enter your saving amount ──
            Text('Enter your saving amount',
                style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  if (_isAmountMode)
                    Text('₹',
                        style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                  if (_isAmountMode) SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      onChanged: (v) => setState(() => _selectedAmount = v),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                        const NoLeadingZerosFormatter(),
                      ],
                      style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                      decoration: const InputDecoration(
                          border: InputBorder.none, hintText: '0'),
                    ),
                  ),
                  // Conversion text on same line (right-aligned)
                  if (inputVal > 0)
                    Text(
                      _isAmountMode
                          ? '${conversion.toStringAsFixed(4)}gm'
                          : '₹${conversion.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600),
                    ),
                  if (!_isAmountMode)
                    Text('gms',
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black45)),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            _isAmountMode
                ? amountDenoms.maybeWhen(
                    data: (list) => _buildDenominationsRow(list),
                    orElse: () => const SizedBox(),
                  )
                : weightDenoms.maybeWhen(
                    data: (list) => _buildDenominationsRow(list),
                    orElse: () => const SizedBox(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenominationsRow(List<dynamic> denoms) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: denoms.map((d) {
          final double val = d.value;
          final bool isPopular = d.isPopular;

          // Robust selection check
          final double inputVal =
              double.tryParse(_amountController.text.trim()) ?? 0.0;
          final double selectedVal = double.tryParse(_selectedAmount) ?? 0.0;
          final bool isSelected = (inputVal - val).abs() < 0.0001 ||
              (selectedVal - val).abs() < 0.0001;

          final label = _isAmountMode
              ? '₹${val % 1 == 0 ? val.toInt() : val}'
              : '${val % 1 == 0 ? val.toInt() : val}g';

          return Padding(
            padding: EdgeInsets.only(right: 12.w, top: 20.h),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                InkWell(
                  onTap: () {
                    final String valStr =
                        val % 1 == 0 ? val.toInt().toString() : val.toString();
                    _amountController.text = valStr;
                    setState(() => _selectedAmount = valStr);
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF064E3B).withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                if (isPopular)
                  Positioned(
                    top: -14.h,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C), // accent orange
                        borderRadius: BorderRadius.circular(6.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalAmountCard(bool isDark, AsyncValue<dynamic> market,
      CommodityType type, AsyncValue<SavingConfig> configAsync) {
    final config = configAsync.valueOrNull;
    if (config == null || !market.hasValue) return const SizedBox.shrink();

    var inputVal = double.tryParse(_selectedAmount) ?? 0.0;
    final double gstRate = config.gst / 100;
    final rate = type == CommodityType.gold
        ? market.value.goldSell
        : market.value.silverSell;

    double totalPayable = 0.0;
    double goldValueWithoutTax = 0.0;
    double gstAmount = 0.0;
    double grams = 0.0;

    if (_isAmountMode) {
      totalPayable = inputVal;
      goldValueWithoutTax = totalPayable / (1 + gstRate);
      gstAmount = totalPayable - goldValueWithoutTax;
      grams = rate > 0 ? goldValueWithoutTax / rate : 0.0;
    } else {
      grams = inputVal;
      goldValueWithoutTax = grams * rate;
      gstAmount = goldValueWithoutTax * gstRate;
      totalPayable = goldValueWithoutTax + gstAmount;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () =>
                  setState(() => _isBreakdownExpanded = !_isBreakdownExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                        Text('Incl.taxes',
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.black38,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('₹${totalPayable.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                        SizedBox(width: 8.w),
                        Icon(
                          _isBreakdownExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 24.sp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isBreakdownExpanded) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _buildBreakdownRow(
                  type == CommodityType.gold ? 'Gold Value' : 'Silver Value',
                  '₹${goldValueWithoutTax.toStringAsFixed(2)}'),
              _buildBreakdownRow('GST (${config.gst.toStringAsFixed(2)}%)',
                  '₹${gstAmount.toStringAsFixed(2)}'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              _buildBreakdownRow('Quantity', '${grams.toStringAsFixed(4)}gm'),
              SizedBox(height: 8.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPill(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                color: const Color(0xFF91411D), size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                '100% Secure Transaction & Bank Grade Storage',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF91411D).withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isDark, AsyncValue<dynamic> market,
      CommodityType type, AsyncValue<SavingConfig> configAsync) {
    final config = configAsync.valueOrNull;
    if (config == null || !market.hasValue) return const SizedBox.shrink();

    var inputVal = double.tryParse(_selectedAmount) ?? 0.0;
    final double gstRate = config.gst / 100;
    double totalPayable = _isAmountMode
        ? inputVal
        : (inputVal *
            (type == CommodityType.gold
                ? market.value.goldSell
                : market.value.silverSell) *
            (1 + gstRate));

    final isInvalid = (totalPayable < config.minAmount ||
        totalPayable > config.maxAmount ||
        totalPayable <= 0);

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: CustomButton(
          text: 'Confirm Order',
          isLoading: _isProcessing,
          loadingText: 'Processing...',
          onPressed: (isInvalid || _isProcessing)
              ? null
              : () => _handleConfirmOrder(market, type, totalPayable, config),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isInvalid
                ? [
                    const Color(0xFF1B882C).withOpacity(0.45),
                    const Color(0xFF003716).withOpacity(0.45),
                  ]
                : const [Color(0xFF1B882C), Color(0xFF003716)],
          ),
          boxShadow: isInvalid
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1B882C).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
          textColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _handleConfirmOrder(AsyncValue<dynamic> market,
      CommodityType type, double totalPayable, SavingConfig config) async {
    SecureLogger.d(
        'ORDER FLOW: Starting confirmation for $type - total: $totalPayable');
    setState(() => _isProcessing = true);
    try {
      final marketValue = market.valueOrNull;
      final rate = (type == CommodityType.gold
              ? marketValue?.goldSell
              : marketValue?.silverSell) ??
          0.0;

      final user = ref.read(userProvider);
      final customerId = user?.id ?? '';
      final mobile = user?.mobile ?? '';

      if (customerId.isEmpty || rate == 0) {
        SecureLogger.e(
            'ORDER FLOW BLOCKED: Invalid state (customer: $customerId, rate: $rate)');
        if (mounted) {
          setState(() => _isProcessing = false);
          AppToast.show(
              context, 'Market rates not ready. Please wait a moment.',
              type: ToastType.warning);
        }
        return;
      }

      SecureLogger.d('ORDER FLOW: Calling check-eligibility API...');
      // Resolve id_metal dynamically from the API commodity list
      final metalId = ref.read(selectedMetalIdProvider);
      final eligibility =
          await ref.read(savingServiceProvider).checkEligibility(
                customerId: customerId,
                metalId: metalId,
                mobile: mobile,
                amount: totalPayable,
                rate: rate,
              );

      SecureLogger.d(
          'ORDER FLOW: API returned nextStep: ${eligibility.nextStep}');

      if (mounted) setState(() => _isProcessing = false);

      if (eligibility.nextStep == 'KYC_REQUIRED') {
        Navigator.pushNamed(context, '/kyc', arguments: {
          'request_from': 'instant',
          'amount': totalPayable,
          'metal_id': metalId,
          'rate': rate,
        });
      } else if (eligibility.nextStep == 'PAYMENT') {
        Navigator.pushNamed(context, AppRouter.paymentMethods, arguments: {
          'amount': totalPayable,
          'metal_id': metalId,
          'rate': rate,
        });
      } else if (eligibility.nextStep == 'UPI_LIST') {
        Navigator.pushNamed(context, '/upi-list', arguments: {
          'amount': totalPayable,
          'metal_id': metalId,
          'rate': rate,
        });
      } else {
        Navigator.pushNamed(context, AppRouter.paymentMethods, arguments: {
          'amount': totalPayable,
          'metal_id': metalId,
          'rate': rate,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToast.show(
            context, 'Something went wrong. Please try again later.',
            type: ToastType.error);
      }
    }
  }
}

class TrendLinePainter extends CustomPainter {
  final Color color;

  TrendLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.8,
        size.width * 0.4, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.1,
        size.width * 0.8, size.height * 0.3);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);

    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    canvas.drawPath(areaPath, areaPaint);
  }

  @override
  bool shouldRepaint(TrendLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
