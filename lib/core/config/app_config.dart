class AppConfig {
  static const String appName = 'StartGold';
  static const String baseUrl =
      'https://mxhedge.logimaxindia.com/test/api/mock_api/'; // Fixed trailing slash http://192.168.1.49:8000/api/v1/
  //

  // Storage Keys
  static const String keyHasSeenOnboarding = 'hasSeenOnboarding';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyMobileNumber = 'mobile_number';
  static const String keyIsMpinEnabled = 'is_mpin_enabled';
  static const String keyCustomerId = 'customer_id';

  // Network Config
  static const int connectTimeout = 60000;
  static const int receiveTimeout = 60000;

  // Security
  static const String encryptionKey =
      'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'; // 32 chars for AES-256
  static const List<String> allowedCertFingerprints = [
    'XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX', // Placeholder
  ];

  // List of sensitive endpoints that REQUIRE encryption
  static const List<String> encryptedEndpoints = [
    'auth/generate-otp',
    'auth/verify-otp',
    'auth/register',
    'savings/initiate',
    'savings/check-eligibility',
    'submit-kyc',
    'update-kyc',
    'kyc/upload',
    'withdraw',
    'payment',
    'investment',
  ];

  // These fields in the payload will be encrypted
  static const List<String> sensitiveFields = [
    'password',
    // 'otp',
    'login_pin',
    'transaction_pin',
    'aadhaar_number',
    'pan_number',
    'bank_account_number',
    'ifsc_code',
    'upi_id',
    'kyc_details',
    'withdrawal_amount',
    'payment_details',
    'amount', // from Payment APIs rule
    // 'amount_inr', // this is testing now
    'payment_pin', // from Payment APIs rule
    'bank_details', // from Payment APIs rule
  ];
}
