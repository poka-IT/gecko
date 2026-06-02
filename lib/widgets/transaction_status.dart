import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';

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
  TransactionState.retrying: 'retrying'.tr(),
};

Map<String, String> errorTransactionMap = {
  'cert.NotRespectCertPeriod': '24hbetweenCerts'.tr(),
  'identity.CreatorNotAllowedToCreateIdty': '24hbetweenCerts'.tr(),
  'identity.CanNotRevokeUnvalidated': 'canNotRevokeUnvalidated'.tr(),
  'cert.CannotCertifySelf': 'canNotCertifySelf'.tr(),
  'identity.IdtyNameAlreadyExist': 'nameAlreadyExist'.tr(),
  'identity.OwnerKeyInBound': 'ownerKeyInBound'.tr(),
  'identity.OwnerKeyAlreadyRecentlyChanged': 'ownerKeyAlreadyRecentlyChanged'.tr(),
  'identity.OwnerKeyUsedAsValidator': 'ownerKeyUsedAsValidator'.tr(),
  'balances.KeepAlive': '2GDtoKeepAlive'.tr(args: [Durt.i.network.symbol]),
  '1010: Invalid Transaction: Inability to pay some fees , e.g. account balance too low':
      'youHaveToFeedThisAccountBeforeUsing'.tr(),
  'Token.FundsUnavailable': 'fundsUnavailable'.tr(),
  'wot.MembershipRenewalPeriodNotRespected': 'membershipRenewalPeriodNotRespected'.tr(),
  'identity.InsufficientBalance': 'identityInsufficientBalance'.tr(),
  'Transaction is temporarily banned': 'transactionTemporarilyBanned'.tr(),
  'Transaction Already Imported': 'transactionAlreadyImported'.tr(),
  'cert.CertNotAllowed': 'certNotAllowed'.tr(),
  'cert.CannotCertifyExpiredMembership': 'cannotCertifyExpiredMembership'.tr(),
  'cert.InvalidCert': 'invalidCert'.tr(),
  'identity.IdtyNotFound': 'idtyNotFound'.tr(),
  'identity.NotAllowedToChangeIdtyAddress': 'notAllowedToChangeIdtyAddress'.tr(),
  'identity.NotAllowedToRemoveIdty': 'notAllowedToRemoveIdty'.tr(),
  'identity.IdtyAlreadyConfirmed': 'idtyAlreadyConfirmed'.tr(),
  'identity.IdtyAlreadyCreated': 'idtyAlreadyCreated'.tr(),
  'identity.IdtyNotValidated': 'idtyNotValidated'.tr(),
  'membership.MembershipNotFound': 'membershipNotFound'.tr(),
  'wot.NotEnoughCerts': 'notEnoughCertsForMembership'.tr(),
  'cert.NotEnoughCertReceived': 'notEnoughCertReceived'.tr(),
  'wot.TargetStatusInvalid': 'targetStatusInvalid'.tr(),
  'wot.IssuerNotMember': 'issuerNotMember'.tr(),
  'cert.IssuedTooManyCert': 'issuedTooManyCert'.tr(),
  'cert.CertAlreadyExists': 'certAlreadyExists'.tr(),
  'cert.CertDoesNotExist': 'certDoesNotExist'.tr(),
  'cert.OriginMustHaveAnIdentity': 'originMustHaveAnIdentity'.tr(),
  'wot.IdtyNotFound': 'idtyNotFound'.tr(),
  'wot.NotEnoughReceivedCertsToCreateIdty': 'notEnoughCertsToCreateIdty'.tr(),
  'wot.MaxEmittedCertsReached': 'issuedTooManyCert'.tr(),
  'wot.IdtyCreationPeriodNotRespected': 'idtyCreationPeriodNotRespected'.tr(),
  'distance.CallerStatusInvalid': 'callerStatusInvalid'.tr(),
  'distance.AlreadyInEvaluation': 'alreadyInEvaluation'.tr(),
  'distance.QueueFull': 'evaluationQueueFull'.tr(),
  'distance.TargetMustBeUnvalidated': 'targetMustBeUnvalidated'.tr(),
  // Distance evaluation can be triggered by membership renewal; surface the
  // remaining variants with clear messages instead of a raw technical error.
  'distance.TooManyEvaluationsInBlock': 'distanceEvaluationBusy'.tr(),
  'distance.TooManyEvaluationsByAuthor': 'distanceEvaluationBusy'.tr(),
  'distance.TooManyEvaluators': 'distanceEvaluationBusy'.tr(),
  'distance.NoAuthor': 'distanceEvaluationBusy'.tr(),
  'distance.CallerNotMember': 'issuerNotMember'.tr(),
  'distance.CallerHasNoIdentity': 'originMustHaveAnIdentity'.tr(),
  'distance.CallerIdentityNotFound': 'idtyNotFound'.tr(),
  'distance.TargetIdentityNotFound': 'idtyNotFound'.tr(),
  'membership.AlreadyMember': 'alreadyMember'.tr(),
  'universalDividend.AccountNotAllowedToClaimUds': 'accountNotAllowedToClaim'.tr(),
  'balances.InsufficientBalance': 'fundsUnavailable'.tr(),
  'Priority is too low': 'transactionPriorityTooLow'.tr(),
};

/// Lookup a transaction error message, trying exact match first then substring match.
String? lookupTransactionError(String? errorMessage) {
  if (errorMessage == null) return null;
  // Try exact match first
  final exact = errorTransactionMap[errorMessage];
  if (exact != null) return exact;
  // Fall back to substring match
  for (final entry in errorTransactionMap.entries) {
    if (errorMessage.contains(entry.key)) return entry.value;
  }
  // Log unmapped errors for future discovery
  log.w('Unmapped transaction error: $errorMessage');
  return null;
}
