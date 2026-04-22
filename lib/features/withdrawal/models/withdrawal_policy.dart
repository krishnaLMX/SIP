/// Model for POST /withdrawal/policy response.
class WithdrawalPolicy {
  final WithdrawalLimits limits;
  final WithdrawalValidation validation;
  final UserEligibility userEligibility;

  const WithdrawalPolicy({
    required this.limits,
    required this.validation,
    required this.userEligibility,
  });

  factory WithdrawalPolicy.fromJson(Map<String, dynamic> json) {
    return WithdrawalPolicy(
      limits: WithdrawalLimits.fromJson(
          (json['limits'] as Map<String, dynamic>?) ?? {}),
      validation: WithdrawalValidation.fromJson(
          (json['validation'] as Map<String, dynamic>?) ?? {}),
      userEligibility: UserEligibility.fromJson(
          (json['user_eligibility'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

class WithdrawalLimits {
  final double minWithdrawal;
  final double maxWithdrawal;
  final double minPurchaseRequired;
  final int dailyLimit;
  final bool sameDayLock;

  const WithdrawalLimits({
    this.minWithdrawal = 0,
    this.maxWithdrawal = 0,
    this.minPurchaseRequired = 0,
    this.dailyLimit = 1,
    this.sameDayLock = false,
  });

  factory WithdrawalLimits.fromJson(Map<String, dynamic> json) {
    return WithdrawalLimits(
      minWithdrawal:
          double.tryParse(json['min_withdrawal']?.toString() ?? '0') ?? 0,
      maxWithdrawal:
          double.tryParse(json['max_withdrawal']?.toString() ?? '0') ?? 0,
      minPurchaseRequired:
          double.tryParse(json['min_purchase_required']?.toString() ?? '0') ??
              0,
      dailyLimit: (json['daily_limit'] as int?) ?? 1,
      sameDayLock: json['same_day_lock'] == true,
    );
  }
}

class WithdrawalValidation {
  final bool isValid;
  final String amount;
  final String? message;

  const WithdrawalValidation({
    this.isValid = true,
    this.amount = '0',
    this.message,
  });

  factory WithdrawalValidation.fromJson(Map<String, dynamic> json) {
    return WithdrawalValidation(
      isValid: json['is_valid'] == true,
      amount: json['amount']?.toString() ?? '0',
      message: json['message']?.toString(),
    );
  }
}

class UserEligibility {
  final bool isEligible;
  final String? message;

  const UserEligibility({
    this.isEligible = true,
    this.message,
  });

  factory UserEligibility.fromJson(Map<String, dynamic> json) {
    return UserEligibility(
      isEligible: json['is_eligible'] == true,
      message: json['message']?.toString(),
    );
  }
}
