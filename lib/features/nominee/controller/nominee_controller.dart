import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nominee_model.dart';
import '../services/nominee_service.dart';

// ─── Service Provider ───────────────────────────────────────────────────────
final nomineeServiceProvider = Provider((ref) => NomineeService());

// ─── Nominee Details Provider ───────────────────────────────────────────────
/// Global nominee provider — cached for the session lifetime.
/// Use `ref.invalidate(nomineeDetailsProvider)` to force refresh.
final nomineeDetailsProvider = FutureProvider<NomineeDetails?>((ref) async {
  final service = ref.watch(nomineeServiceProvider);
  return service.getNomineeDetails();
});

/// Quick check: returns `true` if nominee has been added.
final hasNomineeProvider = Provider<bool>((ref) {
  final nomineeAsync = ref.watch(nomineeDetailsProvider);
  return nomineeAsync.maybeWhen(
    data: (nominee) => nominee != null && nominee.isValid,
    orElse: () => false,
  );
});

// --- Dynamic Relationship List Provider ---------------------------------
/// Fetches the relationship list from the API.
/// Falls back to the hardcoded [nomineeRelationships] list on failure.
final nomineeRelationshipsProvider =
    FutureProvider<List<NomineeRelationship>>((ref) async {
  final service = ref.watch(nomineeServiceProvider);
  final result = await service.fetchRelationships();
  return result ?? nomineeRelationships;
});
