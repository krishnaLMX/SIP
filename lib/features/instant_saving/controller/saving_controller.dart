import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saving_models.dart';
import '../services/saving_service.dart';

final savingServiceProvider = Provider((ref) => SavingService());
final paymentServiceProvider = Provider((ref) => PaymentService());

final savingConfigProvider = FutureProvider.autoDispose<SavingConfig>((ref) async {
  final service = ref.watch(savingServiceProvider);
  return service.getSavingConfig();
});

final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getPaymentMethods();
});

class InstantSavingState {
  final double amount;
  final String? transactionId;
  final bool kycRequired;
  final PaymentMethod? selectedPaymentMethod;

  InstantSavingState({
    this.amount = 0,
    this.transactionId,
    this.kycRequired = false,
    this.selectedPaymentMethod,
  });

  InstantSavingState copyWith({
    double? amount,
    String? transactionId,
    bool? kycRequired,
    PaymentMethod? selectedPaymentMethod,
  }) {
    return InstantSavingState(
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      kycRequired: kycRequired ?? this.kycRequired,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
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

  void setSelectedPaymentMethod(PaymentMethod? method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }
}

final instantSavingControllerProvider =
    StateNotifierProvider<InstantSavingNotifier, InstantSavingState>((ref) {
  return InstantSavingNotifier();
});

