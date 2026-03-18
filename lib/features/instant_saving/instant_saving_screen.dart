import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip/shared/theme/app_theme.dart';
import 'package:sip/core/providers/market_provider.dart';
import 'package:sip/core/providers/commodity_provider.dart';
import 'package:sip/shared/widgets/animations.dart';
import 'package:sip/core/services/shared_service.dart';
import 'package:sip/core/providers/user_provider.dart';

import 'package:sip/core/localization/language_provider.dart';
import 'controller/saving_controller.dart';
import 'models/saving_models.dart';

class InstantSavingScreen extends ConsumerStatefulWidget {
  const InstantSavingScreen({super.key});

  @override
  ConsumerState<InstantSavingScreen> createState() =>
      _InstantSavingScreenState();
}

class _InstantSavingScreenState extends ConsumerState<InstantSavingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController =
      TextEditingController(text: '100');
  late AnimationController _pulseController;
  String _selectedAmount = '100';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Set initial amount if passed from arguments
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
    final marketState = ref.watch(marketRatesStreamProvider);
    final configAsync = ref.watch(savingConfigProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: isDark ? Colors.white : Colors.black, 
            size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          ref.tr('instantSavingTitle'),
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildLiveRateChip(isDark, type, marketState),
            _buildGlassInput(isDark, type, marketState, configAsync),

            // Quick Selection
            ref.watch(amountDenominationsProvider).when(
                  data: (denominations) =>
                      _buildPremiumQuickSelection(isDark, denominations),
                  loading: () => _buildQuickSelectionLoading(isDark),
                  error: (_, __) => _buildPremiumQuickSelection(
                      isDark, []), // Fallback to empty if error
                ),

            SizedBox(height: 24.h),
            _buildSecurityPill(isDark),

            // Extra Info Sections
            // Removed _buildRateTable and _buildPriceTrendChart

            SizedBox(height: 32.h),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildFloatingAction(isDark, marketState, type, configAsync),
    );
  }

  Widget _buildLiveRateChip(
      bool isDark, CommodityType type, AsyncValue<dynamic> market) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: market.when(
        data: (rates) {
          final price = type == CommodityType.gold ? rates.goldSell : rates.silverSell;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppTheme.arcticBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(color: AppTheme.arcticBlue.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: BoxDecoration(
                          color: AppTheme.arcticBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.arcticBlue.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'LIVE',
                        style: GoogleFonts.outfit(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.arcticBlue,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CURRENT ${type == CommodityType.gold ? ref.tr('gold') : ref.tr('silver')} PRICE'.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(2)} / gram',
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildGlassInput(bool isDark, CommodityType type,
      AsyncValue<dynamic> market, AsyncValue<SavingConfig> configAsync) {
    double grams = 0.0;
    if (market.hasValue) {
      final rate = type == CommodityType.gold
          ? market.value.goldSell
          : market.value.silverSell;
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      grams = amount / rate;
    }

    return FadeInAnimation(
      delay: const Duration(milliseconds: 400),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(40.r),
            border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                ref.tr('amountQuestion'),
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  color: isDark ? Colors.white60 : Colors.black45,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 32.h),
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹',
                      style: GoogleFonts.outfit(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.arcticBlue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() => _selectedAmount = val),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1,
                        ),
                        cursorColor: AppTheme.arcticBlue,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(
                              color: isDark ? Colors.white10 : Colors.black12),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              configAsync.when(
                data: (config) {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  final isInvalid = amount > 0 &&
                      (amount < config.minAmount || amount > config.maxAmount);

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppTheme.arcticBlue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(100.r),
                          border: Border.all(color: AppTheme.arcticBlue.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '≈ ${grams.toStringAsFixed(4)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.arcticBlue,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              type == CommodityType.gold ? ref.tr('gold') : ref.tr('silver'),
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isInvalid) ...[
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.redAccent, size: 16.sp),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                amount < config.minAmount
                                    ? ref.tr('minAmount', args: {
                                        'amount':
                                            config.minAmount.toInt().toString()
                                      })
                                    : ref.tr('maxAmount', args: {
                                        'amount':
                                            config.maxAmount.toInt().toString()
                                      }),
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumQuickSelection(
      bool isDark, List<AmountDenomination> denominations) {
    if (denominations.isEmpty) return const SizedBox.shrink();

    return FadeInAnimation(
      delay: const Duration(milliseconds: 600),
      child: Container(
        height: 70.h,
        margin: EdgeInsets.only(top: 24.h),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          physics: const BouncingScrollPhysics(),
          itemCount: denominations.length,
          separatorBuilder: (context, index) => SizedBox(width: 12.w),
          itemBuilder: (context, index) {
            final deno = denominations[index];
            final amt = deno.value.toStringAsFixed(0);
            final isSelected = _selectedAmount == amt;
            
            return GestureDetector(
                onTap: () {
                  _amountController.text = amt;
                  setState(() => _selectedAmount = amt);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                          horizontal: 28.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.arcticBlue
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.arcticBlue
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08)),
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppTheme.arcticBlue.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '₹$amt',
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                    if (deno.isPopular)
                      Positioned(
                        top: -6.h,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              'BEST VALUE',
                              style: GoogleFonts.outfit(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickSelectionLoading(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: List.generate(
          4,
          (index) => Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Container(
              width: 80.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityPill(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 10.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              ref.tr('secureTransaction'),
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF10B981) : const Color(0xFF065F46),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAction(bool isDark, AsyncValue<dynamic> market,
      CommodityType type, AsyncValue<SavingConfig> configAsync) {
    final amount = double.tryParse(_selectedAmount) ?? 0.0;
    final config = configAsync.valueOrNull;
    final isInvalid = config != null &&
        (amount < config.minAmount || amount > config.maxAmount || amount <= 0);

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 36.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr('totalPayable').toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₹${double.tryParse(_selectedAmount)?.toStringAsFixed(0) ?? _selectedAmount}',
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: isInvalid
                  ? null
                  : () async {
                      final amount = double.tryParse(_selectedAmount) ?? 0;
                      if (amount <= 0) return;

                      final configAsync = ref.read(savingConfigProvider);
                      final config = configAsync.valueOrNull ??
                          SavingConfig.defaultConfig();

                      // 1. Validate against global config
                      if (amount < config.minAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Minimum purchase is ₹${config.minAmount.toInt()}')),
                        );
                        return;
                      }

                      if (amount > config.maxAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Maximum purchase is ₹${config.maxAmount.toInt()}')),
                        );
                        return;
                      }

                      // 2. Initiate Purchase flow governed by Backend
                      try {
                        final marketValue = market.valueOrNull;
                        final rate = (type == CommodityType.gold
                                ? marketValue?.goldSell
                                : marketValue?.silverSell) ??
                            0.0;

                        final user = ref.read(userProvider);
                        final eligibility = await ref
                            .read(savingServiceProvider)
                            .checkEligibility(
                              customerId: user?.id ?? '',
                              metalId: type == CommodityType.gold ? '1' : '2',
                              mobile: user?.mobile ?? '',
                              amount: amount,
                              rate: rate,
                            );

                        if (eligibility.nextStep == 'KYC_REQUIRED') {
                          // Navigate to Dynamic KYC Screen
                          Navigator.pushNamed(context, '/kyc', arguments: {
                            'request_from': 'instant',
                            'amount': amount,
                            'metal_id': type == CommodityType.gold ? '1' : '2',
                            'rate': rate,
                          });
                        } else {
                          // Proceed to Payment Method Selection
                          Navigator.pushNamed(context, '/payment-methods',
                              arguments: {
                                'amount': amount,
                                'metal_id': type == CommodityType.gold ? '1' : '2',
                                'rate': rate,
                              });
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: isInvalid
                      ? null
                      : LinearGradient(
                          colors: [AppTheme.arcticBlue, AppTheme.electricCyan],
                        ),
                  color: isInvalid
                      ? (isDark ? Colors.white12 : Colors.black12)
                      : null,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    if (!isInvalid)
                      BoxShadow(
                        color: AppTheme.arcticBlue.withValues(alpha: 0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    ref.tr('confirmOrder').toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
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
