import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:startgold/core/providers/user_provider.dart';
import 'package:startgold/features/kyc/models/kyc_document.dart';
import 'package:startgold/features/kyc/repositories/kyc_repository.dart';

final kycDocumentsProvider = FutureProvider.autoDispose.family<List<KycDocumentType>, String>((ref, requestFrom) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  
  return ref.read(kycRepositoryProvider).getDocumentTypes(
    customerId: user.id,
    requestFrom: requestFrom,
  );
});

final kycSubmitProvider = StateNotifierProvider<KycSubmitController, AsyncValue<bool>>((ref) {
  return KycSubmitController(ref.read(kycRepositoryProvider), ref);
});

class KycSubmitController extends StateNotifier<AsyncValue<bool>> {
  final KycRepository _repository;
  final Ref _ref;

  KycSubmitController(this._repository, this._ref) : super(const AsyncValue.data(false));

  Future<void> submit({
    required String requestFrom,
    required String documentId,
    required Map<String, dynamic> fields,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(userProvider);
      final success = await _repository.uploadKyc(
        customerId: user!.id,
        requestFrom: requestFrom,
        documentId: documentId,
        fields: fields,
      );
      state = AsyncValue.data(success);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

