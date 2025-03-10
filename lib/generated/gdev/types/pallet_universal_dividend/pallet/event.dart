// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i4;

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

  NewUdCreated newUdCreated({
    required BigInt amount,
    required int index,
    required BigInt monetaryMass,
    required BigInt membersCount,
  }) {
    return NewUdCreated(
      amount: amount,
      index: index,
      monetaryMass: monetaryMass,
      membersCount: membersCount,
    );
  }

  UdReevalued udReevalued({
    required BigInt newUdAmount,
    required BigInt monetaryMass,
    required BigInt membersCount,
  }) {
    return UdReevalued(
      newUdAmount: newUdAmount,
      monetaryMass: monetaryMass,
      membersCount: membersCount,
    );
  }

  UdsAutoPaid udsAutoPaid({
    required int count,
    required BigInt total,
    required _i3.AccountId32 who,
  }) {
    return UdsAutoPaid(
      count: count,
      total: total,
      who: who,
    );
  }

  UdsClaimed udsClaimed({
    required int count,
    required BigInt total,
    required _i3.AccountId32 who,
  }) {
    return UdsClaimed(
      count: count,
      total: total,
      who: who,
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
        return NewUdCreated._decode(input);
      case 1:
        return UdReevalued._decode(input);
      case 2:
        return UdsAutoPaid._decode(input);
      case 3:
        return UdsClaimed._decode(input);
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
      case NewUdCreated:
        (value as NewUdCreated).encodeTo(output);
        break;
      case UdReevalued:
        (value as UdReevalued).encodeTo(output);
        break;
      case UdsAutoPaid:
        (value as UdsAutoPaid).encodeTo(output);
        break;
      case UdsClaimed:
        (value as UdsClaimed).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case NewUdCreated:
        return (value as NewUdCreated)._sizeHint();
      case UdReevalued:
        return (value as UdReevalued)._sizeHint();
      case UdsAutoPaid:
        return (value as UdsAutoPaid)._sizeHint();
      case UdsClaimed:
        return (value as UdsClaimed)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A new universal dividend is created.
class NewUdCreated extends Event {
  const NewUdCreated({
    required this.amount,
    required this.index,
    required this.monetaryMass,
    required this.membersCount,
  });

  factory NewUdCreated._decode(_i1.Input input) {
    return NewUdCreated(
      amount: _i1.U64Codec.codec.decode(input),
      index: _i1.U16Codec.codec.decode(input),
      monetaryMass: _i1.U64Codec.codec.decode(input),
      membersCount: _i1.U64Codec.codec.decode(input),
    );
  }

  /// BalanceOf<T>
  final BigInt amount;

  /// UdIndex
  final int index;

  /// BalanceOf<T>
  final BigInt monetaryMass;

  /// BalanceOf<T>
  final BigInt membersCount;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'NewUdCreated': {
          'amount': amount,
          'index': index,
          'monetaryMass': monetaryMass,
          'membersCount': membersCount,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U64Codec.codec.sizeHint(amount);
    size = size + _i1.U16Codec.codec.sizeHint(index);
    size = size + _i1.U64Codec.codec.sizeHint(monetaryMass);
    size = size + _i1.U64Codec.codec.sizeHint(membersCount);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      amount,
      output,
    );
    _i1.U16Codec.codec.encodeTo(
      index,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      monetaryMass,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      membersCount,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is NewUdCreated &&
          other.amount == amount &&
          other.index == index &&
          other.monetaryMass == monetaryMass &&
          other.membersCount == membersCount;

  @override
  int get hashCode => Object.hash(
        amount,
        index,
        monetaryMass,
        membersCount,
      );
}

/// The universal dividend has been re-evaluated.
class UdReevalued extends Event {
  const UdReevalued({
    required this.newUdAmount,
    required this.monetaryMass,
    required this.membersCount,
  });

  factory UdReevalued._decode(_i1.Input input) {
    return UdReevalued(
      newUdAmount: _i1.U64Codec.codec.decode(input),
      monetaryMass: _i1.U64Codec.codec.decode(input),
      membersCount: _i1.U64Codec.codec.decode(input),
    );
  }

  /// BalanceOf<T>
  final BigInt newUdAmount;

  /// BalanceOf<T>
  final BigInt monetaryMass;

  /// BalanceOf<T>
  final BigInt membersCount;

  @override
  Map<String, Map<String, BigInt>> toJson() => {
        'UdReevalued': {
          'newUdAmount': newUdAmount,
          'monetaryMass': monetaryMass,
          'membersCount': membersCount,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U64Codec.codec.sizeHint(newUdAmount);
    size = size + _i1.U64Codec.codec.sizeHint(monetaryMass);
    size = size + _i1.U64Codec.codec.sizeHint(membersCount);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      newUdAmount,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      monetaryMass,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      membersCount,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is UdReevalued &&
          other.newUdAmount == newUdAmount &&
          other.monetaryMass == monetaryMass &&
          other.membersCount == membersCount;

  @override
  int get hashCode => Object.hash(
        newUdAmount,
        monetaryMass,
        membersCount,
      );
}

/// DUs were automatically transferred as part of a member removal.
class UdsAutoPaid extends Event {
  const UdsAutoPaid({
    required this.count,
    required this.total,
    required this.who,
  });

  factory UdsAutoPaid._decode(_i1.Input input) {
    return UdsAutoPaid(
      count: _i1.U16Codec.codec.decode(input),
      total: _i1.U64Codec.codec.decode(input),
      who: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// UdIndex
  final int count;

  /// BalanceOf<T>
  final BigInt total;

  /// T::AccountId
  final _i3.AccountId32 who;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'UdsAutoPaid': {
          'count': count,
          'total': total,
          'who': who.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U16Codec.codec.sizeHint(count);
    size = size + _i1.U64Codec.codec.sizeHint(total);
    size = size + const _i3.AccountId32Codec().sizeHint(who);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i1.U16Codec.codec.encodeTo(
      count,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      total,
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
      other is UdsAutoPaid &&
          other.count == count &&
          other.total == total &&
          _i4.listsEqual(
            other.who,
            who,
          );

  @override
  int get hashCode => Object.hash(
        count,
        total,
        who,
      );
}

/// A member claimed his UDs.
class UdsClaimed extends Event {
  const UdsClaimed({
    required this.count,
    required this.total,
    required this.who,
  });

  factory UdsClaimed._decode(_i1.Input input) {
    return UdsClaimed(
      count: _i1.U16Codec.codec.decode(input),
      total: _i1.U64Codec.codec.decode(input),
      who: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// UdIndex
  final int count;

  /// BalanceOf<T>
  final BigInt total;

  /// T::AccountId
  final _i3.AccountId32 who;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'UdsClaimed': {
          'count': count,
          'total': total,
          'who': who.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U16Codec.codec.sizeHint(count);
    size = size + _i1.U64Codec.codec.sizeHint(total);
    size = size + const _i3.AccountId32Codec().sizeHint(who);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    _i1.U16Codec.codec.encodeTo(
      count,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      total,
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
      other is UdsClaimed &&
          other.count == count &&
          other.total == total &&
          _i4.listsEqual(
            other.who,
            who,
          );

  @override
  int get hashCode => Object.hash(
        count,
        total,
        who,
      );
}
