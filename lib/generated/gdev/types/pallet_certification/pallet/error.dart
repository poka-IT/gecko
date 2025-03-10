// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Issuer of a certification must have an identity
  originMustHaveAnIdentity('OriginMustHaveAnIdentity', 0),

  /// Identity cannot certify itself.
  cannotCertifySelf('CannotCertifySelf', 1),

  /// Identity has already issued the maximum number of certifications.
  issuedTooManyCert('IssuedTooManyCert', 2),

  /// Insufficient certifications received.
  notEnoughCertReceived('NotEnoughCertReceived', 3),

  /// Identity has issued a certification too recently.
  notRespectCertPeriod('NotRespectCertPeriod', 4),

  /// Can not add an already-existing cert
  certAlreadyExists('CertAlreadyExists', 5),

  /// Can not renew a non-existing cert
  certDoesNotExist('CertDoesNotExist', 6);

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
        return Error.cannotCertifySelf;
      case 2:
        return Error.issuedTooManyCert;
      case 3:
        return Error.notEnoughCertReceived;
      case 4:
        return Error.notRespectCertPeriod;
      case 5:
        return Error.certAlreadyExists;
      case 6:
        return Error.certDoesNotExist;
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
