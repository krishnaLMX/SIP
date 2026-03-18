import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sip/routes/app_router.dart';
import 'package:sip/features/kyc/models/kyc_step.dart';

class KycState {
  final List<KycStep> steps;
  final bool isLoading;
  final String? error;

  KycState({
    required this.steps,
    this.isLoading = false,
    this.error,
  });

  KycState copyWith({
    List<KycStep>? steps,
    bool? isLoading,
    String? error,
  }) {
    return KycState(
      steps: steps ?? this.steps,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class KycNotifier extends StateNotifier<KycState> {
  KycNotifier() : super(KycState(steps: [])) {
    _initKycSteps();
  }

  void _initKycSteps() {
    state = KycState(
      steps: [
        KycStep(
          id: 'pan',
          title: 'PAN Card Verification',
          description: 'Essential for tax compliance and investment protocols.',
          icon: Icons.credit_card_rounded,
          status: KycStatus.pending,
          route: AppRouter.panVerification,
        ),
        KycStep(
          id: 'aadhaar',
          title: 'Identity Proof',
          description: 'Submit Aadhaar or Passport for identity confirmation.',
          icon: Icons.person_pin_outlined,
          status: KycStatus.pending,
          route: AppRouter.aadhaarVerification,
        ),
        KycStep(
          id: 'bank',
          title: 'Bank Details',
          description:
              'Link your bank account to facilitate seamless transfers.',
          icon: Icons.account_balance_rounded,
          status: KycStatus.pending,
          route: AppRouter.bankVerification,
        ),
      ],
    );
  }
}

final kycStepsProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier();
});
