// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../membership_removal_reason.dart' as _i3;

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

  MembershipAdded membershipAdded({
    required int member,
    required int expireOn,
  }) {
    return MembershipAdded(
      member: member,
      expireOn: expireOn,
    );
  }

  MembershipRenewed membershipRenewed({
    required int member,
    required int expireOn,
  }) {
    return MembershipRenewed(
      member: member,
      expireOn: expireOn,
    );
  }

  MembershipRemoved membershipRemoved({
    required int member,
    required _i3.MembershipRemovalReason reason,
  }) {
    return MembershipRemoved(
      member: member,
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
        return MembershipAdded._decode(input);
      case 1:
        return MembershipRenewed._decode(input);
      case 2:
        return MembershipRemoved._decode(input);
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
      case MembershipAdded:
        (value as MembershipAdded).encodeTo(output);
        break;
      case MembershipRenewed:
        (value as MembershipRenewed).encodeTo(output);
        break;
      case MembershipRemoved:
        (value as MembershipRemoved).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case MembershipAdded:
        return (value as MembershipAdded)._sizeHint();
      case MembershipRenewed:
        return (value as MembershipRenewed)._sizeHint();
      case MembershipRemoved:
        return (value as MembershipRemoved)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// A membership was added.
class MembershipAdded extends Event {
  const MembershipAdded({
    required this.member,
    required this.expireOn,
  });

  factory MembershipAdded._decode(_i1.Input input) {
    return MembershipAdded(
      member: _i1.U32Codec.codec.decode(input),
      expireOn: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyId
  final int member;

  /// BlockNumberFor<T>
  final int expireOn;

  @override
  Map<String, Map<String, int>> toJson() => {
        'MembershipAdded': {
          'member': member,
          'expireOn': expireOn,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    size = size + _i1.U32Codec.codec.sizeHint(expireOn);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      member,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      expireOn,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MembershipAdded &&
          other.member == member &&
          other.expireOn == expireOn;

  @override
  int get hashCode => Object.hash(
        member,
        expireOn,
      );
}

/// A membership was renewed.
class MembershipRenewed extends Event {
  const MembershipRenewed({
    required this.member,
    required this.expireOn,
  });

  factory MembershipRenewed._decode(_i1.Input input) {
    return MembershipRenewed(
      member: _i1.U32Codec.codec.decode(input),
      expireOn: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyId
  final int member;

  /// BlockNumberFor<T>
  final int expireOn;

  @override
  Map<String, Map<String, int>> toJson() => {
        'MembershipRenewed': {
          'member': member,
          'expireOn': expireOn,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    size = size + _i1.U32Codec.codec.sizeHint(expireOn);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      member,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      expireOn,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is MembershipRenewed &&
          other.member == member &&
          other.expireOn == expireOn;

  @override
  int get hashCode => Object.hash(
        member,
        expireOn,
      );
}

/// A membership was removed.
class MembershipRemoved extends Event {
  const MembershipRemoved({
    required this.member,
    required this.reason,
  });

  factory MembershipRemoved._decode(_i1.Input input) {
    return MembershipRemoved(
      member: _i1.U32Codec.codec.decode(input),
      reason: _i3.MembershipRemovalReason.codec.decode(input),
    );
  }

  /// T::IdtyId
  final int member;

  /// MembershipRemovalReason
  final _i3.MembershipRemovalReason reason;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'MembershipRemoved': {
          'member': member,
          'reason': reason.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(member);
    size = size + _i3.MembershipRemovalReason.codec.sizeHint(reason);
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
    _i3.MembershipRemovalReason.codec.encodeTo(
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
      other is MembershipRemoved &&
          other.member == member &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(
        member,
        reason,
      );
}
