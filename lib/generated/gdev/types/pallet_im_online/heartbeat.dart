// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class Heartbeat {
  const Heartbeat({
    required this.blockNumber,
    required this.sessionIndex,
    required this.authorityIndex,
    required this.validatorsLen,
  });

  factory Heartbeat.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// BlockNumber
  final int blockNumber;

  /// SessionIndex
  final int sessionIndex;

  /// AuthIndex
  final int authorityIndex;

  /// u32
  final int validatorsLen;

  static const $HeartbeatCodec codec = $HeartbeatCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, int> toJson() => {
        'blockNumber': blockNumber,
        'sessionIndex': sessionIndex,
        'authorityIndex': authorityIndex,
        'validatorsLen': validatorsLen,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Heartbeat &&
          other.blockNumber == blockNumber &&
          other.sessionIndex == sessionIndex &&
          other.authorityIndex == authorityIndex &&
          other.validatorsLen == validatorsLen;

  @override
  int get hashCode => Object.hash(
        blockNumber,
        sessionIndex,
        authorityIndex,
        validatorsLen,
      );
}

class $HeartbeatCodec with _i1.Codec<Heartbeat> {
  const $HeartbeatCodec();

  @override
  void encodeTo(
    Heartbeat obj,
    _i1.Output output,
  ) {
    _i1.U32Codec.codec.encodeTo(
      obj.blockNumber,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.sessionIndex,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.authorityIndex,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.validatorsLen,
      output,
    );
  }

  @override
  Heartbeat decode(_i1.Input input) {
    return Heartbeat(
      blockNumber: _i1.U32Codec.codec.decode(input),
      sessionIndex: _i1.U32Codec.codec.decode(input),
      authorityIndex: _i1.U32Codec.codec.decode(input),
      validatorsLen: _i1.U32Codec.codec.decode(input),
    );
  }

  @override
  int sizeHint(Heartbeat obj) {
    int size = 0;
    size = size + _i1.U32Codec.codec.sizeHint(obj.blockNumber);
    size = size + _i1.U32Codec.codec.sizeHint(obj.sessionIndex);
    size = size + _i1.U32Codec.codec.sizeHint(obj.authorityIndex);
    size = size + _i1.U32Codec.codec.sizeHint(obj.validatorsLen);
    return size;
  }
}
