// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i5;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i6;

import '../../bounded_collections/bounded_btree_set/bounded_b_tree_set.dart'
    as _i4;
import '../../sp_core/crypto/account_id32.dart' as _i7;
import '../../tuples.dart' as _i2;
import '../median/median_acc.dart' as _i3;

class EvaluationPool {
  const EvaluationPool({
    required this.evaluations,
    required this.evaluators,
  });

  factory EvaluationPool.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// BoundedVec<(IdtyIndex, MedianAcc<Perbill, MAX_EVALUATORS_PER_SESSION>),
  ///ConstU32<MAX_EVALUATIONS_PER_SESSION>,>
  final List<_i2.Tuple2<int, _i3.MedianAcc>> evaluations;

  /// BoundedBTreeSet<AccountId, ConstU32<MAX_EVALUATORS_PER_SESSION>>
  final _i4.BoundedBTreeSet evaluators;

  static const $EvaluationPoolCodec codec = $EvaluationPoolCodec();

  _i5.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, List<List<dynamic>>> toJson() => {
        'evaluations': evaluations
            .map((value) => [
                  value.value0,
                  value.value1.toJson(),
                ])
            .toList(),
        'evaluators': evaluators.map((value) => value.toList()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is EvaluationPool &&
          _i6.listsEqual(
            other.evaluations,
            evaluations,
          ) &&
          other.evaluators == evaluators;

  @override
  int get hashCode => Object.hash(
        evaluations,
        evaluators,
      );
}

class $EvaluationPoolCodec with _i1.Codec<EvaluationPool> {
  const $EvaluationPoolCodec();

  @override
  void encodeTo(
    EvaluationPool obj,
    _i1.Output output,
  ) {
    const _i1.SequenceCodec<_i2.Tuple2<int, _i3.MedianAcc>>(
        _i2.Tuple2Codec<int, _i3.MedianAcc>(
      _i1.U32Codec.codec,
      _i3.MedianAcc.codec,
    )).encodeTo(
      obj.evaluations,
      output,
    );
    const _i1.SequenceCodec<_i7.AccountId32>(_i7.AccountId32Codec()).encodeTo(
      obj.evaluators,
      output,
    );
  }

  @override
  EvaluationPool decode(_i1.Input input) {
    return EvaluationPool(
      evaluations: const _i1.SequenceCodec<_i2.Tuple2<int, _i3.MedianAcc>>(
          _i2.Tuple2Codec<int, _i3.MedianAcc>(
        _i1.U32Codec.codec,
        _i3.MedianAcc.codec,
      )).decode(input),
      evaluators:
          const _i1.SequenceCodec<_i7.AccountId32>(_i7.AccountId32Codec())
              .decode(input),
    );
  }

  @override
  int sizeHint(EvaluationPool obj) {
    int size = 0;
    size = size +
        const _i1.SequenceCodec<_i2.Tuple2<int, _i3.MedianAcc>>(
            _i2.Tuple2Codec<int, _i3.MedianAcc>(
          _i1.U32Codec.codec,
          _i3.MedianAcc.codec,
        )).sizeHint(obj.evaluations);
    size = size + const _i4.BoundedBTreeSetCodec().sizeHint(obj.evaluators);
    return size;
  }
}
