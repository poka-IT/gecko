// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../sp_arithmetic/per_things/perbill.dart' as _i4;
import '../../sp_core/crypto/account_id32.dart' as _i3;

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

  EvaluationRequested evaluationRequested({
    required int idtyIndex,
    required _i3.AccountId32 who,
  }) {
    return EvaluationRequested(
      idtyIndex: idtyIndex,
      who: who,
    );
  }

  EvaluatedValid evaluatedValid({
    required int idtyIndex,
    required _i4.Perbill distance,
  }) {
    return EvaluatedValid(
      idtyIndex: idtyIndex,
      distance: distance,
    );
  }

  EvaluatedInvalid evaluatedInvalid({
    required int idtyIndex,
    required _i4.Perbill distance,
  }) {
    return EvaluatedInvalid(
      idtyIndex: idtyIndex,
      distance: distance,
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
        return EvaluationRequested._decode(input);
      case 1:
        return EvaluatedValid._decode(input);
      case 2:
        return EvaluatedInvalid._decode(input);
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
      case EvaluationRequested:
        (value as EvaluationRequested).encodeTo(output);
        break;
      case EvaluatedValid:
        (value as EvaluatedValid).encodeTo(output);
        break;
      case EvaluatedInvalid:
        (value as EvaluatedInvalid).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case EvaluationRequested:
        return (value as EvaluationRequested)._sizeHint();
      case EvaluatedValid:
        return (value as EvaluatedValid)._sizeHint();
      case EvaluatedInvalid:
        return (value as EvaluatedInvalid)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A distance evaluation was requested.
class EvaluationRequested extends Event {
  const EvaluationRequested({
    required this.idtyIndex,
    required this.who,
  });

  factory EvaluationRequested._decode(_i1.Input input) {
    return EvaluationRequested(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      who: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// T::AccountId
  final _i3.AccountId32 who;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'EvaluationRequested': {
          'idtyIndex': idtyIndex,
          'who': who.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + const _i3.AccountId32Codec().sizeHint(who);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      who,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is EvaluationRequested &&
          other.idtyIndex == idtyIndex &&
          _i5.listsEqual(
            other.who,
            who,
          );

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        who,
      );
}

/// Distance rule was found valid.
class EvaluatedValid extends Event {
  const EvaluatedValid({
    required this.idtyIndex,
    required this.distance,
  });

  factory EvaluatedValid._decode(_i1.Input input) {
    return EvaluatedValid(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      distance: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// Perbill
  final _i4.Perbill distance;

  @override
  Map<String, Map<String, int>> toJson() => {
        'EvaluatedValid': {
          'idtyIndex': idtyIndex,
          'distance': distance,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + const _i4.PerbillCodec().sizeHint(distance);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      distance,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is EvaluatedValid &&
          other.idtyIndex == idtyIndex &&
          other.distance == distance;

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        distance,
      );
}

/// Distance rule was found invalid.
class EvaluatedInvalid extends Event {
  const EvaluatedInvalid({
    required this.idtyIndex,
    required this.distance,
  });

  factory EvaluatedInvalid._decode(_i1.Input input) {
    return EvaluatedInvalid(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      distance: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// Perbill
  final _i4.Perbill distance;

  @override
  Map<String, Map<String, int>> toJson() => {
        'EvaluatedInvalid': {
          'idtyIndex': idtyIndex,
          'distance': distance,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + const _i4.PerbillCodec().sizeHint(distance);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      distance,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is EvaluatedInvalid &&
          other.idtyIndex == idtyIndex &&
          other.distance == distance;

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        distance,
      );
}
