class AppConfig {
  static const String appName = 'StartGold';
  static const String baseUrl =
      'https://api.startgold.com/v1'; // Production URL

  // Storage Keys
  static const String keyHasSeenOnboarding = 'hasSeenOnboarding';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyMobileNumber = 'mobile_number';

  // Network Config
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Security
  static const List<String> allowedCertFingerprints = [
    'XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX', // Placeholder
  ];
}
