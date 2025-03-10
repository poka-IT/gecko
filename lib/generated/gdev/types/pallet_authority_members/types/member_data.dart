// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i3;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i4;

import '../../sp_core/crypto/account_id32.dart' as _i2;

class MemberData {
  const MemberData({required this.ownerKey});

  factory MemberData.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// AccountId
  final _i2.AccountId32 ownerKey;

  static const $MemberDataCodec codec = $MemberDataCodec();

  _i3.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, List<int>> toJson() => {'ownerKey': ownerKey.toList()};

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MemberData &&
          _i4.listsEqual(
            other.ownerKey,
            ownerKey,
          );

  @override
  int get hashCode => ownerKey.hashCode;
}

class $MemberDataCodec with _i1.Codec<MemberData> {
  const $MemberDataCodec();

  @override
  void encodeTo(
    MemberData obj,
    _i1.Output output,
  ) {
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.ownerKey,
      output,
    );
  }

  @override
  MemberData decode(_i1.Input input) {
    return MemberData(ownerKey: const _i1.U8ArrayCodec(32).decode(input));
  }

  @override
  int sizeHint(MemberData obj) {
    int size = 0;
    size = size + const _i2.AccountId32Codec().sizeHint(obj.ownerKey);
    return size;
  }
}
