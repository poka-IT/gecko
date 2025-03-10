// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Identity already confirmed.
  idtyAlreadyConfirmed('IdtyAlreadyConfirmed', 0),

  /// Identity already created.
  idtyAlreadyCreated('IdtyAlreadyCreated', 1),

  /// Identity index not found.
  idtyIndexNotFound('IdtyIndexNotFound', 2),

  /// Identity name already exists.
  idtyNameAlreadyExist('IdtyNameAlreadyExist', 3),

  /// Invalid identity name.
  idtyNameInvalid('IdtyNameInvalid', 4),

  /// Identity not found.
  idtyNotFound('IdtyNotFound', 5),

  /// Invalid payload signature.
  invalidSignature('InvalidSignature', 6),

  /// Invalid revocation key.
  invalidRevocationKey('InvalidRevocationKey', 7),

  /// Issuer is not member and can not perform this action.
  issuerNotMember('IssuerNotMember', 8),

  /// Identity creation period is not respected.
  notRespectIdtyCreationPeriod('NotRespectIdtyCreationPeriod', 9),

  /// Owner key already changed recently.
  ownerKeyAlreadyRecentlyChanged('OwnerKeyAlreadyRecentlyChanged', 10),

  /// Owner key already used.
  ownerKeyAlreadyUsed('OwnerKeyAlreadyUsed', 11),

  /// Reverting to an old key is prohibited.
  prohibitedToRevertToAnOldKey('ProhibitedToRevertToAnOldKey', 12),

  /// Already revoked.
  alreadyRevoked('AlreadyRevoked', 13),

  /// Can not revoke identity that never was member.
  canNotRevokeUnconfirmed('CanNotRevokeUnconfirmed', 14),

  /// Can not revoke identity that never was member.
  canNotRevokeUnvalidated('CanNotRevokeUnvalidated', 15),

  /// Cannot link to an inexisting account.
  accountNotExist('AccountNotExist', 16),

  /// Insufficient balance to create an identity.
  insufficientBalance('InsufficientBalance', 17),

  /// Owner key currently used as validator.
  ownerKeyUsedAsValidator('OwnerKeyUsedAsValidator', 18);

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
        return Error.idtyAlreadyConfirmed;
      case 1:
        return Error.idtyAlreadyCreated;
      case 2:
        return Error.idtyIndexNotFound;
      case 3:
        return Error.idtyNameAlreadyExist;
      case 4:
        return Error.idtyNameInvalid;
      case 5:
        return Error.idtyNotFound;
      case 6:
        return Error.invalidSignature;
      case 7:
        return Error.invalidRevocationKey;
      case 8:
        return Error.issuerNotMember;
      case 9:
        return Error.notRespectIdtyCreationPeriod;
      case 10:
        return Error.ownerKeyAlreadyRecentlyChanged;
      case 11:
        return Error.ownerKeyAlreadyUsed;
      case 12:
        return Error.prohibitedToRevertToAnOldKey;
      case 13:
        return Error.alreadyRevoked;
      case 14:
        return Error.canNotRevokeUnconfirmed;
      case 15:
        return Error.canNotRevokeUnvalidated;
      case 16:
        return Error.accountNotExist;
      case 17:
        return Error.insufficientBalance;
      case 18:
        return Error.ownerKeyUsedAsValidator;
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
