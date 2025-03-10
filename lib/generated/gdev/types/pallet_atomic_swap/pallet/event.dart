// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../sp_core/crypto/account_id32.dart' as _i3;
import '../pending_swap.dart' as _i4;

/// Event of atomic swap pallet.
abstract class Event {
  const Event();

  factory Event.decode(_i1.Input input) {
    return codec.decode(input);
  }

  static const $EventCodec codec = $EventCodec();

  static const $Event values = $Event();

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

class $Event {
  const $Event();

  NewSwap newSwap({
    required _i3.AccountId32 account,
    required List<int> proof,
    required _i4.PendingSwap swap,
  }) {
    return NewSwap(
      account: account,
      proof: proof,
      swap: swap,
    );
  }

  SwapClaimed swapClaimed({
    required _i3.AccountId32 account,
    required List<int> proof,
    required bool success,
  }) {
    return SwapClaimed(
      account: account,
      proof: proof,
      success: success,
    );
  }

  SwapCancelled swapCancelled({
    required _i3.AccountId32 account,
    required List<int> proof,
  }) {
    return SwapCancelled(
      account: account,
      proof: proof,
    );
  }
}

class $EventCodec with _i1.Codec<Event> {
  const $EventCodec();

  @override
  Event decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return NewSwap._decode(input);
      case 1:
        return SwapClaimed._decode(input);
      case 2:
        return SwapCancelled._decode(input);
      default:
        throw Exception('Event: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Event value,
    _i1.Output output,
  ) {
    switch (value.runtimeType) {
      case NewSwap:
        (value as NewSwap).encodeTo(output);
        break;
      case SwapClaimed:
        (value as SwapClaimed).encodeTo(output);
        break;
      case SwapCancelled:
        (value as SwapCancelled).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case NewSwap:
        return (value as NewSwap)._sizeHint();
      case SwapClaimed:
        return (value as SwapClaimed)._sizeHint();
      case SwapCancelled:
        return (value as SwapCancelled)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Swap created.
class NewSwap extends Event {
  const NewSwap({
    required this.account,
    required this.proof,
    required this.swap,
  });

  factory NewSwap._decode(_i1.Input input) {
    return NewSwap(
      account: const _i1.U8ArrayCodec(32).decode(input),
      proof: const _i1.U8ArrayCodec(32).decode(input),
      swap: _i4.PendingSwap.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 account;

  /// HashedProof
  final List<int> proof;

  /// PendingSwap<T>
  final _i4.PendingSwap swap;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'NewSwap': {
          'account': account.toList(),
          'proof': proof.toList(),
          'swap': swap.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(account);
    size = size + const _i1.U8ArrayCodec(32).sizeHint(proof);
    size = size + _i4.PendingSwap.codec.sizeHint(swap);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      account,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      proof,
      output,
    );
    _i4.PendingSwap.codec.encodeTo(
      swap,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is NewSwap &&
          _i5.listsEqual(
            other.account,
            account,
          ) &&
          _i5.listsEqual(
            other.proof,
            proof,
          ) &&
          other.swap == swap;

  @override
  int get hashCode => Object.hash(
        account,
        proof,
        swap,
      );
}

/// Swap claimed. The last parameter indicates whether the execution succeeds.
class SwapClaimed extends Event {
  const SwapClaimed({
    required this.account,
    required this.proof,
    required this.success,
  });

  factory SwapClaimed._decode(_i1.Input input) {
    return SwapClaimed(
      account: const _i1.U8ArrayCodec(32).decode(input),
      proof: const _i1.U8ArrayCodec(32).decode(input),
      success: _i1.BoolCodec.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 account;

  /// HashedProof
  final List<int> proof;

  /// bool
  final bool success;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'SwapClaimed': {
          'account': account.toList(),
          'proof': proof.toList(),
          'success': success,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(account);
    size = size + const _i1.U8ArrayCodec(32).sizeHint(proof);
    size = size + _i1.BoolCodec.codec.sizeHint(success);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      account,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      proof,
      output,
    );
    _i1.BoolCodec.codec.encodeTo(
      success,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SwapClaimed &&
          _i5.listsEqual(
            other.account,
            account,
          ) &&
          _i5.listsEqual(
            other.proof,
            proof,
          ) &&
          other.success == success;

  @override
  int get hashCode => Object.hash(
        account,
        proof,
        success,
      );
}

/// Swap cancelled.
class SwapCancelled extends Event {
  const SwapCancelled({
    required this.account,
    required this.proof,
  });

  factory SwapCancelled._decode(_i1.Input input) {
    return SwapCancelled(
      account: const _i1.U8ArrayCodec(32).decode(input),
      proof: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 account;

  /// HashedProof
  final List<int> proof;

  @override
  Map<String, Map<String, List<int>>> toJson() => {
        'SwapCancelled': {
          'account': account.toList(),
          'proof': proof.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(account);
    size = size + const _i1.U8ArrayCodec(32).sizeHint(proof);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      account,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      proof,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SwapCancelled &&
          _i5.listsEqual(
            other.account,
            account,
          ) &&
          _i5.listsEqual(
            other.proof,
            proof,
          );

  @override
  int get hashCode => Object.hash(
        account,
        proof,
      );
}
