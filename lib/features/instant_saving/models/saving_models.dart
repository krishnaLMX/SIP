class SavingConfig {
  final double kycLimit;
  final double minAmount;
  final double maxAmount;

  SavingConfig({
    required this.kycLimit,
    required this.minAmount,
    required this.maxAmount,
  });

  factory SavingConfig.fromJson(Map<String, dynamic> json) {
    return SavingConfig(
      kycLimit: (json['kyc_limit'] ?? 0).toDouble(),
      minAmount: (json['min_amount'] ?? 0).toDouble(),
      maxAmount: (json['max_amount'] ?? 0).toDouble(),
    );
  }

  factory SavingConfig.defaultConfig() => SavingConfig(
        kycLimit: 50000,
        minAmount: 10,
        maxAmount: 200000,
      );
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class PaymentOrder {
  final String paymentUrl;
  final String orderId;

  PaymentOrder({
    required this.paymentUrl,
    required this.orderId,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      paymentUrl: json['payment_url'] ?? '',
      orderId: json['order_id'] ?? '',
    );
  }
}

class EligibilityResponse {
  final String nextStep; // KYC_REQUIRED or PAYMENT

  EligibilityResponse({required this.nextStep});

  factory EligibilityResponse.fromJson(Map<String, dynamic> json) {
    return EligibilityResponse(
      nextStep: json['next_step'] ?? 'PAYMENT',
    );
  }
}

class PurchaseInitiateResponse {
  final String? transactionId;
  final String? paymentToken;
  final double? orderAmount;
  final String? message;

  PurchaseInitiateResponse({
    this.transactionId,
    this.paymentToken,
    this.orderAmount,
    this.message,
  });

  factory PurchaseInitiateResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseInitiateResponse(
      transactionId: json['transaction_id'],
      paymentToken: json['payment_token'],
      orderAmount: (json['order_amount'] ?? 0).toDouble(),
      message: json['message'],
    );
  }
}
