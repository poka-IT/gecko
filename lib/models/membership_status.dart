class MembershipStatus {
  final DateTime? expireDate;
  final bool hasPendingRenewal;
  final DateTime? renewalStartDate;

  MembershipStatus({
    required this.expireDate,
    required this.hasPendingRenewal,
    required this.renewalStartDate,
  });

  static MembershipStatus empty() => MembershipStatus(expireDate: null, hasPendingRenewal: false, renewalStartDate: null);
}
