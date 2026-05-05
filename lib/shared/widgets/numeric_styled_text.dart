import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds a [RichText] widget that uses [GoogleFonts.lora] for numeric
/// characters (digits, ₹, %, ., :, /, +, −, ×, X, K, T) and [GoogleFonts.playfairDisplay]
/// for everything else.
///
/// This enforces the fintech typography rule:
///   • Numbers & financial symbols → **Lora**
///   • Text, labels, headings      → **Playfair Display**
///
/// K/T are included so commodity purity labels like "24KT" or "24K"
/// render entirely in the numeric font.
class NumericStyledText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double? height;
  final double? letterSpacing;
  final TextAlign textAlign;

  const NumericStyledText(
    this.text, {
    super.key,
    required this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.color = Colors.black,
    this.height,
    this.letterSpacing,
    this.textAlign = TextAlign.start,
  });

  /// Characters that should be rendered with Lora (numeric font).
  /// Includes K/T for commodity purity labels (e.g. 24KT, 24K).
  static final _numericPattern = RegExp(r'[\d₹%\.,:\\/\+\-×XxKTkt]+');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _numericPattern.allMatches(text)) {
      // Text before the numeric match → Playfair Display
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: height,
            letterSpacing: letterSpacing,
          ),
        ));
      }
      // The numeric match → Lora
      spans.add(TextSpan(
        text: match.group(0),
        style: GoogleFonts.lora(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        ),
      ));
      lastEnd = match.end;
    }

    // Remaining text after last match → Playfair Display
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        ),
      ));
    }

    // If there are no numeric chars at all, just use Playfair Display.
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        ),
      ));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
}
