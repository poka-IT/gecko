// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../../gdev_runtime/runtime_call.dart' as _i3;
import '../../sp_weights/weight_v2/weight.dart' as _i4;

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

  Map<String, Map<String, Map<String, dynamic>>> toJson();
}

class $Call {
  const $Call();

  DispatchAsRoot dispatchAsRoot({required _i3.RuntimeCall call}) {
    return DispatchAsRoot(call: call);
  }

  DispatchAsRootUncheckedWeight dispatchAsRootUncheckedWeight({
    required _i3.RuntimeCall call,
    required _i4.Weight weight,
  }) {
    return DispatchAsRootUncheckedWeight(
      call: call,
      weight: weight,
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
        return DispatchAsRoot._decode(input);
      case 1:
        return DispatchAsRootUncheckedWeight._decode(input);
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
      case DispatchAsRoot:
        (value as DispatchAsRoot).encodeTo(output);
        break;
      case DispatchAsRootUncheckedWeight:
        (value as DispatchAsRootUncheckedWeight).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case DispatchAsRoot:
        return (value as DispatchAsRoot)._sizeHint();
      case DispatchAsRootUncheckedWeight:
        return (value as DispatchAsRootUncheckedWeight)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Dispatches a function call from root origin.
///
/// The weight of this call is defined by the caller.
class DispatchAsRoot extends Call {
  const DispatchAsRoot({required this.call});

  factory DispatchAsRoot._decode(_i1.Input input) {
    return DispatchAsRoot(call: _i3.RuntimeCall.codec.decode(input));
  }

  /// Box<<T as Config>::Call>
  final _i3.RuntimeCall call;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() => {
        'dispatch_as_root': {'call': call.toJson()}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i3.RuntimeCall.codec.sizeHint(call);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i3.RuntimeCall.codec.encodeTo(
      call,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is DispatchAsRoot && other.call == call;

  @override
  int get hashCode => call.hashCode;
}

/// Dispatches a function call from root origin.
/// This function does not check the weight of the call, and instead allows the
/// caller to specify the weight of the call.
///
/// The weight of this call is defined by the caller.
class DispatchAsRootUncheckedWeight extends Call {
  const DispatchAsRootUncheckedWeight({
    required this.call,
    required this.weight,
  });

  factory DispatchAsRootUncheckedWeight._decode(_i1.Input input) {
    return DispatchAsRootUncheckedWeight(
      call: _i3.RuntimeCall.codec.decode(input),
      weight: _i4.Weight.codec.decode(input),
    );
  }

  /// Box<<T as Config>::Call>
  final _i3.RuntimeCall call;

  /// Weight
  final _i4.Weight weight;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() => {
        'dispatch_as_root_unchecked_weight': {
          'call': call.toJson(),
          'weight': weight.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i3.RuntimeCall.codec.sizeHint(call);
    size = size + _i4.Weight.codec.sizeHint(weight);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i3.RuntimeCall.codec.encodeTo(
      call,
      output,
    );
    _i4.Weight.codec.encodeTo(
      weight,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is DispatchAsRootUncheckedWeight &&
          other.call == call &&
          other.weight == weight;

  @override
  int get hashCode => Object.hash(
        call,
        weight,
      );
}
