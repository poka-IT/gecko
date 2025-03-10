// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i4;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../sp_arithmetic/per_things/perbill.dart' as _i3;
import '../../tuples.dart' as _i2;

class MedianAcc {
  const MedianAcc({
    required this.samples,
    this.medianIndex,
    required this.medianSubindex,
  });

  factory MedianAcc.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// BoundedVec<(T, u32), ConstU32<S>>
  final List<_i2.Tuple2<_i3.Perbill, int>> samples;

  /// Option<u32>
  final int? medianIndex;

  /// u32
  final int medianSubindex;

  static const $MedianAccCodec codec = $MedianAccCodec();

  _i4.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'samples': samples
            .map((value) => [
                  value.value0,
                  value.value1,
                ])
            .toList(),
        'medianIndex': medianIndex,
        'medianSubindex': medianSubindex,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MedianAcc &&
          _i5.listsEqual(
            other.samples,
            samples,
          ) &&
          other.medianIndex == medianIndex &&
          other.medianSubindex == medianSubindex;

  @override
  int get hashCode => Object.hash(
        samples,
        medianIndex,
        medianSubindex,
      );
}

class $MedianAccCodec with _i1.Codec<MedianAcc> {
  const $MedianAccCodec();

  @override
  void encodeTo(
    MedianAcc obj,
    _i1.Output output,
  ) {
    const _i1.SequenceCodec<_i2.Tuple2<_i3.Perbill, int>>(
        _i2.Tuple2Codec<_i3.Perbill, int>(
      _i3.PerbillCodec(),
      _i1.U32Codec.codec,
    )).encodeTo(
      obj.samples,
      output,
    );
    const _i1.OptionCodec<int>(_i1.U32Codec.codec).encodeTo(
      obj.medianIndex,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.medianSubindex,
      output,
    );
  }

  @override
  MedianAcc decode(_i1.Input input) {
    return MedianAcc(
      samples: const _i1.SequenceCodec<_i2.Tuple2<_i3.Perbill, int>>(
          _i2.Tuple2Codec<_i3.Perbill, int>(
        _i3.PerbillCodec(),
        _i1.U32Codec.codec,
      )).decode(input),
      medianIndex: const _i1.OptionCodec<int>(_i1.U32Codec.codec).decode(input),
      medianSubindex: _i1.U32Codec.codec.decode(input),
    );
  }

  @override
  int sizeHint(MedianAcc obj) {
    int size = 0;
    size = size +
        const _i1.SequenceCodec<_i2.Tuple2<_i3.Perbill, int>>(
            _i2.Tuple2Codec<_i3.Perbill, int>(
          _i3.PerbillCodec(),
          _i1.U32Codec.codec,
        )).sizeHint(obj.samples);
    size = size +
        const _i1.OptionCodec<int>(_i1.U32Codec.codec)
            .sizeHint(obj.medianIndex);
    size = size + _i1.U32Codec.codec.sizeHint(obj.medianSubindex);
    return size;
  }
}
