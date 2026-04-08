import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography system for the startGOLD app.
///
/// Usage:
///   Text('Hello', style: AppTextStyles.displayLarge(isDark))
///   Text('Hello', style: AppTextStyles.titleLarge(isDark).copyWith(color: Colors.red))
///
/// DO NOT modify existing screens that are already production-stable.
/// Adopt this class gradually — one screen at a time.
///
/// Reference implementation: Withdrawal flow screens.
class AppTextStyles {
  AppTextStyles._(); // Prevent instantiation

  // ─── Color helpers ───────────────────────────────────────────────────────
  static Color _primary(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF1E293B);

  static Color _secondary(bool isDark) =>
      isDark ? Colors.white54 : Colors.black54;

  static Color _muted(bool isDark) =>
      isDark ? Colors.white38 : Colors.black45;

  // ─── 1. Display Large ────────────────────────────────────────────────────
  // Hero titles on success/failure screens, MPIN title
  // Example: "Redemption Initiated!", "AUTHORIZE WITHDRAWAL"
  static TextStyle displayLarge(bool isDark) => GoogleFonts.lora(
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        color: _primary(isDark),
      );

  // ─── 2. Title Large ──────────────────────────────────────────────────────
  // Page section headers, key numerical values, bottom sheet titles
  // Example: "Complete your KYC", "Add Account", "₹ 234.70/gm", amounts
  static TextStyle titleLarge(bool isDark) => GoogleFonts.lora(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: _primary(isDark),
      );

  // ─── 3. Title Medium ─────────────────────────────────────────────────────
  // GradientHeader text, button text, card titles
  // Example: "Withdraw Funds", "Confirm Withdrawal", "DONE"
  static TextStyle titleMedium(bool isDark) => GoogleFonts.lora(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: _primary(isDark),
      );

  // ─── 4. Body Large ───────────────────────────────────────────────────────
  // Subtitles, descriptions, input field text, placeholders
  // Example: "Select your preferred payout method...", input values
  static TextStyle bodyLarge(bool isDark) => GoogleFonts.lora(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: _primary(isDark),
      );

  // ─── 5. Body Medium ──────────────────────────────────────────────────────
  // Secondary descriptions, summary row labels, card subtitles
  // Example: "You will receive", "Selling weight", row labels
  static TextStyle bodyMedium(bool isDark) => GoogleFonts.lora(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: _secondary(isDark),
      );

  // ─── 6. Body Small ───────────────────────────────────────────────────────
  // Form field labels, detail row labels, enquiry labels
  // Example: "Enter UPI ID", "Transaction ID", "Placed on"
  static TextStyle bodySmall(bool isDark) => GoogleFonts.lora(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: _secondary(isDark),
      );

  // ─── 7. Label Medium ─────────────────────────────────────────────────────
  // Helper text, info notes, timestamps, disclaimer text
  // Example: "Only one buy order per metal...", "Rate updated..."
  static TextStyle labelMedium(bool isDark) => GoogleFonts.lora(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: _muted(isDark),
      );

  // ─── 8. Label Small ──────────────────────────────────────────────────────
  // Badges, captions, overline text, timer text
  // Example: "Valid for : 01:20", "CREDIT TO", "Pure Silver" badge
  static TextStyle labelSmall(bool isDark) => GoogleFonts.lora(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        color: _muted(isDark),
      );

  // ─── Convenience variants ────────────────────────────────────────────────

  /// Bold value text for amounts, quantities (same size as titleLarge but w800)
  static TextStyle valueLarge(bool isDark) => GoogleFonts.lora(
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: _primary(isDark),
      );

  /// Detail row value text — right-aligned values in order/transaction details
  static TextStyle valueSmall(bool isDark) => GoogleFonts.lora(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: _primary(isDark),
      );

  /// Input field style — for TextFormField / TextField
  static TextStyle input(bool isDark) => GoogleFonts.lora(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: _primary(isDark),
      );

  /// Input placeholder / hint style
  static TextStyle inputHint(bool isDark) => GoogleFonts.lora(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: _muted(isDark),
      );

  /// Button text style (used inside CustomButton or ElevatedButton)
  static TextStyle button(bool isDark) => GoogleFonts.lora(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
}
