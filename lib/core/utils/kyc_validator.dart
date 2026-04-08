class KycValidator {
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhaar number is required';
    final regex = RegExp(r'^[2-9]{1}[0-9]{11}$');
    if (!regex.hasMatch(value)) return 'Must be 12 digits (starts with 2-9)';
    return null;
  }

  static String? validatePAN(String? value) {
    if (value == null || value.isEmpty) return 'PAN number is required';
    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!regex.hasMatch(value.toUpperCase())) return 'Format: AAAAA9999A';
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(value))
      return 'Enter a valid 10-digit Indian mobile number';
    return null;
  }

  static String? validateUPI(String? value) {
    if (value == null || value.isEmpty) return 'UPI ID is required';
    final regex = RegExp(r'^[a-zA-Z0-9._-]{2,256}@[a-zA-Z]{2,64}$');
    if (!regex.hasMatch(value)) return 'Format: name@bank';
    return null;
  }

  static String? validateGeneric(String? value, String regex, String errorMsg) {
    if (value == null || value.isEmpty) return 'Required';
    final reg = RegExp(regex);
    if (!reg.hasMatch(value)) return errorMsg;
    return null;
  }
}

