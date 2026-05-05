import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startgold/shared/theme/app_theme.dart';

class DailySavingsScreen extends StatefulWidget {
  const DailySavingsScreen({super.key});

  @override
  State<DailySavingsScreen> createState() => _DailySavingsScreenState();
}

class _DailySavingsScreenState extends State<DailySavingsScreen> {
  String _selectedAmount = '20';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Daily Savings Setup',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black)),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Automate Your Savings',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 24.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 12.h),
            Text(
                'Set a small amount to save daily and watch your gold grow effortlessly.',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white70 : Colors.black54)),
            SizedBox(height: 48.h),
            Text('Select Daily Amount',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['₹10', '₹20', '₹50', '₹100'].map((amt) {
                final isSelected = '₹$_selectedAmount' == amt;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedAmount = amt.replaceAll('₹', '')),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.arcticBlue
                          : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(amt,
                        style: GoogleFonts.lora(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                        )),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60.h,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.arcticBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text('Proceed to Payment',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: Text('Secure Payment Gateway',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 12.sp,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

