// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i3;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i4;

import '../sp_arithmetic/per_things/perbill.dart' as _i2;

class ComputationResult {
  const ComputationResult({required this.distances});

  factory ComputationResult.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// scale_info::prelude::vec::Vec<Perbill>
  final List<_i2.Perbill> distances;

  static const $ComputationResultCodec codec = $ComputationResultCodec();

  _i3.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, List<int>> toJson() =>
      {'distances': distances.map((value) => value).toList()};

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ComputationResult &&
          _i4.listsEqual(
            other.distances,
            distances,
          );

  @override
  int get hashCode => distances.hashCode;
}

class $ComputationResultCodec with _i1.Codec<ComputationResult> {
  const $ComputationResultCodec();

  @override
  void encodeTo(
    ComputationResult obj,
    _i1.Output output,
  ) {
    const _i1.SequenceCodec<_i2.Perbill>(_i2.PerbillCodec()).encodeTo(
      obj.distances,
      output,
    );
  }

  @override
  ComputationResult decode(_i1.Input input) {
    return ComputationResult(
        distances: const _i1.SequenceCodec<_i2.Perbill>(_i2.PerbillCodec())
            .decode(input));
  }

  @override
  int sizeHint(ComputationResult obj) {
    int size = 0;
    size = size +
        const _i1.SequenceCodec<_i2.Perbill>(_i2.PerbillCodec())
            .sizeHint(obj.distances);
    return size;
  }
}
