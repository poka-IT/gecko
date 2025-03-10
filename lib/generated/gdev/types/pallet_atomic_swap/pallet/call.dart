// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../sp_core/crypto/account_id32.dart' as _i3;
import '../balance_swap_action.dart' as _i4;

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

  Map<String, Map<String, dynamic>> toJson();
}

class $Call {
  const $Call();

  CreateSwap createSwap({
    required _i3.AccountId32 target,
    required List<int> hashedProof,
    required _i4.BalanceSwapAction action,
    required int duration,
  }) {
    return CreateSwap(
      target: target,
      hashedProof: hashedProof,
      action: action,
      duration: duration,
    );
  }

  ClaimSwap claimSwap({
    required List<int> proof,
    required _i4.BalanceSwapAction action,
  }) {
    return ClaimSwap(
      proof: proof,
      action: action,
    );
  }

  CancelSwap cancelSwap({
    required _i3.AccountId32 target,
    required List<int> hashedProof,
  }) {
    return CancelSwap(
      target: target,
      hashedProof: hashedProof,
    );
  }
}

class $CallCodec with _i1.Codec<Call> {
  const $CallCodec();

  @override
  Call decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return CreateSwap._decode(input);
      case 1:
        return ClaimSwap._decode(input);
      case 2:
        return CancelSwap._decode(input);
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
      case CreateSwap:
        (value as CreateSwap).encodeTo(output);
        break;
      case ClaimSwap:
        (value as ClaimSwap).encodeTo(output);
        break;
      case CancelSwap:
        (value as CancelSwap).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case CreateSwap:
        return (value as CreateSwap)._sizeHint();
      case ClaimSwap:
        return (value as ClaimSwap)._sizeHint();
      case CancelSwap:
        return (value as CancelSwap)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Register a new atomic swap, declaring an intention to send funds from origin to target
/// on the current blockchain. The target can claim the fund using the revealed proof. If
/// the fund is not claimed after `duration` blocks, then the sender can cancel the swap.
///
/// The dispatch origin for this call must be _Signed_.
///
/// - `target`: Receiver of the atomic swap.
/// - `hashed_proof`: The blake2_256 hash of the secret proof.
/// - `balance`: Funds to be sent from origin.
/// - `duration`: Locked duration of the atomic swap. For safety reasons, it is recommended
///  that the revealer uses a shorter duration than the counterparty, to prevent the
///  situation where the revealer reveals the proof too late around the end block.
class CreateSwap extends Call {
  const CreateSwap({
    required this.target,
    required this.hashedProof,
    required this.action,
    required this.duration,
  });

  factory CreateSwap._decode(_i1.Input input) {
    return CreateSwap(
      target: const _i1.U8ArrayCodec(32).decode(input),
      hashedProof: const _i1.U8ArrayCodec(32).decode(input),
      action: _i4.BalanceSwapAction.codec.decode(input),
      duration: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 target;

  /// HashedProof
  final List<int> hashedProof;

  /// T::SwapAction
  final _i4.BalanceSwapAction action;

  /// BlockNumberFor<T>
  final int duration;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'create_swap': {
          'target': target.toList(),
          'hashedProof': hashedProof.toList(),
          'action': action.toJson(),
          'duration': duration,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(target);
    size = size + const _i1.U8ArrayCodec(32).sizeHint(hashedProof);
    size = size + _i4.BalanceSwapAction.codec.sizeHint(action);
    size = size + _i1.U32Codec.codec.sizeHint(duration);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      target,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      hashedProof,
      output,
    );
    _i4.BalanceSwapAction.codec.encodeTo(
      action,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      duration,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is CreateSwap &&
          _i5.listsEqual(
            other.target,
            target,
          ) &&
          _i5.listsEqual(
            other.hashedProof,
            hashedProof,
          ) &&
          other.action == action &&
          other.duration == duration;

  @override
  int get hashCode => Object.hash(
        target,
        hashedProof,
        action,
        duration,
      );
}

/// Claim an atomic swap.
///
/// The dispatch origin for this call must be _Signed_.
///
/// - `proof`: Revealed proof of the claim.
/// - `action`: Action defined in the swap, it must match the entry in blockchain. Otherwise
///  the operation fails. This is used for weight calculation.
class ClaimSwap extends Call {
  const ClaimSwap({
    required this.proof,
    required this.action,
  });

  factory ClaimSwap._decode(_i1.Input input) {
    return ClaimSwap(
      proof: _i1.U8SequenceCodec.codec.decode(input),
      action: _i4.BalanceSwapAction.codec.decode(input),
    );
  }

  /// Vec<u8>
  final List<int> proof;

  /// T::SwapAction
  final _i4.BalanceSwapAction action;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'claim_swap': {
          'proof': proof,
          'action': action.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U8SequenceCodec.codec.sizeHint(proof);
    size = size + _i4.BalanceSwapAction.codec.sizeHint(action);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U8SequenceCodec.codec.encodeTo(
      proof,
      output,
    );
    _i4.BalanceSwapAction.codec.encodeTo(
      action,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ClaimSwap &&
          _i5.listsEqual(
            other.proof,
            proof,
          ) &&
          other.action == action;

  @override
  int get hashCode => Object.hash(
        proof,
        action,
      );
}

/// Cancel an atomic swap. Only possible after the originally set duration has passed.
///
/// The dispatch origin for this call must be _Signed_.
///
/// - `target`: Target of the original atomic swap.
/// - `hashed_proof`: Hashed proof of the original atomic swap.
class CancelSwap extends Call {
  const CancelSwap({
    required this.target,
    required this.hashedProof,
  });

  factory CancelSwap._decode(_i1.Input input) {
    return CancelSwap(
      target: const _i1.U8ArrayCodec(32).decode(input),
      hashedProof: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 target;

  /// HashedProof
  final List<int> hashedProof;

  @override
  Map<String, Map<String, List<int>>> toJson() => {
        'cancel_swap': {
          'target': target.toList(),
          'hashedProof': hashedProof.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(target);
    size = size + const _i1.U8ArrayCodec(32).sizeHint(hashedProof);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      target,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      hashedProof,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is CancelSwap &&
          _i5.listsEqual(
            other.target,
            target,
          ) &&
          _i5.listsEqual(
            other.hashedProof,
            hashedProof,
          );

  @override
  int get hashCode => Object.hash(
        target,
        hashedProof,
      );
}
