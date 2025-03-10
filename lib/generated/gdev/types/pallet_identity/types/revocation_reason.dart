// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

enum RevocationReason {
  root('Root', 0),
  user('User', 1),
  expired('Expired', 2);

  const RevocationReason(
    this.variantName,
    this.codecIndex,
  );

  factory RevocationReason.decode(_i1.Input input) {
    return codec.decode(input);
  }

  final String variantName;

  final int codecIndex;

  static const $RevocationReasonCodec codec = $RevocationReasonCodec();

  String toJson() => variantName;
  _i2.Uint8List encode() {
    return codec.encode(this);
  }
}

class $RevocationReasonCodec with _i1.Codec<RevocationReason> {
  const $RevocationReasonCodec();

  @override
  RevocationReason decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return RevocationReason.root;
      case 1:
        return RevocationReason.user;
      case 2:
        return RevocationReason.expired;
      default:
        throw Exception('RevocationReason: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    RevocationReason value,
    _i1.Output output,
  ) {
    _i1.U8Codec.codec.encodeTo(
      value.codecIndex,
      output,
    );
  }
}
