import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class CountryCode {
  final String name;
  final String code; // ISO code (e.g., IN)
  final String prefix; // Phone prefix (e.g., +91)
  final String flag;

  CountryCode({
    required this.name,
    required this.code,
    required this.prefix,
    required this.flag,
  });

  factory CountryCode.fromJson(Map<String, dynamic> json) {
    return CountryCode(
      name: json['name'] ?? '',
      code: json['iso'] ?? '',
      prefix: json['code'] ?? '',
      flag: json['flag'] ?? '',
    );
  }
}

class Commodity {
  final String id;
  final int webSocketId;
  final String name;

  Commodity({
    required this.id,
    required this.webSocketId,
    required this.name,
  });

  factory Commodity.fromJson(Map<String, dynamic> json) {
    return Commodity(
      id: json['id_metal']?.toString() ?? '',
      webSocketId: int.tryParse(json['web_soc_id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class AmountDenomination {
  final double value;
  final bool isPopular;

  AmountDenomination({
    required this.value,
    required this.isPopular,
  });

  factory AmountDenomination.fromJson(Map<String, dynamic> json) {
    return AmountDenomination(
      value: (json['value'] ?? 0).toDouble(),
      isPopular: (json['is_popular'] ?? 0) == 1,
    );
  }
}

class SharedService {
  final ApiClient _apiClient = ApiClient();

  Future<List<CountryCode>> getCountryCodes() async {
    try {
      final response = await _apiClient.post('users/shared/country-codes');
      if (response.data != null && response.data['data'] != null) {
        final List list = response.data['data'];
        return list.map((item) => CountryCode.fromJson(item)).toList();
      }
      return [
        CountryCode(name: 'India', code: 'IN', prefix: '+91', flag: '🇮🇳')
      ]; // Fallback
    } catch (e) {
      return [
        CountryCode(name: 'India', code: 'IN', prefix: '+91', flag: '🇮🇳')
      ]; // Fallback
    }
  }

  Future<List<Commodity>> getCommodities() async {
    try {
      final response = await _apiClient.post('users/shared/commodities');
      if (response.data != null && response.data['data'] != null) {
        final List list = response.data['data'];
        return list.map((item) => Commodity.fromJson(item)).toList();
      }
      return [
        Commodity(id: '1', webSocketId: 91, name: 'Gold 24KT'),
        Commodity(id: '2', webSocketId: 98, name: 'Silver 999'),
      ]; // Fallback
    } catch (e) {
      return [
        Commodity(id: '1', webSocketId: 91, name: 'Gold 24KT'),
        Commodity(id: '2', webSocketId: 98, name: 'Silver 999'),
      ]; // Fallback
    }
  }

  Future<List<AmountDenomination>> getAmountDenominations() async {
    try {
      final response =
          await _apiClient.post('users/shared/amount-denominations');
      if (response.data != null && response.data['data'] != null) {
        final List list = response.data['data'];
        return list.map((item) => AmountDenomination.fromJson(item)).toList();
      }
      return [
        AmountDenomination(value: 10, isPopular: false),
        AmountDenomination(value: 50, isPopular: false),
        AmountDenomination(value: 100, isPopular: true),
      ]; // Fallback
    } catch (e) {
      return [
        AmountDenomination(value: 10, isPopular: false),
        AmountDenomination(value: 50, isPopular: false),
        AmountDenomination(value: 100, isPopular: true),
      ]; // Fallback
    }
  }
}

final sharedServiceProvider = Provider<SharedService>((ref) => SharedService());

final countryCodesProvider = FutureProvider<List<CountryCode>>((ref) {
  final service = ref.watch(sharedServiceProvider);
  return service.getCountryCodes();
});

final commoditiesProvider = FutureProvider<List<Commodity>>((ref) {
  final service = ref.watch(sharedServiceProvider);
  return service.getCommodities();
});

final amountDenominationsProvider =
    FutureProvider<List<AmountDenomination>>((ref) {
  final service = ref.watch(sharedServiceProvider);
  return service.getAmountDenominations();
});
