class MembershipStatus {
  final DateTime? expireDate;
  final bool hasPendingRenewal;

  const MembershipStatus({
    required this.expireDate,
    required this.hasPendingRenewal,
  });
}
