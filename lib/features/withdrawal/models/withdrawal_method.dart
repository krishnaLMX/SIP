class WithdrawalMethod {
  final String id;
  final String identifier; // upi_id or account_no
  final String title; // bank_name or holder_name
  final String? subtitle; // ifsc or additional info
  final bool isUpi;
  final bool isVerified;

  WithdrawalMethod({
    required this.id,
    required this.identifier,
    required this.title,
    this.subtitle,
    this.isUpi = true,
    this.isVerified = false,
  });

  factory WithdrawalMethod.fromJson(Map<String, dynamic> json) {
    final bool isUpi = json['upi_id'] != null || json['upi_handle'] != null;
    return WithdrawalMethod(
      id: json['id_payout']?.toString() ?? json['id_upi']?.toString() ?? json['id']?.toString() ?? '',
      identifier: json['upi_id'] ?? json['account_no'] ?? json['upi_handle'] ?? '',
      title: json['bank_name'] ?? json['holder_name'] ?? (isUpi ? 'UPI' : 'Bank Account'),
      subtitle: json['ifsc_code'] ?? json['ifsc'],
      isUpi: isUpi,
      isVerified: json['is_verified'] == true || json['status'] == 'verified',
    );
  }
}

