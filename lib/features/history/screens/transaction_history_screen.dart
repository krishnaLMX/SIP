import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_router.dart';
import '../../main/main_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/history_controller.dart';
import '../models/history_models.dart';
import '../../../shared/widgets/gradient_header.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(
            title: 'Transactions',
            onBack: () {
              final routeName = ModalRoute.of(context)?.settings.name;
              if (routeName == AppRouter.transactionHistory) {
                Navigator.pop(context);
              } else {
                ref.read(selectedTabProvider.notifier).state = 0;
              }
            },
          ),
          Expanded(
            child: historyState.when(
              data: (history) => _buildContent(context, history, isDark),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, HistoryResponse history, bool isDark) {
    final grouped = history.groupedTransactions;
    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text('No transactions yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 16.h, bottom: 40.h),
            itemCount: grouped.keys.length,
            itemBuilder: (context, index) {
              String dateKey = grouped.keys.elementAt(index);
              List<TransactionItem> items = grouped[dateKey]!;
              return _buildDateGroup(context, dateKey, items, isDark);
            },
          ),
        )
      ],
    );
  }

  Widget _buildDateGroup(BuildContext context, String date,
      List<TransactionItem> transactions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
          child: Text(
            date,
            style: GoogleFonts.lora(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : const Color(0xFF475569),
            ),
          ),
        ),
        ...transactions
            .map((tx) => _buildTransactionCard(context, tx, isDark))
            .toList(),
      ],
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, TransactionItem tx, bool isDark) {
    bool isSaving = tx.type == 'purchase';
    final cardColor = isDark ? Colors.white.withOpacity(0.04) : Colors.white;
    final borderColor =
        isDark ? Colors.white10 : Colors.black.withOpacity(0.05);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedTextColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(16.w),
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: borderColor),
          ),
        ),
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.transactionDetails,
              arguments: {
                'id': tx.transactionId,
                'type': tx.type,
              });
        },
        child: Row(
          children: [
            // Icon
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: isSaving
                    ? const Color(0xFF023214).withOpacity(0.1)
                    : const Color(0xFF4ADE80).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: isSaving
                    ? Icon(Icons.flash_on_rounded,
                        color: const Color(0xFFD97706), size: 24.sp)
                    : Icon(Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF023214), size: 22.sp),
              ),
            ),
            SizedBox(width: 14.w),
            // Middle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: GoogleFonts.lora(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: const Color(0xFF10B981), size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        tx.displayDate,
                        style: GoogleFonts.lora(
                          fontSize: 12.sp,
                          color: mutedTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${tx.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.lora(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${tx.weightGrams} g ${tx.metalName}',
                  style: GoogleFonts.lora(
                    fontSize: 12.sp,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
