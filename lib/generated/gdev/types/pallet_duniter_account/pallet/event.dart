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

  AccountLinked accountLinked({
    required _i3.AccountId32 who,
    required int identity,
  }) {
    return AccountLinked(
      who: who,
      identity: identity,
    );
  }

  AccountUnlinked accountUnlinked(_i3.AccountId32 value0) {
    return AccountUnlinked(value0);
  }
}

class $EventCodec with _i1.Codec<Event> {
  const $EventCodec();

  @override
  Event decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return AccountLinked._decode(input);
      case 1:
        return AccountUnlinked._decode(input);
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
      case AccountLinked:
        (value as AccountLinked).encodeTo(output);
        break;
      case AccountUnlinked:
        (value as AccountUnlinked).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case AccountLinked:
        return (value as AccountLinked)._sizeHint();
      case AccountUnlinked:
        return (value as AccountUnlinked)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// account linked to identity
class AccountLinked extends Event {
  const AccountLinked({
    required this.who,
    required this.identity,
  });

  factory AccountLinked._decode(_i1.Input input) {
    return AccountLinked(
      who: const _i1.U8ArrayCodec(32).decode(input),
      identity: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 who;

  /// IdtyIdOf<T>
  final int identity;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'AccountLinked': {
          'who': who.toList(),
          'identity': identity,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(who);
    size = size + _i1.U32Codec.codec.sizeHint(identity);
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
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is AccountLinked &&
          _i4.listsEqual(
            other.who,
            who,
          ) &&
          other.identity == identity;

  @override
  int get hashCode => Object.hash(
        who,
        identity,
      );
}

/// The account was unlinked from its identity.
class AccountUnlinked extends Event {
  const AccountUnlinked(this.value0);

  factory AccountUnlinked._decode(_i1.Input input) {
    return AccountUnlinked(const _i1.U8ArrayCodec(32).decode(input));
  }

  /// T::AccountId
  final _i3.AccountId32 value0;

  @override
  Map<String, List<int>> toJson() => {'AccountUnlinked': value0.toList()};

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
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
      other is AccountUnlinked &&
          _i4.listsEqual(
            other.value0,
            value0,
          );

  @override
  int get hashCode => value0.hashCode;
}
