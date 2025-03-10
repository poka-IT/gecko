// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

enum RandomnessType {
  randomnessFromPreviousBlock('RandomnessFromPreviousBlock', 0),
  randomnessFromOneEpochAgo('RandomnessFromOneEpochAgo', 1),
  randomnessFromTwoEpochsAgo('RandomnessFromTwoEpochsAgo', 2);

  const RandomnessType(
    this.variantName,
    this.codecIndex,
  );

  factory RandomnessType.decode(_i1.Input input) {
    return codec.decode(input);
  }

  final String variantName;

  final int codecIndex;

  static const $RandomnessTypeCodec codec = $RandomnessTypeCodec();

  String toJson() => variantName;
  _i2.Uint8List encode() {
    return codec.encode(this);
  }
}

class $RandomnessTypeCodec with _i1.Codec<RandomnessType> {
  const $RandomnessTypeCodec();

  @override
  RandomnessType decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return RandomnessType.randomnessFromPreviousBlock;
      case 1:
        return RandomnessType.randomnessFromOneEpochAgo;
      case 2:
        return RandomnessType.randomnessFromTwoEpochsAgo;
      default:
        throw Exception('RandomnessType: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    RandomnessType value,
    _i1.Output output,
  ) {
    _i1.U8Codec.codec.encodeTo(
      value.codecIndex,
      output,
    );
  }
}
