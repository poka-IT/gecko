// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../primitive_types/h256.dart' as _i3;
import '../types/randomness_type.dart' as _i4;

/// The `Event` enum of this pallet
abstract class Event {
  const Event();

  factory Event.decode(_i1.Input input) {
    return codec.decode(input);
  }

  static const $EventCodec codec = $EventCodec();

  static const $Event values = $Event();

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

class $Event {
  const $Event();

  FilledRandomness filledRandomness({
    required BigInt requestId,
    required _i3.H256 randomness,
  }) {
    return FilledRandomness(
      requestId: requestId,
      randomness: randomness,
    );
  }

  RequestedRandomness requestedRandomness({
    required BigInt requestId,
    required _i3.H256 salt,
    required _i4.RandomnessType type,
  }) {
    return RequestedRandomness(
      requestId: requestId,
      salt: salt,
      type: type,
    );
  }
}

class $EventCodec with _i1.Codec<Event> {
  const $EventCodec();

  @override
  Event decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return FilledRandomness._decode(input);
      case 1:
        return RequestedRandomness._decode(input);
      default:
        throw Exception('Event: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Event value,
    _i1.Output output,
  ) {
    switch (value.runtimeType) {
      case FilledRandomness:
        (value as FilledRandomness).encodeTo(output);
        break;
      case RequestedRandomness:
        (value as RequestedRandomness).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case FilledRandomness:
        return (value as FilledRandomness)._sizeHint();
      case RequestedRandomness:
        return (value as RequestedRandomness)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A request for randomness was fulfilled.
class FilledRandomness extends Event {
  const FilledRandomness({
    required this.requestId,
    required this.randomness,
  });

  factory FilledRandomness._decode(_i1.Input input) {
    return FilledRandomness(
      requestId: _i1.U64Codec.codec.decode(input),
      randomness: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// RequestId
  final BigInt requestId;

  /// H256
  final _i3.H256 randomness;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'FilledRandomness': {
          'requestId': requestId,
          'randomness': randomness.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U64Codec.codec.sizeHint(requestId);
    size = size + const _i3.H256Codec().sizeHint(randomness);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      requestId,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      randomness,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is FilledRandomness &&
          other.requestId == requestId &&
          _i5.listsEqual(
            other.randomness,
            randomness,
          );

  @override
  int get hashCode => Object.hash(
        requestId,
        randomness,
      );
}

/// A request for randomness was made.
class RequestedRandomness extends Event {
  const RequestedRandomness({
    required this.requestId,
    required this.salt,
    required this.type,
  });

  factory RequestedRandomness._decode(_i1.Input input) {
    return RequestedRandomness(
      requestId: _i1.U64Codec.codec.decode(input),
      salt: const _i1.U8ArrayCodec(32).decode(input),
      type: _i4.RandomnessType.codec.decode(input),
    );
  }

  /// RequestId
  final BigInt requestId;

  /// H256
  final _i3.H256 salt;

  /// RandomnessType
  final _i4.RandomnessType type;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'RequestedRandomness': {
          'requestId': requestId,
          'salt': salt.toList(),
          'r#type': type.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U64Codec.codec.sizeHint(requestId);
    size = size + const _i3.H256Codec().sizeHint(salt);
    size = size + _i4.RandomnessType.codec.sizeHint(type);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      requestId,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      salt,
      output,
    );
    _i4.RandomnessType.codec.encodeTo(
      type,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is RequestedRandomness &&
          other.requestId == requestId &&
          _i5.listsEqual(
            other.salt,
            salt,
          ) &&
          other.type == type;

  @override
  int get hashCode => Object.hash(
        requestId,
        salt,
        type,
      );
}
