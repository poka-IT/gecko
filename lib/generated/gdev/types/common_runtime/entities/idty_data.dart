// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class IdtyData {
  const IdtyData({required this.firstEligibleUd});

  factory IdtyData.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// pallet_universal_dividend::FirstEligibleUd
  final int firstEligibleUd;

  static const $IdtyDataCodec codec = $IdtyDataCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, int> toJson() => {'firstEligibleUd': firstEligibleUd};

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyData && other.firstEligibleUd == firstEligibleUd;

  @override
  int get hashCode => firstEligibleUd.hashCode;
}

class $IdtyDataCodec with _i1.Codec<IdtyData> {
  const $IdtyDataCodec();

  @override
  void encodeTo(
    IdtyData obj,
    _i1.Output output,
  ) {
    _i1.U16Codec.codec.encodeTo(
      obj.firstEligibleUd,
      output,
    );
  }

  @override
  IdtyData decode(_i1.Input input) {
    return IdtyData(firstEligibleUd: _i1.U16Codec.codec.decode(input));
  }

  @override
  int sizeHint(IdtyData obj) {
    int size = 0;
    size = size + _i1.U16Codec.codec.sizeHint(obj.firstEligibleUd);
    return size;
  }
}
