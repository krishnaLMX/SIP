class MaskingUtils {
  /// Mask a mobile number:
  /// - Strips country code prefix (+91, +1, etc.) only when preceded by '+'.
  /// - Masks the FIRST 6 digits of the local number with '●'.
  /// - Shows the LAST 4 digits in plain text.
  ///
  /// Examples:
  ///   +91 9488577633  →  ●●●●●●7633
  ///   +919488577633   →  ●●●●●●7633
  ///   9488577633      →  ●●●●●●7633
  static String maskMobile(String mobile) {
    String digits;

    if (mobile.startsWith('+')) {
      // International format: strip '+' + country code digits + optional space
      // e.g. "+91 9488577633" → "9488577633"
      //      "+919488577633"  → "9488577633"
      digits = mobile.replaceFirst(RegExp(r'^\+\d{1,3}\s*'), '').trim();
    } else {
      // Bare number — keep as-is (strip any non-digit chars like spaces/dashes)
      digits = mobile.replaceAll(RegExp(r'\D'), '');
    }

    // Safety: if more than 10 digits, take last 10
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    if (digits.length <= 4) return digits;

    // Mask first (length - 4) digits with ●, show last 4
    final maskedCount = digits.length - 4;
    final visible = digits.substring(maskedCount); // last 4
    final masked = 'X' * maskedCount;              // first 6
    return '$masked$visible';
  }

  /// Mask a bank account number to show only the last 4 digits.
  static String maskBankAccount(String acc) {
    if (acc.length < 4) return acc;
    final lastPart = acc.substring(acc.length - 4);
    final maskedPart = 'x' * (acc.length - 4);
    return '$maskedPart$lastPart';
  }

  /// Mask a PAN number.
  static String maskPan(String pan) {
    if (pan.length < 4) return pan;
    final firstPart = pan.substring(0, 2);
    final lastPart = pan.substring(pan.length - 2);
    final maskedPart = 'x' * (pan.length - 4);
    return '$firstPart$maskedPart$lastPart';
  }

  /// Mask an email.
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length < 3) return email;
    final firstPart = name.substring(0, 2);
    return '$firstPart...${name.substring(name.length - 1)}@$domain';
  }
}
