// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i3;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i4;

import '../../sp_core/crypto/account_id32.dart' as _i2;

class Refund {
  const Refund({
    required this.account,
    required this.identity,
    required this.amount,
  });

  factory Refund.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// AccountId
  final _i2.AccountId32 account;

  /// IdtyId
  final int identity;

  /// Balance
  final BigInt amount;

  static const $RefundCodec codec = $RefundCodec();

  _i3.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'account': account.toList(),
        'identity': identity,
        'amount': amount,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Refund &&
          _i4.listsEqual(
            other.account,
            account,
          ) &&
          other.identity == identity &&
          other.amount == amount;

  @override
  int get hashCode => Object.hash(
        account,
        identity,
        amount,
      );
}

class $RefundCodec with _i1.Codec<Refund> {
  const $RefundCodec();

  @override
  void encodeTo(
    Refund obj,
    _i1.Output output,
  ) {
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.account,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.identity,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      obj.amount,
      output,
    );
  }

  @override
  Refund decode(_i1.Input input) {
    return Refund(
      account: const _i1.U8ArrayCodec(32).decode(input),
      identity: _i1.U32Codec.codec.decode(input),
      amount: _i1.U64Codec.codec.decode(input),
    );
  }

  @override
  int sizeHint(Refund obj) {
    int size = 0;
    size = size + const _i2.AccountId32Codec().sizeHint(obj.account);
    size = size + _i1.U32Codec.codec.sizeHint(obj.identity);
    size = size + _i1.U64Codec.codec.sizeHint(obj.amount);
    return size;
  }
}
