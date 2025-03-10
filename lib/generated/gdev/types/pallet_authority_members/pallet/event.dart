// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i3;

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

  IncomingAuthorities incomingAuthorities({required List<int> members}) {
    return IncomingAuthorities(members: members);
  }

  OutgoingAuthorities outgoingAuthorities({required List<int> members}) {
    return OutgoingAuthorities(members: members);
  }

  MemberGoOffline memberGoOffline({required int member}) {
    return MemberGoOffline(member: member);
  }

  MemberGoOnline memberGoOnline({required int member}) {
    return MemberGoOnline(member: member);
  }

  MemberRemoved memberRemoved({required int member}) {
    return MemberRemoved(member: member);
  }

  MemberRemovedFromBlacklist memberRemovedFromBlacklist({required int member}) {
    return MemberRemovedFromBlacklist(member: member);
  }

  MemberAddedToBlacklist memberAddedToBlacklist({required int member}) {
    return MemberAddedToBlacklist(member: member);
  }
}

class $EventCodec with _i1.Codec<Event> {
  const $EventCodec();

  @override
  Event decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return IncomingAuthorities._decode(input);
      case 1:
        return OutgoingAuthorities._decode(input);
      case 2:
        return MemberGoOffline._decode(input);
      case 3:
        return MemberGoOnline._decode(input);
      case 4:
        return MemberRemoved._decode(input);
      case 5:
        return MemberRemovedFromBlacklist._decode(input);
      case 6:
        return MemberAddedToBlacklist._decode(input);
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
      case IncomingAuthorities:
        (value as IncomingAuthorities).encodeTo(output);
        break;
      case OutgoingAuthorities:
        (value as OutgoingAuthorities).encodeTo(output);
        break;
      case MemberGoOffline:
        (value as MemberGoOffline).encodeTo(output);
        break;
      case MemberGoOnline:
        (value as MemberGoOnline).encodeTo(output);
        break;
      case MemberRemoved:
        (value as MemberRemoved).encodeTo(output);
        break;
      case MemberRemovedFromBlacklist:
        (value as MemberRemovedFromBlacklist).encodeTo(output);
        break;
      case MemberAddedToBlacklist:
        (value as MemberAddedToBlacklist).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case IncomingAuthorities:
        return (value as IncomingAuthorities)._sizeHint();
      case OutgoingAuthorities:
        return (value as OutgoingAuthorities)._sizeHint();
      case MemberGoOffline:
        return (value as MemberGoOffline)._sizeHint();
      case MemberGoOnline:
        return (value as MemberGoOnline)._sizeHint();
      case MemberRemoved:
        return (value as MemberRemoved)._sizeHint();
      case MemberRemovedFromBlacklist:
        return (value as MemberRemovedFromBlacklist)._sizeHint();
      case MemberAddedToBlacklist:
        return (value as MemberAddedToBlacklist)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// List of members scheduled to join the set of authorities in the next session.
class IncomingAuthorities extends Event {
  const IncomingAuthorities({required this.members});

  factory IncomingAuthorities._decode(_i1.Input input) {
    return IncomingAuthorities(
        members: _i1.U32SequenceCodec.codec.decode(input));
  }

  /// Vec<T::MemberId>
  final List<int> members;

  @override
  Map<String, Map<String, List<int>>> toJson() => {
        'IncomingAuthorities': {'members': members}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32SequenceCodec.codec.sizeHint(members);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U32SequenceCodec.codec.encodeTo(
      members,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is IncomingAuthorities &&
          _i3.listsEqual(
            other.members,
            members,
          );

  @override
  int get hashCode => members.hashCode;
}

/// List of members leaving the set of authorities in the next session.
class OutgoingAuthorities extends Event {
  const OutgoingAuthorities({required this.members});

  factory OutgoingAuthorities._decode(_i1.Input input) {
    return OutgoingAuthorities(
        members: _i1.U32SequenceCodec.codec.decode(input));
  }

  /// Vec<T::MemberId>
  final List<int> members;

  @override
  Map<String, Map<String, List<int>>> toJson() => {
        'OutgoingAuthorities': {'members': members}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32SequenceCodec.codec.sizeHint(members);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U32SequenceCodec.codec.encodeTo(
      members,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is OutgoingAuthorities &&
          _i3.listsEqual(
            other.members,
            members,
          );

  @override
  int get hashCode => members.hashCode;
}

/// A member will leave the set of authorities in 2 sessions.
class MemberGoOffline extends Event {
  const MemberGoOffline({required this.member});

  factory MemberGoOffline._decode(_i1.Input input) {
    return MemberGoOffline(member: _i1.U32Codec.codec.decode(input));
  }

  /// T::MemberId
  final int member;

  @override
  Map<String, Map<String, int>> toJson() => {
        'MemberGoOffline': {'member': member}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      member,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MemberGoOffline && other.member == member;

  @override
  int get hashCode => member.hashCode;
}

/// A member will join the set of authorities in 2 sessions.
class MemberGoOnline extends Event {
  const MemberGoOnline({required this.member});

  factory MemberGoOnline._decode(_i1.Input input) {
    return MemberGoOnline(member: _i1.U32Codec.codec.decode(input));
  }

  /// T::MemberId
  final int member;

  @override
  Map<String, Map<String, int>> toJson() => {
        'MemberGoOnline': {'member': member}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      member,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MemberGoOnline && other.member == member;

  @override
  int get hashCode => member.hashCode;
}

/// A member, who no longer has authority rights, will be removed from the authority set in 2 sessions.
class MemberRemoved extends Event {
  const MemberRemoved({required this.member});

  factory MemberRemoved._decode(_i1.Input input) {
    return MemberRemoved(member: _i1.U32Codec.codec.decode(input));
  }

  /// T::MemberId
  final int member;

  @override
  Map<String, Map<String, int>> toJson() => {
        'MemberRemoved': {'member': member}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      4,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      member,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MemberRemoved && other.member == member;

  @override
  int get hashCode => member.hashCode;
}

/// A member has been removed from the blacklist.
class MemberRemovedFromBlacklist extends Event {
  const MemberRemovedFromBlacklist({required this.member});

  factory MemberRemovedFromBlacklist._decode(_i1.Input input) {
    return MemberRemovedFromBlacklist(member: _i1.U32Codec.codec.decode(input));
  }

  /// T::MemberId
  final int member;

  @override
  Map<String, Map<String, int>> toJson() => {
        'MemberRemovedFromBlacklist': {'member': member}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      5,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      member,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MemberRemovedFromBlacklist && other.member == member;

  @override
  int get hashCode => member.hashCode;
}

/// A member has been blacklisted.
class MemberAddedToBlacklist extends Event {
  const MemberAddedToBlacklist({required this.member});

  factory MemberAddedToBlacklist._decode(_i1.Input input) {
    return MemberAddedToBlacklist(member: _i1.U32Codec.codec.decode(input));
  }

  /// T::MemberId
  final int member;

  @override
  Map<String, Map<String, int>> toJson() => {
        'MemberAddedToBlacklist': {'member': member}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      6,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      member,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MemberAddedToBlacklist && other.member == member;

  @override
  int get hashCode => member.hashCode;
}
