// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Swap already exists.
  alreadyExist('AlreadyExist', 0),

  /// Swap proof is invalid.
  invalidProof('InvalidProof', 1),

  /// Proof is too large.
  proofTooLarge('ProofTooLarge', 2),

  /// Source does not match.
  sourceMismatch('SourceMismatch', 3),

  /// Swap has already been claimed.
  alreadyClaimed('AlreadyClaimed', 4),

  /// Swap does not exist.
  notExist('NotExist', 5),

  /// Claim action mismatch.
  claimActionMismatch('ClaimActionMismatch', 6),

  /// Duration has not yet passed for the swap to be cancelled.
  durationNotPassed('DurationNotPassed', 7);

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
        return Error.alreadyExist;
      case 1:
        return Error.invalidProof;
      case 2:
        return Error.proofTooLarge;
      case 3:
        return Error.sourceMismatch;
      case 4:
        return Error.alreadyClaimed;
      case 5:
        return Error.notExist;
      case 6:
        return Error.claimActionMismatch;
      case 7:
        return Error.durationNotPassed;
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
