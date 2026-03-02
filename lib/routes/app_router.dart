import 'package:flutter/material.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/otp/otp_screen.dart';
import '../features/mpin/mpin_screen.dart';
import '../features/kyc/kyc_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/statements/statements_screen.dart';
import '../features/support/support_screen.dart';
import '../features/referral/referral_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String mpin = '/mpin';
  static const String kyc = '/kyc';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String statements = '/statements';
  static const String support = '/support';
  static const String referral = '/referral';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        otp: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return OtpScreen(
            mobile: args['mobile'],
            otpSessionId: args['otpSessionId'],
          );
        },
        mpin: (context) => const MpinScreen(),
        kyc: (context) => const KycScreen(),
        home: (context) => const HomeScreen(),
        profile: (context) => const ProfileScreen(),
        statements: (context) => const StatementsScreen(),
        support: (context) => const SupportScreen(),
        referral: (context) => const ReferralScreen(),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (routes.containsKey(settings.name)) {
      return MaterialPageRoute(
        builder: (context) => routes[settings.name]!(context),
        settings: settings,
      );
    }
    return MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Center(child: Text('Route Not Found')),
      ),
    );
  }
}
