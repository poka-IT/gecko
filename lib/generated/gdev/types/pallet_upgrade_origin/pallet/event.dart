// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../../sp_runtime/dispatch_error.dart' as _i3;

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

  Map<String, Map<String, Map<String, dynamic>>> toJson();
}

class $Event {
  const $Event();

  DispatchedAsRoot dispatchedAsRoot(
      {required _i1.Result<dynamic, _i3.DispatchError> result}) {
    return DispatchedAsRoot(result: result);
  }
}

class $EventCodec with _i1.Codec<Event> {
  const $EventCodec();

  @override
  Event decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return DispatchedAsRoot._decode(input);
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
      case DispatchedAsRoot:
        (value as DispatchedAsRoot).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case DispatchedAsRoot:
        return (value as DispatchedAsRoot)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A call was dispatched as root from an upgradable origin
class DispatchedAsRoot extends Event {
  const DispatchedAsRoot({required this.result});

  factory DispatchedAsRoot._decode(_i1.Input input) {
    return DispatchedAsRoot(
        result: const _i1.ResultCodec<dynamic, _i3.DispatchError>(
      _i1.NullCodec.codec,
      _i3.DispatchError.codec,
    ).decode(input));
  }

  /// DispatchResult
  final _i1.Result<dynamic, _i3.DispatchError> result;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() => {
        'DispatchedAsRoot': {'result': result.toJson()}
      };

  int _sizeHint() {
    int size = 1;
    size = size +
        const _i1.ResultCodec<dynamic, _i3.DispatchError>(
          _i1.NullCodec.codec,
          _i3.DispatchError.codec,
        ).sizeHint(result);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    const _i1.ResultCodec<dynamic, _i3.DispatchError>(
      _i1.NullCodec.codec,
      _i3.DispatchError.codec,
    ).encodeTo(
      result,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is DispatchedAsRoot && other.result == result;

  @override
  int get hashCode => result.hashCode;
}
