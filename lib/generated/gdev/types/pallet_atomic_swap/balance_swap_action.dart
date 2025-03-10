// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class BalanceSwapAction {
  const BalanceSwapAction({required this.value});

  factory BalanceSwapAction.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// <C as Currency<AccountId>>::Balance
  final BigInt value;

  static const $BalanceSwapActionCodec codec = $BalanceSwapActionCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, BigInt> toJson() => {'value': value};

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is BalanceSwapAction && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class $BalanceSwapActionCodec with _i1.Codec<BalanceSwapAction> {
  const $BalanceSwapActionCodec();

  @override
  void encodeTo(
    BalanceSwapAction obj,
    _i1.Output output,
  ) {
    _i1.U64Codec.codec.encodeTo(
      obj.value,
      output,
    );
  }

  @override
  BalanceSwapAction decode(_i1.Input input) {
    return BalanceSwapAction(value: _i1.U64Codec.codec.decode(input));
  }

  @override
  int sizeHint(BalanceSwapAction obj) {
    int size = 0;
    size = size + _i1.U64Codec.codec.sizeHint(obj.value);
    return size;
  }
}
