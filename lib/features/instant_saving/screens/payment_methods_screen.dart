import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip/shared/theme/app_theme.dart';
import '../controller/saving_controller.dart';
import 'package:sip/core/providers/user_provider.dart';
import '../models/saving_models.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  final double amount;
  final String metalId;
  final double rate;
  final String? couponCode;

  const PaymentMethodsScreen({
    super.key,
    required this.amount,
    required this.metalId,
    required this.rate,
    this.couponCode,
  });

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  String? _selectedMethodId;
  bool _isLoading = false;

  Future<void> _createPaymentOrder() async {
    if (_selectedMethodId == null) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider);
      if (user == null) throw Exception('User not logged in');

      // 1. Initiate Purchase
      final PurchaseInitiateResponse purchase =
          await ref.read(savingServiceProvider).initiatePurchase(
            customerId: user.id,
            metalId: widget.metalId,
            mobile: user.mobile,
            buyType: 'AMOUNT',
            amount: widget.amount,
            rate: widget.rate,
            couponCode: widget.couponCode,
          );

      if (purchase.transactionId == null) {
        throw Exception('Failed to initiate purchase');
      }

      // 2. Create Payment Order
      final order = await ref.read(paymentServiceProvider).createOrder(
            amount: widget.amount,
            methodId: _selectedMethodId!,
            transactionId: purchase.transactionId!,
          );

      if (mounted) {
        // Redirect to PG URL
        // In real app, use url_launcher or WebView
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redirecting to: ${order.paymentUrl}')),
        );

        // Mock status verification after 2 seconds
        Future.delayed(const Duration(seconds: 2), () async {
          final status = await ref
              .read(paymentServiceProvider)
              .verifyPaymentStatus(order.orderId);
          if (status == 'SUCCESS') {
            // Navigate to success screen
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiation failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Select Payment Method',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildAmountHeader(isDark),
          Expanded(
            child: methodsAsync.when(
              data: (methods) => ListView.builder(
                padding: EdgeInsets.all(24.w),
                itemCount: methods.length,
                itemBuilder: (context, index) =>
                    _buildMethodTile(methods[index], isDark),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(isDark),
    );
  }

  Widget _buildAmountHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Text('TOTAL PAYABLE',
              style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          SizedBox(height: 8.h),
          Text('₹${widget.amount.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildMethodTile(PaymentMethod method, bool isDark) {
    final isSelected = _selectedMethodId == method.id;
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethodId = method.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
                color: isSelected
                    ? AppTheme.arcticBlue
                    : (isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05)),
                width: isSelected ? 2 : 1),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                    color: AppTheme.arcticBlue.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14.r)),
                child: Center(
                    child: Icon(Icons.payment, color: AppTheme.arcticBlue)),
              ),
              SizedBox(width: 16.w),
              Text(method.name,
                  style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black)),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: AppTheme.arcticBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createPaymentOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.arcticBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Proceed to Pay',
                  style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
        ),
      ),
    );
  }
}
