// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

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

  CertAdded certAdded({
    required int issuer,
    required int receiver,
  }) {
    return CertAdded(
      issuer: issuer,
      receiver: receiver,
    );
  }

  CertRemoved certRemoved({
    required int issuer,
    required int receiver,
    required bool expiration,
  }) {
    return CertRemoved(
      issuer: issuer,
      receiver: receiver,
      expiration: expiration,
    );
  }

  CertRenewed certRenewed({
    required int issuer,
    required int receiver,
  }) {
    return CertRenewed(
      issuer: issuer,
      receiver: receiver,
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
        return CertAdded._decode(input);
      case 1:
        return CertRemoved._decode(input);
      case 2:
        return CertRenewed._decode(input);
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
      case CertAdded:
        (value as CertAdded).encodeTo(output);
        break;
      case CertRemoved:
        (value as CertRemoved).encodeTo(output);
        break;
      case CertRenewed:
        (value as CertRenewed).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case CertAdded:
        return (value as CertAdded)._sizeHint();
      case CertRemoved:
        return (value as CertRemoved)._sizeHint();
      case CertRenewed:
        return (value as CertRenewed)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A new certification was added.
class CertAdded extends Event {
  const CertAdded({
    required this.issuer,
    required this.receiver,
  });

  factory CertAdded._decode(_i1.Input input) {
    return CertAdded(
      issuer: _i1.U32Codec.codec.decode(input),
      receiver: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int issuer;

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'CertAdded': {
          'issuer': issuer,
          'receiver': receiver,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(issuer);
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      issuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      receiver,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is CertAdded &&
          other.issuer == issuer &&
          other.receiver == receiver;

  @override
  int get hashCode => Object.hash(
        issuer,
        receiver,
      );
}

/// A certification was removed.
class CertRemoved extends Event {
  const CertRemoved({
    required this.issuer,
    required this.receiver,
    required this.expiration,
  });

  factory CertRemoved._decode(_i1.Input input) {
    return CertRemoved(
      issuer: _i1.U32Codec.codec.decode(input),
      receiver: _i1.U32Codec.codec.decode(input),
      expiration: _i1.BoolCodec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int issuer;

  /// T::IdtyIndex
  final int receiver;

  /// bool
  final bool expiration;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'CertRemoved': {
          'issuer': issuer,
          'receiver': receiver,
          'expiration': expiration,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(issuer);
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    size = size + _i1.BoolCodec.codec.sizeHint(expiration);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      issuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      receiver,
      output,
    );
    _i1.BoolCodec.codec.encodeTo(
      expiration,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is CertRemoved &&
          other.issuer == issuer &&
          other.receiver == receiver &&
          other.expiration == expiration;

  @override
  int get hashCode => Object.hash(
        issuer,
        receiver,
        expiration,
      );
}

/// A certification was renewed.
class CertRenewed extends Event {
  const CertRenewed({
    required this.issuer,
    required this.receiver,
  });

  factory CertRenewed._decode(_i1.Input input) {
    return CertRenewed(
      issuer: _i1.U32Codec.codec.decode(input),
      receiver: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int issuer;

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'CertRenewed': {
          'issuer': issuer,
          'receiver': receiver,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(issuer);
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      issuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      receiver,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is CertRenewed &&
          other.issuer == issuer &&
          other.receiver == receiver;

  @override
  int get hashCode => Object.hash(
        issuer,
        receiver,
      );
}
