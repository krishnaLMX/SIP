import 'package:flutter/services.dart';

/// Capitalizes the first letter of every word as the user types.
/// Also strips any character that is not a letter or a space (defense-in-depth).
class UpperCaseWordsFormatter extends TextInputFormatter {
  // Allow only a-z, A-Z and space
  static final _allowed = RegExp(r'[a-zA-Z ]');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Strip disallowed characters first
    final cleaned =
        newValue.text.split('').where((ch) => _allowed.hasMatch(ch)).join();

    if (cleaned.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final buf = StringBuffer();
    bool capitalizeNext = true;
    for (int i = 0; i < cleaned.length; i++) {
      final ch = cleaned[i];
      if (ch == ' ') {
        capitalizeNext = true;
        buf.write(ch);
      } else if (capitalizeNext) {
        buf.write(ch.toUpperCase());
        capitalizeNext = false;
      } else {
        buf.write(ch);
      }
    }

    final newText = buf.toString();
    // Clamp the cursor so it never goes out of bounds after stripping
    final offset = newValue.selection.end.clamp(0, newText.length) as int;
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
