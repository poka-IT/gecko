// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Block height is in the future.
  blockHeightInFuture('BlockHeightInFuture', 0),

  /// Block height is too old.
  blockHeightTooOld('BlockHeightTooOld', 1),

  /// Destination account does not exist.
  destAccountNotExist('DestAccountNotExist', 2),

  /// Destination account has a balance less than the existential deposit.
  existentialDeposit('ExistentialDeposit', 3),

  /// Source account has insufficient balance.
  insufficientBalance('InsufficientBalance', 4),

  /// Destination oneshot account already exists.
  oneshotAccountAlreadyCreated('OneshotAccountAlreadyCreated', 5),

  /// Source oneshot account does not exist.
  oneshotAccountNotExist('OneshotAccountNotExist', 6);

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
        return Error.blockHeightInFuture;
      case 1:
        return Error.blockHeightTooOld;
      case 2:
        return Error.destAccountNotExist;
      case 3:
        return Error.existentialDeposit;
      case 4:
        return Error.insufficientBalance;
      case 5:
        return Error.oneshotAccountAlreadyCreated;
      case 6:
        return Error.oneshotAccountNotExist;
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
