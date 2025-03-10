// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Issuer of anything (invitation, acceptance, certification) must have an identity ID
  originMustHaveAnIdentity('OriginMustHaveAnIdentity', 0),

  /// Issuer must be known as a potential smith
  originHasNeverBeenInvited('OriginHasNeverBeenInvited', 1),

  /// Invitation is reseverd to smiths
  invitationIsASmithPrivilege('InvitationIsASmithPrivilege', 2),

  /// Invitation is reseverd to online smiths
  invitationIsAOnlineSmithPrivilege('InvitationIsAOnlineSmithPrivilege', 3),

  /// Invitation must not have been accepted yet
  invitationAlreadyAccepted('InvitationAlreadyAccepted', 4),

  /// Invitation of an already known smith is forbidden except if it has been excluded
  invitationOfExistingNonExcluded('InvitationOfExistingNonExcluded', 5),

  /// Invitation of a non-member (of the WoT) is forbidden
  invitationOfNonMember('InvitationOfNonMember', 6),

  /// Certification cannot be made on someone who has not accepted an invitation
  certificationMustBeAgreed('CertificationMustBeAgreed', 7),

  /// Certification cannot be made on excluded
  certificationOnExcludedIsForbidden('CertificationOnExcludedIsForbidden', 8),

  /// Issuer must be a smith
  certificationIsASmithPrivilege('CertificationIsASmithPrivilege', 9),

  /// Only online smiths can certify
  certificationIsAOnlineSmithPrivilege(
      'CertificationIsAOnlineSmithPrivilege', 10),

  /// Smith cannot certify itself
  certificationOfSelfIsForbidden('CertificationOfSelfIsForbidden', 11),

  /// Receiver must be invited by another smith
  certificationReceiverMustHaveBeenInvited(
      'CertificationReceiverMustHaveBeenInvited', 12),

  /// Receiver must not already have this certification
  certificationAlreadyExists('CertificationAlreadyExists', 13),

  /// A smith has a limited stock of certifications
  certificationStockFullyConsumed('CertificationStockFullyConsumed', 14);

  const Error(
    this.variantName,
    this.codecIndex,
  );

  factory Error.decode(_i1.Input input) {
    return codec.decode(input);
  }

  final String variantName;

  final int codecIndex;

  static const $ErrorCodec codec = $ErrorCodec();

  String toJson() => variantName;
  _i2.Uint8List encode() {
    return codec.encode(this);
  }
}

class $ErrorCodec with _i1.Codec<Error> {
  const $ErrorCodec();

  @override
  Error decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return Error.originMustHaveAnIdentity;
      case 1:
        return Error.originHasNeverBeenInvited;
      case 2:
        return Error.invitationIsASmithPrivilege;
      case 3:
        return Error.invitationIsAOnlineSmithPrivilege;
      case 4:
        return Error.invitationAlreadyAccepted;
      case 5:
        return Error.invitationOfExistingNonExcluded;
      case 6:
        return Error.invitationOfNonMember;
      case 7:
        return Error.certificationMustBeAgreed;
      case 8:
        return Error.certificationOnExcludedIsForbidden;
      case 9:
        return Error.certificationIsASmithPrivilege;
      case 10:
        return Error.certificationIsAOnlineSmithPrivilege;
      case 11:
        return Error.certificationOfSelfIsForbidden;
      case 12:
        return Error.certificationReceiverMustHaveBeenInvited;
      case 13:
        return Error.certificationAlreadyExists;
      case 14:
        return Error.certificationStockFullyConsumed;
      default:
        throw Exception('Error: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Error value,
    _i1.Output output,
  ) {
    _i1.U8Codec.codec.encodeTo(
      value.codecIndex,
      output,
    );
  }
}
