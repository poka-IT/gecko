// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i3;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i4;

import '../../primitive_types/h256.dart' as _i2;

class Request {
  const Request({
    required this.requestId,
    required this.salt,
  });

  factory Request.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// RequestId
  final BigInt requestId;

  /// H256
  final _i2.H256 salt;

  static const $RequestCodec codec = $RequestCodec();

  _i3.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'salt': salt.toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Request &&
          other.requestId == requestId &&
          _i4.listsEqual(
            other.salt,
            salt,
          );

  @override
  int get hashCode => Object.hash(
        requestId,
        salt,
      );
}

class $RequestCodec with _i1.Codec<Request> {
  const $RequestCodec();

  @override
  void encodeTo(
    Request obj,
    _i1.Output output,
  ) {
    _i1.U64Codec.codec.encodeTo(
      obj.requestId,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.salt,
      output,
    );
  }

  @override
  Request decode(_i1.Input input) {
    return Request(
      requestId: _i1.U64Codec.codec.decode(input),
      salt: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  @override
  int sizeHint(Request obj) {
    int size = 0;
    size = size + _i1.U64Codec.codec.sizeHint(obj.requestId);
    size = size + const _i2.H256Codec().sizeHint(obj.salt);
    return size;
  }
}
