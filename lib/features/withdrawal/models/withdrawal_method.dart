class WithdrawalMethod {
  final String id;
  final String upiId;
  final String bankName;
  final bool isVerified;

  WithdrawalMethod({
    required this.id,
    required this.upiId,
    required this.bankName,
    this.isVerified = false,
  });
}
