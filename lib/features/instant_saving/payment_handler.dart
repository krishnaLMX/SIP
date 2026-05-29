// lib/features/instant_saving/payment_handler.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// PaymentHandler — Centralized Cashfree Payment Orchestrator
//
// This class is the SINGLE source of truth for all Cashfree payment logic.
// It replaces the inline Cashfree code that previously lived in
// PaymentMethodsScreen, making the full payment flow reusable from any screen.
//
// Responsibilities:
//   1. Call savings/initiate API to create a server-side order
//   2. Launch Cashfree Web Checkout using the returned session_id
//   3. Handle Cashfree SUCCESS callback → call savings/confirm-payment
//   4. Handle Cashfree FAILURE callback → call savings/confirm-payment (notify server)
//   5. Navigate to PurchaseSuccessScreen with the correct result data
//
// Usage (from InvestScreen OR after KYC completes):
//
//   final handler = PaymentHandler(ref: ref, context: context);
//   await handler.startPayment(
//     amount:   totalPayable,
//     metalId:  metalId,
//     rate:     rate,
//     buyType:  1,       // 1 = AMOUNT, 2 = GRAMS
//     weight:   grams,
//   );
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/providers/timer_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/security/secure_logger.dart';
import '../../shared/widgets/app_toast.dart';
import 'controller/saving_controller.dart';
import 'models/saving_models.dart';
import 'screens/purchase_success_screen.dart';

class PaymentHandler {
  final WidgetRef ref;
  final BuildContext context;

  // Cashfree SDK gateway service — single instance per handler.
  final CFPaymentGatewayService _cfPaymentGatewayService =
      CFPaymentGatewayService();

  // Stores the server-confirmed amount_inr after savings/initiate succeeds.
  // Used in the success/failure screen when savings/confirm-payment
  // doesn't return the amount.
  double _confirmedAmountInr = 0;

  // Callbacks passed by the caller to toggle loading state on the parent widget.
  VoidCallback? _onLoadingStart;
  VoidCallback? _onLoadingEnd;

