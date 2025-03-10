// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../sp_core/crypto/account_id32.dart' as _i4;
import '../../sp_distance/computation_result.dart' as _i3;

/// Contains a variant per dispatchable extrinsic that this pallet has.
abstract class Call {
  const Call();

  factory Call.decode(_i1.Input input) {
    return codec.decode(input);
  }

  static const $CallCodec codec = $CallCodec();

  static const $Call values = $Call();

  _i2.Uint8List encode() {
    final output = _i1.ByteOutput(codec.sizeHint(this));
    codec.encodeTo(this, output);
    return output.toBytes();
  }

  int sizeHint() {
    return codec.sizeHint(this);
  }

  Map<String, dynamic> toJson();
}

class $Call {
  const $Call();

  RequestDistanceEvaluation requestDistanceEvaluation() {
    return RequestDistanceEvaluation();
  }

  RequestDistanceEvaluationFor requestDistanceEvaluationFor(
      {required int target}) {
    return RequestDistanceEvaluationFor(target: target);
  }

  UpdateEvaluation updateEvaluation(
      {required _i3.ComputationResult computationResult}) {
    return UpdateEvaluation(computationResult: computationResult);
  }

  ForceUpdateEvaluation forceUpdateEvaluation({
    required _i4.AccountId32 evaluator,
    required _i3.ComputationResult computationResult,
  }) {
    return ForceUpdateEvaluation(
      evaluator: evaluator,
      computationResult: computationResult,
    );
  }

  ForceValidDistanceStatus forceValidDistanceStatus({required int identity}) {
    return ForceValidDistanceStatus(identity: identity);
  }
}

class $CallCodec with _i1.Codec<Call> {
  const $CallCodec();

  @override
  Call decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return const RequestDistanceEvaluation();
      case 4:
        return RequestDistanceEvaluationFor._decode(input);
      case 1:
        return UpdateEvaluation._decode(input);
      case 2:
        return ForceUpdateEvaluation._decode(input);
      case 3:
        return ForceValidDistanceStatus._decode(input);
      default:
        throw Exception('Call: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Call value,
    _i1.Output output,
  ) {
    switch (value.runtimeType) {
      case RequestDistanceEvaluation:
        (value as RequestDistanceEvaluation).encodeTo(output);
        break;
      case RequestDistanceEvaluationFor:
        (value as RequestDistanceEvaluationFor).encodeTo(output);
        break;
      case UpdateEvaluation:
        (value as UpdateEvaluation).encodeTo(output);
        break;
      case ForceUpdateEvaluation:
        (value as ForceUpdateEvaluation).encodeTo(output);
        break;
      case ForceValidDistanceStatus:
        (value as ForceValidDistanceStatus).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case RequestDistanceEvaluation:
        return 1;
      case RequestDistanceEvaluationFor:
        return (value as RequestDistanceEvaluationFor)._sizeHint();
      case UpdateEvaluation:
        return (value as UpdateEvaluation)._sizeHint();
      case ForceUpdateEvaluation:
        return (value as ForceUpdateEvaluation)._sizeHint();
      case ForceValidDistanceStatus:
        return (value as ForceValidDistanceStatus)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Request evaluation of the caller's identity distance.
///
/// This function allows the caller to request an evaluation of their distance.
/// A positive evaluation will lead to claiming or renewing membership, while a negative
/// evaluation will result in slashing for the caller.
class RequestDistanceEvaluation extends Call {
  const RequestDistanceEvaluation();

  @override
  Map<String, dynamic> toJson() => {'request_distance_evaluation': null};

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
  }

  @override
  bool operator ==(Object other) => other is RequestDistanceEvaluation;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Request evaluation of a target identity's distance.
///
/// This function allows the caller to request an evaluation of a specific target identity's distance.
/// This action is only permitted for unvalidated identities.
class RequestDistanceEvaluationFor extends Call {
  const RequestDistanceEvaluationFor({required this.target});

  factory RequestDistanceEvaluationFor._decode(_i1.Input input) {
    return RequestDistanceEvaluationFor(
        target: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int target;

  @override
  Map<String, Map<String, int>> toJson() => {
        'request_distance_evaluation_for': {'target': target}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(target);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      4,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      target,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is RequestDistanceEvaluationFor && other.target == target;

  @override
  int get hashCode => target.hashCode;
}

/// Push an evaluation result to the pool.
///
/// This inherent function is called internally by validators to push an evaluation result
/// to the evaluation pool.
class UpdateEvaluation extends Call {
  const UpdateEvaluation({required this.computationResult});

  factory UpdateEvaluation._decode(_i1.Input input) {
    return UpdateEvaluation(
        computationResult: _i3.ComputationResult.codec.decode(input));
  }

  /// ComputationResult
  final _i3.ComputationResult computationResult;

  @override
  Map<String, Map<String, Map<String, List<int>>>> toJson() => {
        'update_evaluation': {'computationResult': computationResult.toJson()}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i3.ComputationResult.codec.sizeHint(computationResult);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i3.ComputationResult.codec.encodeTo(
      computationResult,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is UpdateEvaluation && other.computationResult == computationResult;

  @override
  int get hashCode => computationResult.hashCode;
}

/// Force push an evaluation result to the pool.
///
/// It is primarily used for testing purposes.
///
/// - `origin`: Must be `Root`.
class ForceUpdateEvaluation extends Call {
  const ForceUpdateEvaluation({
    required this.evaluator,
    required this.computationResult,
  });

  factory ForceUpdateEvaluation._decode(_i1.Input input) {
    return ForceUpdateEvaluation(
      evaluator: const _i1.U8ArrayCodec(32).decode(input),
      computationResult: _i3.ComputationResult.codec.decode(input),
    );
  }

  /// <T as frame_system::Config>::AccountId
  final _i4.AccountId32 evaluator;

  /// ComputationResult
  final _i3.ComputationResult computationResult;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'force_update_evaluation': {
          'evaluator': evaluator.toList(),
          'computationResult': computationResult.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i4.AccountId32Codec().sizeHint(evaluator);
    size = size + _i3.ComputationResult.codec.sizeHint(computationResult);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      evaluator,
      output,
    );
    _i3.ComputationResult.codec.encodeTo(
      computationResult,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ForceUpdateEvaluation &&
          _i5.listsEqual(
            other.evaluator,
            evaluator,
          ) &&
          other.computationResult == computationResult;

  @override
  int get hashCode => Object.hash(
        evaluator,
        computationResult,
      );
}

/// Force set the distance evaluation status of an identity.
///
/// It is primarily used for testing purposes.
///
/// - `origin`: Must be `Root`.
class ForceValidDistanceStatus extends Call {
  const ForceValidDistanceStatus({required this.identity});

  factory ForceValidDistanceStatus._decode(_i1.Input input) {
    return ForceValidDistanceStatus(identity: _i1.U32Codec.codec.decode(input));
  }

  /// <T as pallet_identity::Config>::IdtyIndex
  final int identity;

  @override
  Map<String, Map<String, int>> toJson() => {
        'force_valid_distance_status': {'identity': identity}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(identity);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      identity,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ForceValidDistanceStatus && other.identity == identity;

  @override
  int get hashCode => identity.hashCode;
}
