// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class IdtyCertMeta {
  const IdtyCertMeta({
    required this.issuedCount,
    required this.nextIssuableOn,
    required this.receivedCount,
  });

  factory IdtyCertMeta.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// u32
  final int issuedCount;

  /// BlockNumber
  final int nextIssuableOn;

  /// u32
  final int receivedCount;

  static const $IdtyCertMetaCodec codec = $IdtyCertMetaCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, int> toJson() => {
        'issuedCount': issuedCount,
        'nextIssuableOn': nextIssuableOn,
        'receivedCount': receivedCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyCertMeta &&
          other.issuedCount == issuedCount &&
          other.nextIssuableOn == nextIssuableOn &&
          other.receivedCount == receivedCount;

  @override
  int get hashCode => Object.hash(
        issuedCount,
        nextIssuableOn,
        receivedCount,
      );
}

class $IdtyCertMetaCodec with _i1.Codec<IdtyCertMeta> {
  const $IdtyCertMetaCodec();

  @override
  void encodeTo(
    IdtyCertMeta obj,
    _i1.Output output,
  ) {
    _i1.U32Codec.codec.encodeTo(
      obj.issuedCount,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.nextIssuableOn,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.receivedCount,
      output,
    );
  }

  @override
  IdtyCertMeta decode(_i1.Input input) {
    return IdtyCertMeta(
      issuedCount: _i1.U32Codec.codec.decode(input),
      nextIssuableOn: _i1.U32Codec.codec.decode(input),
      receivedCount: _i1.U32Codec.codec.decode(input),
    );
  }

  @override
  int sizeHint(IdtyCertMeta obj) {
    int size = 0;
    size = size + _i1.U32Codec.codec.sizeHint(obj.issuedCount);
    size = size + _i1.U32Codec.codec.sizeHint(obj.nextIssuableOn);
    size = size + _i1.U32Codec.codec.sizeHint(obj.receivedCount);
    return size;
  }
}
