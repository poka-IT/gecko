// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../../gdev_runtime/opaque/session_keys.dart' as _i3;

/// Contains a variant per dispatchable extrinsic that this pallet has.
abstract class Call {
  const Call();

  factory Call.decode(_i1.Input input) {
    return codec.decode(input);
  }

  static const $CallCodec codec = $CallCodec();

  static const $Call values = $Call();

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

class $Call {
  const $Call();

  GoOffline goOffline() {
    return GoOffline();
  }

  GoOnline goOnline() {
    return GoOnline();
  }

  SetSessionKeys setSessionKeys({required _i3.SessionKeys keys}) {
    return SetSessionKeys(keys: keys);
  }

  RemoveMember removeMember({required int memberId}) {
    return RemoveMember(memberId: memberId);
  }

  RemoveMemberFromBlacklist removeMemberFromBlacklist({required int memberId}) {
    return RemoveMemberFromBlacklist(memberId: memberId);
  }
}

class $CallCodec with _i1.Codec<Call> {
  const $CallCodec();

  @override
  Call decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return const GoOffline();
      case 1:
        return const GoOnline();
      case 2:
        return SetSessionKeys._decode(input);
      case 3:
        return RemoveMember._decode(input);
      case 4:
        return RemoveMemberFromBlacklist._decode(input);
      default:
        throw Exception('Call: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Call value,
    _i1.Output output,
  ) {
    switch (value.runtimeType) {
      case GoOffline:
        (value as GoOffline).encodeTo(output);
        break;
      case GoOnline:
        (value as GoOnline).encodeTo(output);
        break;
      case SetSessionKeys:
        (value as SetSessionKeys).encodeTo(output);
        break;
      case RemoveMember:
        (value as RemoveMember).encodeTo(output);
        break;
      case RemoveMemberFromBlacklist:
        (value as RemoveMemberFromBlacklist).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case GoOffline:
        return 1;
      case GoOnline:
        return 1;
      case SetSessionKeys:
        return (value as SetSessionKeys)._sizeHint();
      case RemoveMember:
        return (value as RemoveMember)._sizeHint();
      case RemoveMemberFromBlacklist:
        return (value as RemoveMemberFromBlacklist)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Request to leave the set of validators two sessions later.
class GoOffline extends Call {
  const GoOffline();

  @override
  Map<String, dynamic> toJson() => {'go_offline': null};

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
  }

  @override
  bool operator ==(Object other) => other is GoOffline;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Request to join the set of validators two sessions later.
class GoOnline extends Call {
  const GoOnline();

  @override
  Map<String, dynamic> toJson() => {'go_online': null};

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
  }

  @override
  bool operator ==(Object other) => other is GoOnline;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Declare new session keys to replace current ones.
class SetSessionKeys extends Call {
  const SetSessionKeys({required this.keys});

  factory SetSessionKeys._decode(_i1.Input input) {
    return SetSessionKeys(keys: _i3.SessionKeys.codec.decode(input));
  }

  /// T::Keys
  final _i3.SessionKeys keys;

  @override
  Map<String, Map<String, Map<String, List<int>>>> toJson() => {
        'set_session_keys': {'keys': keys.toJson()}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i3.SessionKeys.codec.sizeHint(keys);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i3.SessionKeys.codec.encodeTo(
      keys,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SetSessionKeys && other.keys == keys;

  @override
  int get hashCode => keys.hashCode;
}

/// Remove a member from the set of validators.
class RemoveMember extends Call {
  const RemoveMember({required this.memberId});

  factory RemoveMember._decode(_i1.Input input) {
    return RemoveMember(memberId: _i1.U32Codec.codec.decode(input));
  }

  /// T::MemberId
  final int memberId;

  @override
  Map<String, Map<String, int>> toJson() => {
        'remove_member': {'memberId': memberId}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(memberId);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      memberId,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is RemoveMember && other.memberId == memberId;

  @override
  int get hashCode => memberId.hashCode;
}

/// Remove a member from the blacklist.
/// remove an identity from the blacklist
class RemoveMemberFromBlacklist extends Call {
  const RemoveMemberFromBlacklist({required this.memberId});

  factory RemoveMemberFromBlacklist._decode(_i1.Input input) {
    return RemoveMemberFromBlacklist(
        memberId: _i1.U32Codec.codec.decode(input));
  }

  /// T::MemberId
  final int memberId;

  @override
  Map<String, Map<String, int>> toJson() => {
        'remove_member_from_blacklist': {'memberId': memberId}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(memberId);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      4,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      memberId,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is RemoveMemberFromBlacklist && other.memberId == memberId;

  @override
  int get hashCode => memberId.hashCode;
}
