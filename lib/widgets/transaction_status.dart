import 'package:easy_localization/easy_localization.dart';

enum TransactionStatus { sending, propagation, validating, failed, success, timeout, finalized, none }

Map<String, String> actionMap = {
  'pay': 'transaction'.tr(),
  'cert': 'certification'.tr(),
  'comfirmIdty': 'identityConfirm'.tr(),
  'revokeIdty': 'revokeAdhesion'.tr(),
  'identityMigration': 'identityMigration'.tr(),
  'renewMembership': 'renewingMembership'.tr(),
};

Map<TransactionStatus, String> statusStatusMap = {
  TransactionStatus.none: 'noTransaction'.tr(),
  TransactionStatus.sending: 'sending'.tr(),
  TransactionStatus.propagation: 'propagating'.tr(),
  TransactionStatus.validating: 'validating'.tr(),
  TransactionStatus.success: 'extrinsicValidated'.tr(args: [actionMap['pay']!]),
  TransactionStatus.finalized: 'extrinsicFinalized'.tr(args: [actionMap['pay']!]),
  TransactionStatus.timeout: 'execTimeoutOver'.tr(),
};

Map<String, String> errorTransactionMap = {
  'cert.NotRespectCertPeriod': '24hbetweenCerts'.tr(),
  'identity.CreatorNotAllowedToCreateIdty': '24hbetweenCerts'.tr(),
  'cert.CannotCertifySelf': 'canNotCertifySelf'.tr(),
  'identity.IdtyNameAlreadyExist': 'nameAlreadyExist'.tr(),
  'balances.KeepAlive': '2GDtoKeepAlive'.tr(),
  '1010: Invalid Transaction: Inability to pay some fees , e.g. account balance too low': 'youHaveToFeedThisAccountBeforeUsing'.tr(),
  'Token.FundsUnavailable': 'fundsUnavailable'.tr(),
  'wot.MembershipRenewalPeriodNotRespected': 'membershipRenewalPeriodNotRespected'.tr(),
};
