import 'package:gecko/models/wallet_data.dart' as wallet_data;
import 'package:gecko/generated/gdev/types/pallet_identity/types/idty_status.dart' as idty_status;

class MembershipStatusDeprecated {
  final DateTime? expireDate;
  final bool hasPendingRenewal;
  final DateTime? renewalStartDate;
  final wallet_data.IdtyStatus idtyStatus;

  MembershipStatusDeprecated({
    required this.expireDate,
    required this.hasPendingRenewal,
    required this.renewalStartDate,
    required this.idtyStatus,
  });

  static MembershipStatusDeprecated empty() =>
      MembershipStatusDeprecated(expireDate: null, hasPendingRenewal: false, renewalStartDate: null, idtyStatus: wallet_data.IdtyStatus.none);
}

class MembershipStatus {
  final DateTime? expireDate;
  final bool hasPendingRenewal;
  final DateTime? renewalStartDate;
  final idty_status.IdtyStatus? idtyStatus;

  MembershipStatus({
    required this.expireDate,
    required this.hasPendingRenewal,
    required this.renewalStartDate,
    required this.idtyStatus,
  });

  static MembershipStatus empty() => MembershipStatus(expireDate: null, hasPendingRenewal: false, renewalStartDate: null, idtyStatus: null);
}