  PaymentHandler({required this.ref, required this.context});

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Entry point. Call this from InvestScreen (direct PAYMENT path) or
  /// from InvestScreen after KYC returns `true`.
  ///
  /// [onLoadingStart] / [onLoadingEnd] — optional callbacks so the caller can
  /// show/hide its own loading indicator while payment is in-flight.
  Future<void> startPayment({
    required double amount,
    required String metalId,
    required double rate,
    required int buyType, // 1 = AMOUNT, 2 = GRAMS
    required double weight,
    String? couponCode,
    VoidCallback? onLoadingStart,
    VoidCallback? onLoadingEnd,
  }) async {
    _onLoadingStart = onLoadingStart;
    _onLoadingEnd = onLoadingEnd;

    // Register Cashfree callbacks BEFORE initiating the order so the SDK is
    // ready to receive callbacks as soon as doPayment() is called.
    _cfPaymentGatewayService.setCallback(_onCashfreeSuccess, _onCashfreeError);

    _onLoadingStart?.call();

    try {
      await _initiatePurchase(
        amount: amount,
        metalId: metalId,
        rate: rate,
        buyType: buyType,
        weight: weight,
        couponCode: couponCode,
      );
    } catch (e) {
      _onLoadingEnd?.call();
      if (context.mounted) {
        final message = (e is Failure)
            ? e.message
            : 'Payment initiation failed. Please try again.';
        AppToast.show(context, message, type: ToastType.error);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — savings/initiate
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initiatePurchase({
    required double amount,
    required String metalId,
    required double rate,
    required int buyType,
    required double weight,
    String? couponCode,
  }) async {
    final user = ref.read(userProvider);
    if (user == null) throw Exception('User not logged in');

    // Use the timer-locked rate if available; otherwise fall back to the
    // rate that was passed in (already validated before calling startPayment).
    final timerState = ref.read(sellRateTimerProvider);
    final activeRate = timerState.isActive
        ? (metalId == '1'
            ? timerState.lockedRates!.goldSell
            : timerState.lockedRates!.silverSell)
        : rate;

    // ── Weight calculation ─────────────────────────────────────────────────
    // buyType 1 (AMOUNT): weight is derived from amount / rate (net of GST).
    // buyType 2 (GRAMS) : weight is exactly what the customer requested.
    final double weightForApi;
    if (buyType == 2) {
      weightForApi = double.parse(weight.toStringAsFixed(4));
    } else {
      final config = ref.read(savingConfigProvider).valueOrNull;
      final gstRate = (config?.gst ?? 3.0) / 100;
      final raw = (amount / (1 + gstRate)) / activeRate;
      weightForApi = double.parse(raw.toStringAsFixed(4));
    }

    SecureLogger.d(
        '[PaymentHandler] savings/initiate → buyType=$buyType | weight=$weightForApi');

    final PurchaseInitiateResponse purchase =
        await ref.read(savingServiceProvider).initiatePurchase(
              customerId: user.id,
              metalId: metalId,
              mobile: user.mobile,
              buyType: buyType,
              amount: amount,
              rate: activeRate,
              weight: weightForApi,
              couponCode: couponCode,
            );

    // Use the server-confirmed amount_inr (authoritative for the gateway).
    // For GRAMS mode this may differ from [amount] when the rate has moved.
    final confirmedAmount =
        (purchase.amountInr != null && purchase.amountInr!.isNotEmpty)
            ? double.tryParse(purchase.amountInr!) ?? amount
            : amount;

    _confirmedAmountInr = confirmedAmount;

    SecureLogger.d(
        '[PaymentHandler] initiate OK → orderId=${purchase.orderId}');

    // ── STEP 2: Launch Cashfree ─────────────────────────────────────────────
    if (context.mounted) {
      _launchCashfree(purchase);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Launch Cashfree Web Checkout
  // ─────────────────────────────────────────────────────────────────────────

  void _launchCashfree(PurchaseInitiateResponse purchase) {
    if (purchase.orderId == null || purchase.sessionId == null) {
      _onLoadingEnd?.call();
      if (context.mounted) {
        AppToast.show(
            context, 'Failed to initiate payment session. Please try again.',
            type: ToastType.error);
      }
      return;
    }

    try {
      final env = purchase.environment?.toUpperCase() == 'PRODUCTION'
          ? CFEnvironment.PRODUCTION
          : CFEnvironment.SANDBOX;

      final session = CFSessionBuilder()
          .setEnvironment(env)
          .setOrderId(purchase.orderId!)
          .setPaymentSessionId(purchase.sessionId!)
          .build();

      final cfWebCheckoutPayment =
          CFWebCheckoutPaymentBuilder().setSession(session).build();

      SecureLogger.d('[PaymentHandler] Launching Cashfree SDK...');
      _cfPaymentGatewayService.doPayment(cfWebCheckoutPayment);

      // Loading stays active — it is cleared inside the Cashfree callbacks.
    } catch (e) {
      _onLoadingEnd?.call();
      if (context.mounted) {
        final message = (e is Failure)
            ? e.message
            : 'Payment gateway error. Please try again.';
        AppToast.show(context, message, type: ToastType.error);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3a — Cashfree SUCCESS callback
  // ─────────────────────────────────────────────────────────────────────────

  void _onCashfreeSuccess(String orderId) async {
    SecureLogger.d('[PaymentHandler] Cashfree SUCCESS → orderId=$orderId');
    _onLoadingEnd?.call();
    await _confirmAndNavigate(orderId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3b — Cashfree FAILURE callback
  // ─────────────────────────────────────────────────────────────────────────

  void _onCashfreeError(CFErrorResponse errorResponse, String orderId) async {
    SecureLogger.e(
        '[PaymentHandler] Cashfree ERROR → orderId=$orderId | ${errorResponse.getMessage()}');
    _onLoadingEnd?.call();

    // Always notify the server even on failure so it can update order status.
    final fallbackMsg =
        'Payment failed for order $orderId.\n${errorResponse.getMessage()}';
    await _confirmAndNavigate(orderId,
        wasError: true, fallbackErrorMsg: fallbackMsg);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4 — savings/confirm-payment → navigate to result screen
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _confirmAndNavigate(
    String orderId, {
    bool wasError = false,
    String? fallbackErrorMsg,
  }) async {
    Map<String, dynamic>? response;

    try {
      response =
          await ref.read(savingServiceProvider).confirmPayment(orderId);
      SecureLogger.d('[PaymentHandler] confirm-payment response received');
    } catch (e) {
      // Server error during confirm — still navigate to result screen.
      SecureLogger.e('[PaymentHandler] confirm-payment threw: $e');
    }

    if (!context.mounted) return;

    final bool isSuccess =
        !wasError && (response?['success'] == true);

    if (isSuccess) {
      // ── SUCCESS ─────────────────────────────────────────────────────────
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseSuccessScreen(
            data: {
              'isSuccess': true,
              'orderId': response?['data']?['order_id'] ?? orderId,
              'weight': response?['data']?['grams_credited'] ??
                  response?['data']?['credited_weight'] ??
                  response?['data']?['weight'],
              'message': response?['message'] ??
                  'Gold has been successfully added to your locker.',
              'commodity_name': response?['data']?['commodity_name'],
              'total_amount': response?['data']?['total_amount'] ??
                  (_confirmedAmountInr > 0 ? _confirmedAmountInr : 0),
              'rate': response?['data']?['rate'],
              'payment_mode': response?['data']?['payment_mode'],
            },
          ),
        ),
      );
    } else {
      // ── FAILURE ─────────────────────────────────────────────────────────
      // Prefer server message; fall back to Cashfree error message.
      final errorMsg = response?['message'] ??
          response?['error']?['message'] ??
          fallbackErrorMsg ??
          'Your order could not be processed. Please try again.';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseSuccessScreen(
            data: {
              'isSuccess': false,
              'orderId': orderId,
              'message': errorMsg,
            },
          ),
        ),
      );
    }
  }
}
