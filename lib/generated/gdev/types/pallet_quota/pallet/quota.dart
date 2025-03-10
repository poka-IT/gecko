// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class Quota {
  const Quota({
    required this.lastUse,
    required this.amount,
  });

  factory Quota.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// BlockNumber
  final int lastUse;

  /// Balance
  final BigInt amount;

  static const $QuotaCodec codec = $QuotaCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'lastUse': lastUse,
        'amount': amount,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Quota && other.lastUse == lastUse && other.amount == amount;

  @override
  int get hashCode => Object.hash(
        lastUse,
        amount,
      );
}

class $QuotaCodec with _i1.Codec<Quota> {
  const $QuotaCodec();

  @override
  void encodeTo(
    Quota obj,
    _i1.Output output,
  ) {
    _i1.U32Codec.codec.encodeTo(
      obj.lastUse,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      obj.amount,
      output,
    );
  }

  @override
  Quota decode(_i1.Input input) {
    return Quota(
      lastUse: _i1.U32Codec.codec.decode(input),
      amount: _i1.U64Codec.codec.decode(input),
    );
  }

  @override
  int sizeHint(Quota obj) {
    int size = 0;
    size = size + _i1.U32Codec.codec.sizeHint(obj.lastUse);
    size = size + _i1.U64Codec.codec.sizeHint(obj.amount);
    return size;
  }
}
