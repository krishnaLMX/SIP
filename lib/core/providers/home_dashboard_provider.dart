import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/home_service.dart';
import '../../features/home/models/home_dashboard.dart';
import 'commodity_provider.dart';
import 'user_provider.dart';

final homeServiceProvider = Provider<HomeService>((ref) => HomeService());

final homeDashboardProvider = FutureProvider<HomeDashboard?>((ref) async {
  // Watch userProvider so this provider auto-invalidates on login/logout.
  // When user logs out (null) → returns null immediately (no 401 call).
  // When user logs in → re-fetches fresh dashboard with new session token.
  final user = ref.watch(userProvider);
  if (user == null || user.id.isEmpty) return null;

  final service = ref.watch(homeServiceProvider);
  final idMetal = ref.watch(selectedMetalIdProvider); // dynamic from API
  return service.getHomeDashboard(idMetal);
});
