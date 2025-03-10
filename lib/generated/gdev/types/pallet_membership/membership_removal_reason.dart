// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

enum MembershipRemovalReason {
  expired('Expired', 0),
  revoked('Revoked', 1),
  notEnoughCerts('NotEnoughCerts', 2),
  system('System', 3);

  const MembershipRemovalReason(
    this.variantName,
    this.codecIndex,
  );

  factory MembershipRemovalReason.decode(_i1.Input input) {
    return codec.decode(input);
  }

  final String variantName;

  final int codecIndex;

  static const $MembershipRemovalReasonCodec codec =
      $MembershipRemovalReasonCodec();

  String toJson() => variantName;
  _i2.Uint8List encode() {
    return codec.encode(this);
  }
}

class $MembershipRemovalReasonCodec with _i1.Codec<MembershipRemovalReason> {
  const $MembershipRemovalReasonCodec();

  @override
  MembershipRemovalReason decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return MembershipRemovalReason.expired;
      case 1:
        return MembershipRemovalReason.revoked;
      case 2:
        return MembershipRemovalReason.notEnoughCerts;
      case 3:
        return MembershipRemovalReason.system;
      default:
        throw Exception(
            'MembershipRemovalReason: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    MembershipRemovalReason value,
    _i1.Output output,
  ) {
    _i1.U8Codec.codec.encodeTo(
      value.codecIndex,
      output,
    );
  }
}
