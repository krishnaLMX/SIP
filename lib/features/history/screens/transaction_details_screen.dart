import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/history_controller.dart';
import '../models/history_models.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/theme/app_theme.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> transactionData;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionData,
  });

  @override
  ConsumerState<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends ConsumerState<TransactionDetailsScreen> {
  bool _isOrderDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final transactionId = widget.transactionData['id'];
    final detailsState = ref.watch(transactionDetailsProvider(transactionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(title: 'Transaction Details'),
          Expanded(
            child: detailsState.when(
              data: (details) => _buildContent(context, details, isDark),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                // Strip exception prefix to show only the pure API error message
                final errorMessage = err.toString().replaceAll('Exception: ', '');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: const Color(0xFFDC2626), size: 48.sp),
                      SizedBox(height: 16.h),
                      Text(
                        'Failed to load details',
                        style: GoogleFonts.lora(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        errorMessage,
                        style: GoogleFonts.lora(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransactionDetailResponse details, bool isDark) {
    final bool isSaving = details.metalName.toLowerCase() == 'gold' || details.title.toLowerCase().contains('saving');
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedTextColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final cardColor = isDark ? Colors.white.withOpacity(0.04) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          _buildTopCard(details, isSaving, cardColor, borderColor, textColor, mutedTextColor, isDark),
          SizedBox(height: 16.h),
          _buildStatusCard(details, isSaving, cardColor, borderColor, textColor, mutedTextColor, isDark),
          SizedBox(height: 16.h),
          _buildOrderDetails(details, isSaving, cardColor, borderColor, textColor, mutedTextColor, isDark),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildTopCard(TransactionDetailResponse details, bool isSaving, Color cardColor, Color borderColor, Color textColor, Color mutedTextColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: isSaving
                  ? const Color(0xFF023214).withOpacity(0.1)
                  : const Color(0xFF4ADE80).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isSaving
                  ? Icon(Icons.flash_on_rounded, color: const Color(0xFFD97706), size: 26.sp)
                  : Icon(Icons.account_balance_wallet_rounded, color: const Color(0xFF023214), size: 26.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  style: GoogleFonts.lora(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  details.subtitle,
                  style: GoogleFonts.lora(
                    fontSize: 13.sp,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${details.amount}',
                style: GoogleFonts.lora(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${details.weightGrams} g',
                style: GoogleFonts.lora(
                  fontSize: 13.sp,
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusCard(TransactionDetailResponse details, bool isSaving, Color cardColor, Color borderColor, Color textColor, Color mutedTextColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Status',
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 24.h),
          ...details.timeline.map((step) => _buildTimelineStep(step, isDark: isDark, textColor: textColor, mutedTextColor: mutedTextColor, isLast: details.timeline.last == step, isFirst: details.timeline.first == step)).toList(),
          SizedBox(height: 16.h),
          Divider(color: borderColor, height: 1),
          SizedBox(height: 16.h),
          Text(
            details.footerMessage,
            style: GoogleFonts.lora(
              fontSize: 13.sp,
              color: mutedTextColor,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              if (details.invoiceUrl.isNotEmpty) ...[
                Expanded(
                  flex: isSaving ? 4 : 10,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(details.invoiceUrl);
                        try {
                        final launched = await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched && context.mounted) {
                          AppToast.show(context, 'No app found to open the invoice', type: ToastType.warning);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.show(context, 'Could not open invoice', type: ToastType.error);
                        }
                      }
                    },
                    icon: Icon(Icons.download_rounded,
                        color: textColor, size: 20.sp),
                    label: Text('Invoice',
                        style: TextStyle(
                            color: textColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.r)),
                    ),
                  ),
                ),
                if (isSaving) SizedBox(width: 12.w),
              ],
              if (isSaving)
                Expanded(
                  flex: details.invoiceUrl.isNotEmpty ? 6 : 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.greenGradient,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRouter.instantSaving);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.r)),
                        elevation: 0,
                      ),
                      child: Text('Save ₹${details.amount} Again',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(TimelineStep step, {bool isFirst = false, bool isLast = false, required Color textColor, required Color mutedTextColor, required bool isDark}) {
    // Determine colors and icon based on status
    final statusLower = step.status.toLowerCase();
    final bool isFailed = statusLower == 'failed' || statusLower == 'failure' || statusLower == 'cancelled';
    final bool isPending = statusLower == 'pending' || statusLower == 'processing';

    // Status-specific styling
    final Color stepColor;
    final Color badgeBgColor;
    final Color badgeTextColor;
    final IconData stepIcon;

    if (isFailed) {
      stepColor = const Color(0xFFDC2626);
      badgeBgColor = const Color(0xFFDC2626).withOpacity(0.12);
      badgeTextColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      stepIcon = Icons.cancel_rounded;
    } else if (isPending) {
      stepColor = const Color(0xFFF59E0B);
      badgeBgColor = const Color(0xFFF59E0B).withOpacity(0.12);
      badgeTextColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      stepIcon = Icons.schedule_rounded;
    } else {
      // Success / default
      stepColor = const Color(0xFF10B981);
      badgeBgColor = const Color(0xFF10B981).withOpacity(0.15);
      badgeTextColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
      stepIcon = Icons.check_circle;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24.w,
            child: Column(
              children: [
                if (!isFirst) Container(width: 2.w, height: 12.h, color: stepColor.withOpacity(0.4)),
                Icon(stepIcon, color: stepColor, size: 18.sp),
                if (!isLast) Expanded(child: Container(width: 2.w, color: stepColor.withOpacity(0.4))),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(step.stepName, style: GoogleFonts.lora(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          step.status,
                          style: GoogleFonts.lora(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    step.time,
                    style: GoogleFonts.lora(fontSize: 12.sp, color: mutedTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(TransactionDetailResponse details, bool isSaving, Color cardColor, Color borderColor, Color textColor, Color mutedTextColor, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: _isOrderDetailsExpanded ? 20.h : 8.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isOrderDetailsExpanded = !_isOrderDetailsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details',
                    style: GoogleFonts.lora(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  AnimatedRotation(
                    turns: _isOrderDetailsExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: textColor, size: 24.sp),
                  ),
                ],
              ),
            ),
          ),
          if (_isOrderDetailsExpanded) ...[
            SizedBox(height: 16.h),
            Text(
              'PRICE BREAKDOWN',
              style: GoogleFonts.lora(fontSize: 11.sp, color: mutedTextColor, letterSpacing: 0.5, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildDetailRow('Gold quantity', details.priceBreakdown.quantity, textColor, mutedTextColor),
            _buildDetailRow(isSaving ? 'Gold purchased at' : 'Gold sold at', details.priceBreakdown.rate, textColor, mutedTextColor),
            _buildDetailRow('Gold value', details.priceBreakdown.value, textColor, mutedTextColor),
            _buildDetailRow('GST', details.priceBreakdown.gst, textColor, mutedTextColor),
            Divider(color: borderColor, height: 24.h),
            _buildDetailRow('Amount', details.priceBreakdown.totalAmount, textColor, mutedTextColor, isBold: true),
            SizedBox(height: 32.h),
            Text(
              'TRANSACTION DETAILS',
              style: GoogleFonts.lora(fontSize: 11.sp, color: mutedTextColor, letterSpacing: 0.5, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildDetailRow('Transaction ID', details.technicalDetails.transactionIdDisplay, textColor, mutedTextColor, showCopy: true),
            if (details.technicalDetails.goldTransactionId != null)
              _buildDetailRow('Gold transaction ID', details.technicalDetails.goldTransactionId!, textColor, mutedTextColor, showCopy: true),
            _buildDetailRow('Placed on', details.technicalDetails.placedOn, textColor, mutedTextColor),
            _buildDetailRow(isSaving ? 'Paid via' : 'UPI ID', details.technicalDetails.paidVia, textColor, mutedTextColor),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color mutedTextColor, {bool isBold = false, bool showCopy = false}) {
    // Hide row when server returns empty / placeholder data
    if (value.isEmpty || value == 'N/A' || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? textColor : mutedTextColor,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.lora(
                  fontSize: 13.sp,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (showCopy) ...[
                SizedBox(width: 8.w),
                Icon(Icons.copy_outlined, color: mutedTextColor, size: 14.sp),
              ]
            ],
          )
        ],
      ),
    );
  }
}

