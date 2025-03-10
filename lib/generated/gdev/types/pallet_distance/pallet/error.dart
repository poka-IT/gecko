// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Distance is already under evaluation.
  alreadyInEvaluation('AlreadyInEvaluation', 0),

  /// Too many evaluations requested by author.
  tooManyEvaluationsByAuthor('TooManyEvaluationsByAuthor', 1),

  /// Too many evaluations for this block.
  tooManyEvaluationsInBlock('TooManyEvaluationsInBlock', 2),

  /// No author for this block.
  noAuthor('NoAuthor', 3),

  /// Caller has no identity.
  callerHasNoIdentity('CallerHasNoIdentity', 4),

  /// Caller identity not found.
  callerIdentityNotFound('CallerIdentityNotFound', 5),

  /// Caller not member.
  callerNotMember('CallerNotMember', 6),
  callerStatusInvalid('CallerStatusInvalid', 7),

  /// Target identity not found.
  targetIdentityNotFound('TargetIdentityNotFound', 8),

  /// Evaluation queue is full.
  queueFull('QueueFull', 9),

  /// Too many evaluators in the current evaluation pool.
  tooManyEvaluators('TooManyEvaluators', 10),

  /// Evaluation result has a wrong length.
  wrongResultLength('WrongResultLength', 11),

  /// Targeted distance evaluation request is only possible for an unvalidated identity.
  targetMustBeUnvalidated('TargetMustBeUnvalidated', 12);

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
        return Error.alreadyInEvaluation;
      case 1:
        return Error.tooManyEvaluationsByAuthor;
      case 2:
        return Error.tooManyEvaluationsInBlock;
      case 3:
        return Error.noAuthor;
      case 4:
        return Error.callerHasNoIdentity;
      case 5:
        return Error.callerIdentityNotFound;
      case 6:
        return Error.callerNotMember;
      case 7:
        return Error.callerStatusInvalid;
      case 8:
        return Error.targetIdentityNotFound;
      case 9:
        return Error.queueFull;
      case 10:
        return Error.tooManyEvaluators;
      case 11:
        return Error.wrongResultLength;
      case 12:
        return Error.targetMustBeUnvalidated;
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
