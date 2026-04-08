class MaskingUtils {
  /// Mask a mobile number to show only the last 5 digits.
  /// Example: 1234567890 -> xxxxx67890
  static String maskMobile(String mobile) {
    if (mobile.length < 5) return mobile;
    final lastPart = mobile.substring(mobile.length - 5);
    final maskedPart = 'x' * (mobile.length - 5);
    return '$maskedPart$lastPart';
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
