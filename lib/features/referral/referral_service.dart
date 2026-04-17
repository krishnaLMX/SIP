import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:startgold/core/network/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class ReferralData {
  final String referralCode;
  final int totalReferrals;
  final double totalEarned;
  final String rewardAmount;
  final String shareLink;
  /// Dynamic hero title shown in the header.
  /// e.g. "Invite a friend and earn ₹100 worth of Gold."
  final String title;
  /// Dynamic bullet points shown below the title.
  final List<String> bulletPoints;

  const ReferralData({
    required this.referralCode,
    required this.totalReferrals,
    required this.totalEarned,
    required this.rewardAmount,
    required this.shareLink,
    required this.title,
    required this.bulletPoints,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    // Parse bullet_points: array of objects {content: "..."} or plain strings
    final rawBullets = json['bullet_points'];
    List<String> bullets = [];
    if (rawBullets is List) {
      for (final item in rawBullets) {
        if (item is Map && item['content'] != null) {
          bullets.add(item['content'].toString());
        } else if (item is String) {
          bullets.add(item);
        }
      }
    }

    return ReferralData(
      referralCode: json['referral_code']?.toString() ?? '',
      totalReferrals:
          int.tryParse(json['total_referrals']?.toString() ?? '0') ?? 0,
      totalEarned:
          double.tryParse(json['total_earned']?.toString() ?? '0') ?? 0,
      rewardAmount: json['reward_amount']?.toString() ?? '',
      shareLink: json['share_link']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      bulletPoints: bullets,
    );
  }

  static const empty = ReferralData(
    referralCode: '',
    totalReferrals: 0,
    totalEarned: 0,
    rewardAmount: '',
    shareLink: '',
    title: '',
    bulletPoints: [],
  );
}

// ── Service ───────────────────────────────────────────────────────────────────
class ReferralService {
  final ApiClient _apiClient = ApiClient();

  Future<ReferralData> fetchReferralData() async {
    try {
      final response =
          await _apiClient.post('users/auth/referral/details', data: {});
      final body = response.data;

      debugPrint('═══ REFERRAL/DATA STATUS: ${response.statusCode} ═══');
      debugPrint('═══ REFERRAL/DATA BODY: $body ═══');

      if (body == null) return ReferralData.empty;

      if (body is Map<String, dynamic>) {
        if (body['success'] == false) {
          debugPrint('REFERRAL: success=false → ${body['message']}');
          return ReferralData.empty;
        }
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return ReferralData.fromJson(data);
        }
      }
      return ReferralData.empty;
    } catch (e, st) {
      debugPrint('REFERRAL/DATA ERROR: $e\n$st');
      return ReferralData.empty;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final referralServiceProvider =
    Provider<ReferralService>((ref) => ReferralService());

final referralDataProvider = FutureProvider<ReferralData>((ref) {
  return ref.read(referralServiceProvider).fetchReferralData();
});
