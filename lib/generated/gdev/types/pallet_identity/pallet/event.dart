// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i7;

import '../../sp_core/crypto/account_id32.dart' as _i3;
import '../types/idty_name.dart' as _i4;
import '../types/removal_reason.dart' as _i6;
import '../types/revocation_reason.dart' as _i5;

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

  IdtyCreated idtyCreated({
    required int idtyIndex,
    required _i3.AccountId32 ownerKey,
  }) {
    return IdtyCreated(
      idtyIndex: idtyIndex,
      ownerKey: ownerKey,
    );
  }

  IdtyConfirmed idtyConfirmed({
    required int idtyIndex,
    required _i3.AccountId32 ownerKey,
    required _i4.IdtyName name,
  }) {
    return IdtyConfirmed(
      idtyIndex: idtyIndex,
      ownerKey: ownerKey,
      name: name,
    );
  }

  IdtyValidated idtyValidated({required int idtyIndex}) {
    return IdtyValidated(idtyIndex: idtyIndex);
  }

  IdtyChangedOwnerKey idtyChangedOwnerKey({
    required int idtyIndex,
    required _i3.AccountId32 newOwnerKey,
  }) {
    return IdtyChangedOwnerKey(
      idtyIndex: idtyIndex,
      newOwnerKey: newOwnerKey,
    );
  }

  IdtyRevoked idtyRevoked({
    required int idtyIndex,
    required _i5.RevocationReason reason,
  }) {
    return IdtyRevoked(
      idtyIndex: idtyIndex,
      reason: reason,
    );
  }

  IdtyRemoved idtyRemoved({
    required int idtyIndex,
    required _i6.RemovalReason reason,
  }) {
    return IdtyRemoved(
      idtyIndex: idtyIndex,
      reason: reason,
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
        return IdtyCreated._decode(input);
      case 1:
        return IdtyConfirmed._decode(input);
      case 2:
        return IdtyValidated._decode(input);
      case 3:
        return IdtyChangedOwnerKey._decode(input);
      case 4:
        return IdtyRevoked._decode(input);
      case 5:
        return IdtyRemoved._decode(input);
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
      case IdtyCreated:
        (value as IdtyCreated).encodeTo(output);
        break;
      case IdtyConfirmed:
        (value as IdtyConfirmed).encodeTo(output);
        break;
      case IdtyValidated:
        (value as IdtyValidated).encodeTo(output);
        break;
      case IdtyChangedOwnerKey:
        (value as IdtyChangedOwnerKey).encodeTo(output);
        break;
      case IdtyRevoked:
        (value as IdtyRevoked).encodeTo(output);
        break;
      case IdtyRemoved:
        (value as IdtyRemoved).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case IdtyCreated:
        return (value as IdtyCreated)._sizeHint();
      case IdtyConfirmed:
        return (value as IdtyConfirmed)._sizeHint();
      case IdtyValidated:
        return (value as IdtyValidated)._sizeHint();
      case IdtyChangedOwnerKey:
        return (value as IdtyChangedOwnerKey)._sizeHint();
      case IdtyRevoked:
        return (value as IdtyRevoked)._sizeHint();
      case IdtyRemoved:
        return (value as IdtyRemoved)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A new identity has been created.
class IdtyCreated extends Event {
  const IdtyCreated({
    required this.idtyIndex,
    required this.ownerKey,
  });

  factory IdtyCreated._decode(_i1.Input input) {
    return IdtyCreated(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      ownerKey: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// T::AccountId
  final _i3.AccountId32 ownerKey;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'IdtyCreated': {
          'idtyIndex': idtyIndex,
          'ownerKey': ownerKey.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + const _i3.AccountId32Codec().sizeHint(ownerKey);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      ownerKey,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyCreated &&
          other.idtyIndex == idtyIndex &&
          _i7.listsEqual(
            other.ownerKey,
            ownerKey,
          );

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        ownerKey,
      );
}

/// An identity has been confirmed by its owner.
class IdtyConfirmed extends Event {
  const IdtyConfirmed({
    required this.idtyIndex,
    required this.ownerKey,
    required this.name,
  });

  factory IdtyConfirmed._decode(_i1.Input input) {
    return IdtyConfirmed(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      ownerKey: const _i1.U8ArrayCodec(32).decode(input),
      name: _i1.U8SequenceCodec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// T::AccountId
  final _i3.AccountId32 ownerKey;

  /// IdtyName
  final _i4.IdtyName name;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'IdtyConfirmed': {
          'idtyIndex': idtyIndex,
          'ownerKey': ownerKey.toList(),
          'name': name,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + const _i3.AccountId32Codec().sizeHint(ownerKey);
    size = size + const _i4.IdtyNameCodec().sizeHint(name);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      ownerKey,
      output,
    );
    _i1.U8SequenceCodec.codec.encodeTo(
      name,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyConfirmed &&
          other.idtyIndex == idtyIndex &&
          _i7.listsEqual(
            other.ownerKey,
            ownerKey,
          ) &&
          _i7.listsEqual(
            other.name,
            name,
          );

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        ownerKey,
        name,
      );
}

/// An identity has been validated.
class IdtyValidated extends Event {
  const IdtyValidated({required this.idtyIndex});

  factory IdtyValidated._decode(_i1.Input input) {
    return IdtyValidated(idtyIndex: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int idtyIndex;

  @override
  Map<String, Map<String, int>> toJson() => {
        'IdtyValidated': {'idtyIndex': idtyIndex}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyValidated && other.idtyIndex == idtyIndex;

  @override
  int get hashCode => idtyIndex.hashCode;
}

class IdtyChangedOwnerKey extends Event {
  const IdtyChangedOwnerKey({
    required this.idtyIndex,
    required this.newOwnerKey,
  });

  factory IdtyChangedOwnerKey._decode(_i1.Input input) {
    return IdtyChangedOwnerKey(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      newOwnerKey: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// T::AccountId
  final _i3.AccountId32 newOwnerKey;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'IdtyChangedOwnerKey': {
          'idtyIndex': idtyIndex,
          'newOwnerKey': newOwnerKey.toList(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + const _i3.AccountId32Codec().sizeHint(newOwnerKey);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      newOwnerKey,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyChangedOwnerKey &&
          other.idtyIndex == idtyIndex &&
          _i7.listsEqual(
            other.newOwnerKey,
            newOwnerKey,
          );

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        newOwnerKey,
      );
}

/// An identity has been revoked.
class IdtyRevoked extends Event {
  const IdtyRevoked({
    required this.idtyIndex,
    required this.reason,
  });

  factory IdtyRevoked._decode(_i1.Input input) {
    return IdtyRevoked(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      reason: _i5.RevocationReason.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// RevocationReason
  final _i5.RevocationReason reason;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'IdtyRevoked': {
          'idtyIndex': idtyIndex,
          'reason': reason.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + _i5.RevocationReason.codec.sizeHint(reason);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      4,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    _i5.RevocationReason.codec.encodeTo(
      reason,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyRevoked &&
          other.idtyIndex == idtyIndex &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        reason,
      );
}

/// An identity has been removed.
class IdtyRemoved extends Event {
  const IdtyRemoved({
    required this.idtyIndex,
    required this.reason,
  });

  factory IdtyRemoved._decode(_i1.Input input) {
    return IdtyRemoved(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      reason: _i6.RemovalReason.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// RemovalReason
  final _i6.RemovalReason reason;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'IdtyRemoved': {
          'idtyIndex': idtyIndex,
          'reason': reason.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + _i6.RemovalReason.codec.sizeHint(reason);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      5,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    _i6.RemovalReason.codec.encodeTo(
      reason,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IdtyRemoved &&
          other.idtyIndex == idtyIndex &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        reason,
      );
}
