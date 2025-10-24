import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';

Map<String, String> actionMap = {
  'pay': 'transaction'.tr(),
  'cert': 'certification'.tr(),
  'comfirmIdty': 'identityConfirm'.tr(),
  'revokeIdty': 'revokeAdhesion'.tr(),
  'identityMigration': 'identityMigration'.tr(),
  'renewMembership': 'renewingMembership'.tr(),
  'accountMigration': 'accountMigration'.tr(),
};

Map<TransactionState, String> statusStatusMap = {
  TransactionState.none: 'noTransaction'.tr(),
  TransactionState.pending: 'sending'.tr(),
  TransactionState.inBlock: 'extrinsicValidated'.tr(args: [actionMap['pay']!]),
  TransactionState.finalized: 'extrinsicFinalized'.tr(args: [actionMap['pay']!]),
  TransactionState.timeout: 'execTimeoutOver'.tr(),
};

Map<String, String> errorTransactionMap = {
  'cert.NotRespectCertPeriod': '24hbetweenCerts'.tr(),
  'identity.CreatorNotAllowedToCreateIdty': '24hbetweenCerts'.tr(),
  'identity.CanNotRevokeUnvalidated': 'canNotRevokeUnvalidated'.tr(),
  'cert.CannotCertifySelf': 'canNotCertifySelf'.tr(),
  'identity.IdtyNameAlreadyExist': 'nameAlreadyExist'.tr(),
  'identity.OwnerKeyInBound': 'ownerKeyInBound'.tr(),
  'balances.KeepAlive': '2GDtoKeepAlive'.tr(args: [Durt.i.network.symbol]),
  '1010: Invalid Transaction: Inability to pay some fees , e.g. account balance too low':
      'youHaveToFeedThisAccountBeforeUsing'.tr(),
  'Token.FundsUnavailable': 'fundsUnavailable'.tr(),
  'wot.MembershipRenewalPeriodNotRespected': 'membershipRenewalPeriodNotRespected'.tr(),
};
