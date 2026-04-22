import 'package:flutter/material.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/otp/otp_screen.dart';
import '../features/mpin/mpin_screen.dart';
import '../features/kyc/screens/pan_verification_screen.dart';
import '../features/instant_saving/instant_saving_screen.dart';
import '../features/daily_savings/daily_savings_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/support/support_screen.dart';
import '../features/referral/referral_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/auth/pin/pin_creation_screen.dart';
import '../features/auth/pin/pin_screen.dart';
import '../features/auth/registration/registration_screen.dart';
import '../features/auth/registration/registration_success_screen.dart';
import '../features/profile/account_details_screen.dart';
import '../features/withdrawal/screens/withdrawal_screen.dart';
import '../features/withdrawal/screens/withdrawal_confirmation_screen.dart';
import '../features/withdrawal/screens/upi_selection_screen.dart';
import '../features/withdrawal/screens/withdrawal_success_screen.dart';
import '../features/kyc/screens/kyc_screen.dart' as dynamic_kyc;
import '../features/instant_saving/screens/payment_methods_screen.dart';
import '../features/history/screens/transaction_history_screen.dart';
import '../features/history/screens/transaction_details_screen.dart';
import '../features/content/screens/content_screen.dart';
import '../features/content/screens/faq_screen.dart';
import '../features/content/screens/contact_us_screen.dart';
import '../features/support/screens/enquiry_form_screen.dart';
import '../features/support/screens/enquiry_list_screen.dart';
import '../features/main/main_screen.dart';
import '../core/services/content_service.dart';
import '../features/mpin/change_mpin_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/screens/delete_account_screen.dart';
import '../features/referral/referee_list_screen.dart';

class AppRouter {
  static const String splash = '/splash';
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
  static const String main = '/main';
  static const String profile = '/profile';
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
  static const String upiSelection = '/upi-selection';
  static const String withdrawalSuccess = '/withdrawal-success';
  static const String registrationSuccess = '/registration-success';
  static const String accountDetails = '/accountdetails';
  static const String transactionHistory = '/transaction-history';
  static const String transactionDetails = '/transaction-details';
  static const String changeMpin = '/change-mpin';
  static const String maintenance = '/maintenance';
  static const String notifications = '/notifications';
  static const String deleteAccount = '/delete-account';
  static const String refereeList = '/referee-list';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        otp: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return OtpScreen(
            mobile: args['mobile'],
            countryCode: args['countryCode'] ?? '+91',
            idCountry: args['idCountry'] ?? '101',
            otpReferenceId: args['otpReferenceId'] ?? '',
          );
        },
        mpin: (context) => const MpinScreen(),
        changeMpin: (context) => const ChangeMpinScreen(),
        kyc: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
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
        home: (context) => const MainScreen(),
        main: (context) => const MainScreen(),
        profile: (context) => const ProfileScreen(),
        accountDetails: (context) => const AccountDetailsScreen(),
        transactionHistory: (context) => const TransactionHistoryScreen(),
        transactionDetails: (context) {
          final tx = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return TransactionDetailsScreen(transactionData: tx);
        },
        support: (context) => const SupportScreen(),
        referral: (context) => const ReferralScreen(),
        settings: (context) => const SettingsScreen(),
        mpinCreation: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return PinCreationScreen(
            mobile: args['mobile'] ?? '',
            fullName: args['fullName'] ?? '',
            email: args['email'] ?? '',
            dob: args['dob'] ?? '',
            referralCode: args['referralCode'] ?? '',
            tempToken: args['tempToken'] ?? '',
          );
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
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
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
            buyType: (args['buy_type'] as int?) ?? 1,
            weight: (args['weight'] as num?)?.toDouble() ?? 0.0,
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
        upiSelection: (context) => const UpiSelectionScreen(),
        withdrawalSuccess: (context) => WithdrawalSuccessScreen(
            data: ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>),
        registrationSuccess: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return RegistrationSuccessScreen(fullName: args['fullName'] ?? '');
        },
        maintenance: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return MaintenanceScreen(
            resumeRoute: args['resumeRoute'] as String? ?? AppRouter.login,
          );
        },
        notifications: (context) => const NotificationsScreen(),
        deleteAccount: (context) => const DeleteAccountScreen(),
        refereeList: (context) => const RefereeListScreen(),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (routes.containsKey(settings.name)) {
      return MaterialPageRoute(
        builder: (context) => routes[settings.name]!(context),
        settings: settings,
      );
    }
    // Fallback: unknown or null route — show recoverable error screen
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.explore_off_rounded,
                      size: 48,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Page Not Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The route "${settings.name ?? 'unknown'}" does not exist.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.main,
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Go to Home',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
