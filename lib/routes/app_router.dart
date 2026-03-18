import 'package:flutter/material.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/otp/otp_screen.dart';
import '../features/mpin/mpin_screen.dart';
import '../features/kyc/screens/pan_verification_screen.dart';
import '../features/instant_saving/instant_saving_screen.dart';
import '../features/daily_savings/daily_savings_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/statements/statements_screen.dart';
import '../features/support/support_screen.dart';
import '../features/referral/referral_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/auth/pin/pin_creation_screen.dart';
import '../features/auth/pin/pin_screen.dart';
import '../features/auth/registration/registration_screen.dart';
import '../features/withdrawal/screens/withdrawal_screen.dart';
import '../features/withdrawal/screens/withdrawal_confirmation_screen.dart';
import '../features/kyc/screens/kyc_screen.dart' as dynamic_kyc;
import '../features/instant_saving/screens/payment_methods_screen.dart';
import '../features/content/screens/content_screen.dart';
import '../features/content/screens/faq_screen.dart';
import '../features/content/screens/contact_us_screen.dart';
import '../features/support/screens/enquiry_form_screen.dart';
import '../features/support/screens/enquiry_list_screen.dart';
import '../core/services/content_service.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String mpin = '/mpin';
  static const String kyc = '/kyc';
  static const String panVerification = '/pan-verification';
  static const String aadhaarVerification = '/aadhaar-verification';
  static const String bankVerification = '/bank-verification';
  static const String instantSaving = '/instant-saving';
  static const String dailySavings = '/daily-savings';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String statements = '/statements';
  static const String support = '/support';
  static const String referral = '/referral';
  static const String settings = '/settings';
  static const String mpinCreation = '/mpin-creation';
  static const String pinEntry = '/pin-entry';
  static const String registration = '/registration';
  static const String withdrawal = '/withdrawal';
  static const String withdrawalConfirmation = '/withdrawal-confirmation';
  static const String payment = '/payment';
  static const String dynamicKyc = '/kyc-dynamic';
  static const String paymentMethods = '/payment-methods';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String faq = '/faq';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String enquiryForm = '/enquiry-form';
  static const String enquiryList = '/enquiry-list';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        otp: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return OtpScreen(
            mobile: args['mobile'],
            countryCode: args['countryCode'] ?? '+91',
            otpReferenceId: args['otpReferenceId'] ?? '',
          );
        },
        mpin: (context) => const MpinScreen(),
        kyc: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
          return dynamic_kyc.KycScreen(
            requestFrom: args['request_from'] ?? 'instant',
            extraData: args,
          );
        },
        panVerification: (context) => const PanVerificationScreen(),
        aadhaarVerification: (context) =>
            const Scaffold(body: Center(child: Text('Aadhaar Verification'))),
        bankVerification: (context) =>
            const Scaffold(body: Center(child: Text('Bank Verification'))),
        instantSaving: (context) => const InstantSavingScreen(),
        dailySavings: (context) => const DailySavingsScreen(),
        home: (context) => const HomeScreen(),
        profile: (context) => const ProfileScreen(),
        statements: (context) => const StatementsScreen(),
        support: (context) => const SupportScreen(),
        referral: (context) => const ReferralScreen(),
        settings: (context) => const SettingsScreen(),
        mpinCreation: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return PinCreationScreen(mobile: args['mobile'] ?? '');
        },
        pinEntry: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return PinScreen(mobile: args['mobile'] ?? '');
        },
        registration: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return RegistrationScreen(
            mobile: args['mobile'] ?? '',
            tempToken: args['tempToken'] ?? '',
          );
        },
        withdrawal: (context) => const WithdrawalScreen(),
        withdrawalConfirmation: (context) =>
            const WithdrawalConfirmationScreen(),
        payment: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return Scaffold(
            appBar: AppBar(title: const Text('Secure Payment')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded,
                      size: 80, color: Colors.indigo),
                  const SizedBox(height: 24),
                  Text('Completing Payment for ₹${args['amount'] ?? '0'}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      'Plan: ${args['type'] == 'daily_sip' ? 'Daily Savings' : 'One-time'}',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Home'),
                  )
                ],
              ),
            ),
          );
        },
        dynamicKyc: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
          return dynamic_kyc.KycScreen(
            requestFrom: args['request_from'] ?? 'instant',
            extraData: args,
          );
        },
        paymentMethods: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return PaymentMethodsScreen(
            amount: args['amount'],
            metalId: args['metal_id'],
            rate: args['rate'],
            couponCode: args['coupon_code'],
          );
        },
        terms: (context) => ContentScreen(
          title: 'Terms & Conditions',
          provider: termsProvider,
        ),
        privacy: (context) => ContentScreen(
          title: 'Privacy Policy',
          provider: privacyPolicyProvider,
        ),
        about: (context) => ContentScreen(
          title: 'About Us',
          provider: aboutUsProvider,
        ),
        faq: (context) => const FaqScreen(),
        contact: (context) => const ContactUsScreen(),
        enquiryForm: (context) => const EnquiryFormScreen(),
        enquiryList: (context) => const EnquiryListScreen(),
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
