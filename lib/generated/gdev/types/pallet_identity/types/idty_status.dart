// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

enum IdtyStatus {
  unconfirmed('Unconfirmed', 0),
  unvalidated('Unvalidated', 1),
  member('Member', 2),
  notMember('NotMember', 3),
  revoked('Revoked', 4);

  const IdtyStatus(
    this.variantName,
    this.codecIndex,
  );

  factory IdtyStatus.decode(_i1.Input input) {
    return codec.decode(input);
  }

  final String variantName;

  final int codecIndex;

  static const $IdtyStatusCodec codec = $IdtyStatusCodec();

  String toJson() => variantName;
  _i2.Uint8List encode() {
    return codec.encode(this);
  }
}

class $IdtyStatusCodec with _i1.Codec<IdtyStatus> {
  const $IdtyStatusCodec();

  @override
  IdtyStatus decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return IdtyStatus.unconfirmed;
      case 1:
        return IdtyStatus.unvalidated;
      case 2:
        return IdtyStatus.member;
      case 3:
        return IdtyStatus.notMember;
      case 4:
        return IdtyStatus.revoked;
      default:
        throw Exception('IdtyStatus: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    IdtyStatus value,
    _i1.Output output,
  ) {
    _i1.U8Codec.codec.encodeTo(
      value.codecIndex,
      output,
    );
  }
}
