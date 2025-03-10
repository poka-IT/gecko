// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class AccountData {
  const AccountData({
    required this.free,
    required this.reserved,
    required this.feeFrozen,
    this.linkedIdty,
  });

  factory AccountData.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// Balance
  final BigInt free;

  /// Balance
  final BigInt reserved;

  /// Balance
  final BigInt feeFrozen;

  /// Option<IdtyId>
  final int? linkedIdty;

  static const $AccountDataCodec codec = $AccountDataCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'free': free,
        'reserved': reserved,
        'feeFrozen': feeFrozen,
        'linkedIdty': linkedIdty,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is AccountData &&
          other.free == free &&
          other.reserved == reserved &&
          other.feeFrozen == feeFrozen &&
          other.linkedIdty == linkedIdty;

  @override
  int get hashCode => Object.hash(
        free,
        reserved,
        feeFrozen,
        linkedIdty,
      );
}

class $AccountDataCodec with _i1.Codec<AccountData> {
  const $AccountDataCodec();

  @override
  void encodeTo(
    AccountData obj,
    _i1.Output output,
  ) {
    _i1.U64Codec.codec.encodeTo(
      obj.free,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      obj.reserved,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      obj.feeFrozen,
      output,
    );
    const _i1.OptionCodec<int>(_i1.U32Codec.codec).encodeTo(
      obj.linkedIdty,
      output,
    );
  }

  @override
  AccountData decode(_i1.Input input) {
    return AccountData(
      free: _i1.U64Codec.codec.decode(input),
      reserved: _i1.U64Codec.codec.decode(input),
      feeFrozen: _i1.U64Codec.codec.decode(input),
      linkedIdty: const _i1.OptionCodec<int>(_i1.U32Codec.codec).decode(input),
    );
  }

  @override
  int sizeHint(AccountData obj) {
    int size = 0;
    size = size + _i1.U64Codec.codec.sizeHint(obj.free);
    size = size + _i1.U64Codec.codec.sizeHint(obj.reserved);
    size = size + _i1.U64Codec.codec.sizeHint(obj.feeFrozen);
    size = size +
        const _i1.OptionCodec<int>(_i1.U32Codec.codec).sizeHint(obj.linkedIdty);
    return size;
  }
}
