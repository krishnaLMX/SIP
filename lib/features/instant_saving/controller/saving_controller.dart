import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saving_models.dart';
import '../services/saving_service.dart';

final savingServiceProvider = Provider((ref) => SavingService());
final paymentServiceProvider = Provider((ref) => PaymentService());

final savingConfigProvider = FutureProvider<SavingConfig>((ref) async {
  final service = ref.watch(savingServiceProvider);
  return service.getSavingConfig();
});

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getPaymentMethods();
});

class InstantSavingState {
  final double amount;
  final String? transactionId;
  final bool kycRequired;

  InstantSavingState({
    this.amount = 0,
    this.transactionId,
    this.kycRequired = false,
  });

  InstantSavingState copyWith({
    double? amount,
    String? transactionId,
    bool? kycRequired,
  }) {
    return InstantSavingState(
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      kycRequired: kycRequired ?? this.kycRequired,
    );
  }
}

class InstantSavingNotifier extends StateNotifier<InstantSavingState> {
  InstantSavingNotifier() : super(InstantSavingState());

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setTransactionData(String id, bool kycReq) {
    state = state.copyWith(transactionId: id, kycRequired: kycReq);
  }
}

final instantSavingControllerProvider =
    StateNotifierProvider<InstantSavingNotifier, InstantSavingState>((ref) {
  return InstantSavingNotifier();
});
