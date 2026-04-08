import 'package:flutter/services.dart';

/// Prevents leading zeros in numeric input.
///
/// Rules:
/// - `009`  → blocked (leading zeros before non-zero digit)
/// - `0`    → allowed (single zero)
/// - `0.5`  → allowed (zero before decimal point)
/// - `1.009` → allowed (zeros after decimal point)
/// - `.5`   → converted to `0.5`
class NoLeadingZerosFormatter extends TextInputFormatter {
  final bool allowDecimal;

  const NoLeadingZerosFormatter({this.allowDecimal = true});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Allow empty
    if (text.isEmpty) return newValue;

    // If starts with '.', prefix with '0'
    if (allowDecimal && text.startsWith('.')) {
      return TextEditingValue(
        text: '0$text',
        selection: TextSelection.collapsed(offset: newValue.selection.end + 1),
      );
    }

    // Block leading zeros: "00", "007", etc.
    // Allow: "0", "0.", "0.5"
    if (text.length > 1 && text.startsWith('0') && text[1] != '.') {
      return oldValue;
    }

    // If decimal is not allowed, block '.'
    if (!allowDecimal && text.contains('.')) {
      return oldValue;
    }

    return newValue;
  }
}
