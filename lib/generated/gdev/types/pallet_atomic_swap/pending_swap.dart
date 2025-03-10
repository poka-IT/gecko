// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i4;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../sp_core/crypto/account_id32.dart' as _i2;
import 'balance_swap_action.dart' as _i3;

class PendingSwap {
  const PendingSwap({
    required this.source,
    required this.action,
    required this.endBlock,
  });

  factory PendingSwap.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// T::AccountId
  final _i2.AccountId32 source;

  /// T::SwapAction
  final _i3.BalanceSwapAction action;

  /// BlockNumberFor<T>
  final int endBlock;

  static const $PendingSwapCodec codec = $PendingSwapCodec();

  _i4.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'source': source.toList(),
        'action': action.toJson(),
        'endBlock': endBlock,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is PendingSwap &&
          _i5.listsEqual(
            other.source,
            source,
          ) &&
          other.action == action &&
          other.endBlock == endBlock;

  @override
  int get hashCode => Object.hash(
        source,
        action,
        endBlock,
      );
}

class $PendingSwapCodec with _i1.Codec<PendingSwap> {
  const $PendingSwapCodec();

  @override
  void encodeTo(
    PendingSwap obj,
    _i1.Output output,
  ) {
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.source,
      output,
    );
    _i3.BalanceSwapAction.codec.encodeTo(
      obj.action,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.endBlock,
      output,
    );
  }

  @override
  PendingSwap decode(_i1.Input input) {
    return PendingSwap(
      source: const _i1.U8ArrayCodec(32).decode(input),
      action: _i3.BalanceSwapAction.codec.decode(input),
      endBlock: _i1.U32Codec.codec.decode(input),
    );
  }

  @override
  int sizeHint(PendingSwap obj) {
    int size = 0;
    size = size + const _i2.AccountId32Codec().sizeHint(obj.source);
    size = size + _i3.BalanceSwapAction.codec.sizeHint(obj.action);
    size = size + _i1.U32Codec.codec.sizeHint(obj.endBlock);
    return size;
  }
}
