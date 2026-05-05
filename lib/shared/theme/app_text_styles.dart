import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography system for the startGOLD app.
///
/// Font Strategy:
///   • Content & special characters → Playfair Display
///   • Numeric values (₹, weights, rates, OTP digits) → Lora
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── CONTENT STYLES (Playfair Display) ─────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── 1. Display Large ────────────────────────────────────────────────────
  // Hero titles on success/failure screens, MPIN title
  // Example: "Redemption Initiated!", "AUTHORIZE WITHDRAWAL"
  static TextStyle displayLarge(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        color: _primary(isDark),
      );

  // ─── 2. Title Large ──────────────────────────────────────────────────────
  // Page section headers, key numerical values, bottom sheet titles
  // Example: "Complete your KYC", "Add Account"
  static TextStyle titleLarge(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: _primary(isDark),
      );

  // ─── 3. Title Medium ─────────────────────────────────────────────────────
  // GradientHeader text, button text, card titles
  // Example: "Withdraw Funds", "Confirm Withdrawal", "DONE"
  static TextStyle titleMedium(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: _primary(isDark),
      );

  // ─── 4. Body Large ───────────────────────────────────────────────────────
  // Subtitles, descriptions, input field text, placeholders
  // Example: "Select your preferred payout method...", input values
  static TextStyle bodyLarge(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: _primary(isDark),
      );

  // ─── 5. Body Medium ──────────────────────────────────────────────────────
  // Secondary descriptions, summary row labels, card subtitles
  // Example: "You will receive", "Selling weight", row labels
  static TextStyle bodyMedium(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: _secondary(isDark),
      );

  // ─── 6. Body Small ───────────────────────────────────────────────────────
  // Form field labels, detail row labels, enquiry labels
  // Example: "Enter UPI ID", "Transaction ID", "Placed on"
  static TextStyle bodySmall(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: _secondary(isDark),
      );

  // ─── 7. Label Medium ─────────────────────────────────────────────────────
  // Helper text, info notes, timestamps, disclaimer text
  // Example: "Only one buy order per metal...", "Rate updated..."
  static TextStyle labelMedium(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: _muted(isDark),
      );

  // ─── 8. Label Small ──────────────────────────────────────────────────────
  // Badges, captions, overline text, timer text
  // Example: "CREDIT TO", "Pure Silver" badge
  static TextStyle labelSmall(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        color: _muted(isDark),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── NUMERIC STYLES (Lora) ─────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bold value text for amounts, quantities (same size as titleLarge but w800)
  /// Example: "₹ 1,234.50", "4.5000g"
  static TextStyle valueLarge(bool isDark) => GoogleFonts.lora(
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: _primary(isDark),
      );

  /// Detail row value text — right-aligned values in order/transaction details
  /// Example: "₹ 234.70", "0.1245g"
  static TextStyle valueSmall(bool isDark) => GoogleFonts.lora(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: _primary(isDark),
      );

  /// Numeric display — prices, rates, quantities at medium size
  /// Example: "₹ 234.70/gm", "8,500.00"
  static TextStyle numericLarge(bool isDark) => GoogleFonts.lora(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: _primary(isDark),
      );

  /// Numeric display — small values, weights, percentages
  /// Example: "0.1245g", "+2.5%"
  static TextStyle numericSmall(bool isDark) => GoogleFonts.lora(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: _primary(isDark),
      );

  /// Numeric display — medium values, timer, rates
  /// Example: "01:20", "₹ 7,500/gm"
  static TextStyle numericMedium(bool isDark) => GoogleFonts.lora(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: _primary(isDark),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── INPUT & BUTTON STYLES ─────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// Input field style — for TextFormField / TextField (Lora for numeric input)
  static TextStyle input(bool isDark) => GoogleFonts.lora(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: _primary(isDark),
      );

  /// Input placeholder / hint style (Playfair Display for hint text)
  static TextStyle inputHint(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: _muted(isDark),
      );

  /// Button text style (Playfair Display — used inside CustomButton or ElevatedButton)
  static TextStyle button(bool isDark) => GoogleFonts.playfairDisplay(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
}
