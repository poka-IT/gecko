// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i5;

import '../../sp_core/crypto/account_id32.dart' as _i3;
import '../../tuples.dart' as _i4;

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

  OneshotAccountCreated oneshotAccountCreated({
    required _i3.AccountId32 account,
    required BigInt balance,
    required _i3.AccountId32 creator,
  }) {
    return OneshotAccountCreated(
      account: account,
      balance: balance,
      creator: creator,
    );
  }

  OneshotAccountConsumed oneshotAccountConsumed({
    required _i3.AccountId32 account,
    required _i4.Tuple2<_i3.AccountId32, BigInt> dest1,
    _i4.Tuple2<_i3.AccountId32, BigInt>? dest2,
  }) {
    return OneshotAccountConsumed(
      account: account,
      dest1: dest1,
      dest2: dest2,
    );
  }

  Withdraw withdraw({
    required _i3.AccountId32 account,
    required BigInt balance,
  }) {
    return Withdraw(
      account: account,
      balance: balance,
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
        return OneshotAccountCreated._decode(input);
      case 1:
        return OneshotAccountConsumed._decode(input);
      case 2:
        return Withdraw._decode(input);
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
      case OneshotAccountCreated:
        (value as OneshotAccountCreated).encodeTo(output);
        break;
      case OneshotAccountConsumed:
        (value as OneshotAccountConsumed).encodeTo(output);
        break;
      case Withdraw:
        (value as Withdraw).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case OneshotAccountCreated:
        return (value as OneshotAccountCreated)._sizeHint();
      case OneshotAccountConsumed:
        return (value as OneshotAccountConsumed)._sizeHint();
      case Withdraw:
        return (value as Withdraw)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A oneshot account was created.
class OneshotAccountCreated extends Event {
  const OneshotAccountCreated({
    required this.account,
    required this.balance,
    required this.creator,
  });

  factory OneshotAccountCreated._decode(_i1.Input input) {
    return OneshotAccountCreated(
      account: const _i1.U8ArrayCodec(32).decode(input),
      balance: _i1.U64Codec.codec.decode(input),
      creator: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 account;

  /// BalanceOf<T>
  final BigInt balance;

  /// T::AccountId
  final _i3.AccountId32 creator;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'OneshotAccountCreated': {
          'account': account.toList(),
          'balance': balance,
          'creator': creator.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(account);
    size = size + _i1.U64Codec.codec.sizeHint(balance);
    size = size + const _i3.AccountId32Codec().sizeHint(creator);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      account,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      balance,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      creator,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is OneshotAccountCreated &&
          _i5.listsEqual(
            other.account,
            account,
          ) &&
          other.balance == balance &&
          _i5.listsEqual(
            other.creator,
            creator,
          );

  @override
  int get hashCode => Object.hash(
        account,
        balance,
        creator,
      );
}

/// A oneshot account was consumed.
class OneshotAccountConsumed extends Event {
  const OneshotAccountConsumed({
    required this.account,
    required this.dest1,
    this.dest2,
  });

  factory OneshotAccountConsumed._decode(_i1.Input input) {
    return OneshotAccountConsumed(
      account: const _i1.U8ArrayCodec(32).decode(input),
      dest1: const _i4.Tuple2Codec<_i3.AccountId32, BigInt>(
        _i3.AccountId32Codec(),
        _i1.U64Codec.codec,
      ).decode(input),
      dest2: const _i1.OptionCodec<_i4.Tuple2<_i3.AccountId32, BigInt>>(
          _i4.Tuple2Codec<_i3.AccountId32, BigInt>(
        _i3.AccountId32Codec(),
        _i1.U64Codec.codec,
      )).decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 account;

  /// (T::AccountId, BalanceOf<T>)
  final _i4.Tuple2<_i3.AccountId32, BigInt> dest1;

  /// Option<(T::AccountId, BalanceOf<T>)>
  final _i4.Tuple2<_i3.AccountId32, BigInt>? dest2;

  @override
  Map<String, Map<String, List<dynamic>?>> toJson() => {
        'OneshotAccountConsumed': {
          'account': account.toList(),
          'dest1': [
            dest1.value0.toList(),
            dest1.value1,
          ],
          'dest2': [
            dest2?.value0.toList(),
            dest2?.value1,
          ],
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(account);
    size = size +
        const _i4.Tuple2Codec<_i3.AccountId32, BigInt>(
          _i3.AccountId32Codec(),
          _i1.U64Codec.codec,
        ).sizeHint(dest1);
    size = size +
        const _i1.OptionCodec<_i4.Tuple2<_i3.AccountId32, BigInt>>(
            _i4.Tuple2Codec<_i3.AccountId32, BigInt>(
          _i3.AccountId32Codec(),
          _i1.U64Codec.codec,
        )).sizeHint(dest2);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      account,
      output,
    );
    const _i4.Tuple2Codec<_i3.AccountId32, BigInt>(
      _i3.AccountId32Codec(),
      _i1.U64Codec.codec,
    ).encodeTo(
      dest1,
      output,
    );
    const _i1.OptionCodec<_i4.Tuple2<_i3.AccountId32, BigInt>>(
        _i4.Tuple2Codec<_i3.AccountId32, BigInt>(
      _i3.AccountId32Codec(),
      _i1.U64Codec.codec,
    )).encodeTo(
      dest2,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is OneshotAccountConsumed &&
          _i5.listsEqual(
            other.account,
            account,
          ) &&
          other.dest1 == dest1 &&
          other.dest2 == dest2;

  @override
  int get hashCode => Object.hash(
        account,
        dest1,
        dest2,
      );
}

/// A withdrawal was executed on a oneshot account.
class Withdraw extends Event {
  const Withdraw({
    required this.account,
    required this.balance,
  });

  factory Withdraw._decode(_i1.Input input) {
    return Withdraw(
      account: const _i1.U8ArrayCodec(32).decode(input),
      balance: _i1.U64Codec.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 account;

  /// BalanceOf<T>
  final BigInt balance;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'Withdraw': {
          'account': account.toList(),
          'balance': balance,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(account);
    size = size + _i1.U64Codec.codec.sizeHint(balance);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      account,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      balance,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Withdraw &&
          _i5.listsEqual(
            other.account,
            account,
          ) &&
          other.balance == balance;

  @override
  int get hashCode => Object.hash(
        account,
        balance,
      );
}
