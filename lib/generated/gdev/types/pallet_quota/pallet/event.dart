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

  Map<String, dynamic> toJson();
}

class $Event {
  const $Event();

  Refunded refunded({
    required _i3.AccountId32 who,
    required int identity,
    required BigInt amount,
  }) {
    return Refunded(
      who: who,
      identity: identity,
      amount: amount,
    );
  }

  NoQuotaForIdty noQuotaForIdty(int value0) {
    return NoQuotaForIdty(value0);
  }

  NoMoreCurrencyForRefund noMoreCurrencyForRefund() {
    return NoMoreCurrencyForRefund();
  }

  RefundFailed refundFailed(_i3.AccountId32 value0) {
    return RefundFailed(value0);
  }

  RefundQueueFull refundQueueFull() {
    return RefundQueueFull();
  }
}

class $EventCodec with _i1.Codec<Event> {
  const $EventCodec();

  @override
  Event decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return Refunded._decode(input);
      case 1:
        return NoQuotaForIdty._decode(input);
      case 2:
        return const NoMoreCurrencyForRefund();
      case 3:
        return RefundFailed._decode(input);
      case 4:
        return const RefundQueueFull();
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
      case Refunded:
        (value as Refunded).encodeTo(output);
        break;
      case NoQuotaForIdty:
        (value as NoQuotaForIdty).encodeTo(output);
        break;
      case NoMoreCurrencyForRefund:
        (value as NoMoreCurrencyForRefund).encodeTo(output);
        break;
      case RefundFailed:
        (value as RefundFailed).encodeTo(output);
        break;
      case RefundQueueFull:
        (value as RefundQueueFull).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case Refunded:
        return (value as Refunded)._sizeHint();
      case NoQuotaForIdty:
        return (value as NoQuotaForIdty)._sizeHint();
      case NoMoreCurrencyForRefund:
        return 1;
      case RefundFailed:
        return (value as RefundFailed)._sizeHint();
      case RefundQueueFull:
        return 1;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Transaction fees were refunded.
class Refunded extends Event {
  const Refunded({
    required this.who,
    required this.identity,
    required this.amount,
  });

  factory Refunded._decode(_i1.Input input) {
    return Refunded(
      who: const _i1.U8ArrayCodec(32).decode(input),
      identity: _i1.U32Codec.codec.decode(input),
      amount: _i1.U64Codec.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 who;

  /// IdtyId<T>
  final int identity;

  /// BalanceOf<T>
  final BigInt amount;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'Refunded': {
          'who': who.toList(),
          'identity': identity,
          'amount': amount,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(who);
    size = size + _i1.U32Codec.codec.sizeHint(identity);
    size = size + _i1.U64Codec.codec.sizeHint(amount);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      who,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      identity,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      amount,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Refunded &&
          _i4.listsEqual(
            other.who,
            who,
          ) &&
          other.identity == identity &&
          other.amount == amount;

  @override
  int get hashCode => Object.hash(
        who,
        identity,
        amount,
      );
}

/// No more quota available for refund.
class NoQuotaForIdty extends Event {
  const NoQuotaForIdty(this.value0);

  factory NoQuotaForIdty._decode(_i1.Input input) {
    return NoQuotaForIdty(_i1.U32Codec.codec.decode(input));
  }

  /// IdtyId<T>
  final int value0;

  @override
  Map<String, int> toJson() => {'NoQuotaForIdty': value0};

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      value0,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is NoQuotaForIdty && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

/// No more currency available for refund.
/// This scenario should never occur if the fees are intended for the refund account.
class NoMoreCurrencyForRefund extends Event {
  const NoMoreCurrencyForRefund();

  @override
  Map<String, dynamic> toJson() => {'NoMoreCurrencyForRefund': null};

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
  }

  @override
  bool operator ==(Object other) => other is NoMoreCurrencyForRefund;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The refund has failed.
/// This scenario should rarely occur, except when the account was destroyed in the interim between the request and the refund.
class RefundFailed extends Event {
  const RefundFailed(this.value0);

  factory RefundFailed._decode(_i1.Input input) {
    return RefundFailed(const _i1.U8ArrayCodec(32).decode(input));
  }

  /// T::AccountId
  final _i3.AccountId32 value0;

  @override
  Map<String, List<int>> toJson() => {'RefundFailed': value0.toList()};

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      value0,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is RefundFailed &&
          _i4.listsEqual(
            other.value0,
            value0,
          );

  @override
  int get hashCode => value0.hashCode;
}

/// Refund queue was full.
class RefundQueueFull extends Event {
  const RefundQueueFull();

  @override
  Map<String, dynamic> toJson() => {'RefundQueueFull': null};

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      4,
      output,
    );
  }

  @override
  bool operator ==(Object other) => other is RefundQueueFull;

  @override
  int get hashCode => runtimeType.hashCode;
}
