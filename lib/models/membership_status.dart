import 'package:gecko/models/wallet_data.dart';

class MembershipStatus {
  final DateTime? expireDate;
  final bool hasPendingRenewal;
  final DateTime? renewalStartDate;
  final IdtyStatus idtyStatus;

  MembershipStatus({
    required this.expireDate,
    required this.hasPendingRenewal,
    required this.renewalStartDate,
    required this.idtyStatus,
  });

  static MembershipStatus empty() => MembershipStatus(expireDate: null, hasPendingRenewal: false, renewalStartDate: null, idtyStatus: IdtyStatus.none);
}
