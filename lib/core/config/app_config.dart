class AppConfig {
  static const String appName = 'startGOLD';
  static const String baseUrl =
      'http://startgoldapi.logimaxindia.com/api/api/v1/'; // Fixed trailing slash http://192.168.1.72:8000/api/v1/
  //  http://startgoldapi.logimaxindia.com/api/v1/

  // Storage Keys
  static const String keyHasSeenOnboarding = 'hasSeenOnboarding';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyMobileNumber = 'mobile_number';
  static const String keyIsMpinEnabled = 'is_mpin_enabled';
  static const String keyIsBiometricEnabled = 'is_biometric_enabled';
  static const String keyCustomerId = 'customer_id';
  static const String keyCustomerName = 'customer_name';
  static const String keyCustomerPhoto = 'customer_photo';
  static const String keyServerPublicKey =
      'server_public_key'; // RSA public key cache

  // Network Config
  static const int connectTimeout = 60000;
  static const int receiveTimeout = 60000;

  // Crypto / Key Exchange
  static const String publicKeyEndpoint = 'crypto/public-key';

  // Security
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
    'verify-upi',
    'verify-bank',
    'payment',
    'investment',
    'mpin/create',
    'mpin/validate',
    'mpin/change',
    'mpin/reset',
  ];

  // These fields in the payload will be encrypted
  static const List<String> sensitiveFields = [
    'password',
    'otp',
    'login_pin',
    'transaction_pin',
    'aadhaar_number',
    'pan_number', // this is for testing
    'pan',
    'bank_account_number',
    'account_no',
    'ifsc_code',
    'upi_id',
    'kyc_details',
    'withdrawal_amount',
    'payment_details',
    'amount', // from Payment APIs rule
    'amount_inr', // this is testing now
    'payment_pin', // from Payment APIs rule
    'bank_details', // from Payment APIs rule
    'mpin', // MPIN rule
    'old_mpin',
    'new_mpin',
    'mobile', // encrypt PII
    'weight', // withdrawal: grams being sold
    'buy_rate', // withdrawal: rate at time of sale
  ];
}
