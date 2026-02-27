class Validators {
  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    final regExp = RegExp(r'^[0-9]{10}$');
    if (!regExp.hasMatch(value)) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'Enter a 6-digit OTP';
    return null;
  }
}
