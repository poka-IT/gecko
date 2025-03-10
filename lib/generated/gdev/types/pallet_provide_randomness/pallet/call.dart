// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../primitive_types/h256.dart' as _i4;
import '../types/randomness_type.dart' as _i3;

/// Contains a variant per dispatchable extrinsic that this pallet has.
abstract class Call {
  const Call();

  factory Call.decode(_i1.Input input) {
    return codec.decode(input);
  }

  static const $CallCodec codec = $CallCodec();

  static const $Call values = $Call();

  _i2.Uint8List encode() {
    final output = _i1.ByteOutput(codec.sizeHint(this));
    codec.encodeTo(this, output);
    return output.toBytes();
  }

  int sizeHint() {
    return codec.sizeHint(this);
  }

  Map<String, Map<String, dynamic>> toJson();
}

class $Call {
  const $Call();

  Request request({
    required _i3.RandomnessType randomnessType,
    required _i4.H256 salt,
  }) {
    return Request(
      randomnessType: randomnessType,
      salt: salt,
    );
  }
}

class $CallCodec with _i1.Codec<Call> {
  const $CallCodec();

  @override
  Call decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return Request._decode(input);
      default:
        throw Exception('Call: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Call value,
    _i1.Output output,
  ) {
    switch (value.runtimeType) {
      case Request:
        (value as Request).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case Request:
        return (value as Request)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Request randomness.
class Request extends Call {
  const Request({
    required this.randomnessType,
    required this.salt,
  });

  factory Request._decode(_i1.Input input) {
    return Request(
      randomnessType: _i3.RandomnessType.codec.decode(input),
      salt: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// RandomnessType
  final _i3.RandomnessType randomnessType;

  /// H256
  final _i4.H256 salt;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'request': {
          'randomnessType': randomnessType.toJson(),
          'salt': salt.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i3.RandomnessType.codec.sizeHint(randomnessType);
    size = size + const _i4.H256Codec().sizeHint(salt);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i3.RandomnessType.codec.encodeTo(
      randomnessType,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      salt,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Request &&
          other.randomnessType == randomnessType &&
          _i5.listsEqual(
            other.salt,
            salt,
          );

  @override
  int get hashCode => Object.hash(
        randomnessType,
        salt,
      );
}
