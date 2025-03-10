// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class MembershipData {
  const MembershipData({required this.expireOn});

  factory MembershipData.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// BlockNumber
  final int expireOn;

  static const $MembershipDataCodec codec = $MembershipDataCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, int> toJson() => {'expireOn': expireOn};

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MembershipData && other.expireOn == expireOn;

  @override
  int get hashCode => expireOn.hashCode;
}

class $MembershipDataCodec with _i1.Codec<MembershipData> {
  const $MembershipDataCodec();

  @override
  void encodeTo(
    MembershipData obj,
    _i1.Output output,
  ) {
    _i1.U32Codec.codec.encodeTo(
      obj.expireOn,
      output,
    );
  }

  @override
  MembershipData decode(_i1.Input input) {
    return MembershipData(expireOn: _i1.U32Codec.codec.decode(input));
  }

  @override
  int sizeHint(MembershipData obj) {
    int size = 0;
    size = size + _i1.U32Codec.codec.sizeHint(obj.expireOn);
    return size;
  }
}
