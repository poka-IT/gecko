// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Insufficient certifications received.
  notEnoughCerts('NotEnoughCerts', 0),

  /// Target status is incompatible with this operation.
  targetStatusInvalid('TargetStatusInvalid', 1),

  /// Identity creation period not respected.
  idtyCreationPeriodNotRespected('IdtyCreationPeriodNotRespected', 2),

  /// Insufficient received certifications to create identity.
  notEnoughReceivedCertsToCreateIdty('NotEnoughReceivedCertsToCreateIdty', 3),

  /// Maximum number of emitted certifications reached.
  maxEmittedCertsReached('MaxEmittedCertsReached', 4),

  /// Issuer cannot emit a certification because it is not member.
  issuerNotMember('IssuerNotMember', 5),

  /// Issuer or receiver not found.
  idtyNotFound('IdtyNotFound', 6),

  /// Membership can only be renewed after an antispam delay.
  membershipRenewalPeriodNotRespected('MembershipRenewalPeriodNotRespected', 7);

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
        return Error.notEnoughCerts;
      case 1:
        return Error.targetStatusInvalid;
      case 2:
        return Error.idtyCreationPeriodNotRespected;
      case 3:
        return Error.notEnoughReceivedCertsToCreateIdty;
      case 4:
        return Error.maxEmittedCertsReached;
      case 5:
        return Error.issuerNotMember;
      case 6:
        return Error.idtyNotFound;
      case 7:
        return Error.membershipRenewalPeriodNotRespected;
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
