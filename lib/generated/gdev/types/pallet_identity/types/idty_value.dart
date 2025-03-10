// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i6;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i7;

import '../../common_runtime/entities/idty_data.dart' as _i2;
import '../../sp_core/crypto/account_id32.dart' as _i4;
import '../../tuples.dart' as _i3;
import 'idty_status.dart' as _i5;

class IdtyValue {
  const IdtyValue({
    required this.data,
    required this.nextCreatableIdentityOn,
    this.oldOwnerKey,
    required this.ownerKey,
    required this.nextScheduled,
    required this.status,
  });

  factory IdtyValue.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// IdtyData
  final _i2.IdtyData data;

  /// BlockNumber
  final int nextCreatableIdentityOn;

  /// Option<(AccountId, BlockNumber)>
  final _i3.Tuple2<_i4.AccountId32, int>? oldOwnerKey;

  /// AccountId
  final _i4.AccountId32 ownerKey;

  /// BlockNumber
  final int nextScheduled;

  /// IdtyStatus
  final _i5.IdtyStatus status;

  static const $IdtyValueCodec codec = $IdtyValueCodec();

  _i6.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'data': data.toJson(),
        'nextCreatableIdentityOn': nextCreatableIdentityOn,
        'oldOwnerKey': [
          oldOwnerKey?.value0.toList(),
          oldOwnerKey?.value1,
        ],
        'ownerKey': ownerKey.toList(),
        'nextScheduled': nextScheduled,
        'status': status.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyValue &&
          other.data == data &&
          other.nextCreatableIdentityOn == nextCreatableIdentityOn &&
          other.oldOwnerKey == oldOwnerKey &&
          _i7.listsEqual(
            other.ownerKey,
            ownerKey,
          ) &&
          other.nextScheduled == nextScheduled &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        data,
        nextCreatableIdentityOn,
        oldOwnerKey,
        ownerKey,
        nextScheduled,
        status,
      );
}

class $IdtyValueCodec with _i1.Codec<IdtyValue> {
  const $IdtyValueCodec();

  @override
  void encodeTo(
    IdtyValue obj,
    _i1.Output output,
  ) {
    _i2.IdtyData.codec.encodeTo(
      obj.data,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.nextCreatableIdentityOn,
      output,
    );
    const _i1.OptionCodec<_i3.Tuple2<_i4.AccountId32, int>>(
        _i3.Tuple2Codec<_i4.AccountId32, int>(
      _i4.AccountId32Codec(),
      _i1.U32Codec.codec,
    )).encodeTo(
      obj.oldOwnerKey,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.ownerKey,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.nextScheduled,
      output,
    );
    _i5.IdtyStatus.codec.encodeTo(
      obj.status,
      output,
    );
  }

  @override
  IdtyValue decode(_i1.Input input) {
    return IdtyValue(
      data: _i2.IdtyData.codec.decode(input),
      nextCreatableIdentityOn: _i1.U32Codec.codec.decode(input),
      oldOwnerKey: const _i1.OptionCodec<_i3.Tuple2<_i4.AccountId32, int>>(
          _i3.Tuple2Codec<_i4.AccountId32, int>(
        _i4.AccountId32Codec(),
        _i1.U32Codec.codec,
      )).decode(input),
      ownerKey: const _i1.U8ArrayCodec(32).decode(input),
      nextScheduled: _i1.U32Codec.codec.decode(input),
      status: _i5.IdtyStatus.codec.decode(input),
    );
  }

  @override
  int sizeHint(IdtyValue obj) {
    int size = 0;
    size = size + _i2.IdtyData.codec.sizeHint(obj.data);
    size = size + _i1.U32Codec.codec.sizeHint(obj.nextCreatableIdentityOn);
    size = size +
        const _i1.OptionCodec<_i3.Tuple2<_i4.AccountId32, int>>(
            _i3.Tuple2Codec<_i4.AccountId32, int>(
          _i4.AccountId32Codec(),
          _i1.U32Codec.codec,
        )).sizeHint(obj.oldOwnerKey);
    size = size + const _i4.AccountId32Codec().sizeHint(obj.ownerKey);
    size = size + _i1.U32Codec.codec.sizeHint(obj.nextScheduled);
    size = size + _i5.IdtyStatus.codec.sizeHint(obj.status);
    return size;
  }
}
