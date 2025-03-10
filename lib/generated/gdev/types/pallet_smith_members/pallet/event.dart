// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// Events type.
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

  Map<String, Map<String, int>> toJson();
}

class $Event {
  const $Event();

  InvitationSent invitationSent({
    required int issuer,
    required int receiver,
  }) {
    return InvitationSent(
      issuer: issuer,
      receiver: receiver,
    );
  }

  InvitationAccepted invitationAccepted({required int idtyIndex}) {
    return InvitationAccepted(idtyIndex: idtyIndex);
  }

  SmithCertAdded smithCertAdded({
    required int issuer,
    required int receiver,
  }) {
    return SmithCertAdded(
      issuer: issuer,
      receiver: receiver,
    );
  }

  SmithCertRemoved smithCertRemoved({
    required int issuer,
    required int receiver,
  }) {
    return SmithCertRemoved(
      issuer: issuer,
      receiver: receiver,
    );
  }

  SmithMembershipAdded smithMembershipAdded({required int idtyIndex}) {
    return SmithMembershipAdded(idtyIndex: idtyIndex);
  }

  SmithMembershipRemoved smithMembershipRemoved({required int idtyIndex}) {
    return SmithMembershipRemoved(idtyIndex: idtyIndex);
  }
}

class $EventCodec with _i1.Codec<Event> {
  const $EventCodec();

  @override
  Event decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return InvitationSent._decode(input);
      case 1:
        return InvitationAccepted._decode(input);
      case 2:
        return SmithCertAdded._decode(input);
      case 3:
        return SmithCertRemoved._decode(input);
      case 4:
        return SmithMembershipAdded._decode(input);
      case 5:
        return SmithMembershipRemoved._decode(input);
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
      case InvitationSent:
        (value as InvitationSent).encodeTo(output);
        break;
      case InvitationAccepted:
        (value as InvitationAccepted).encodeTo(output);
        break;
      case SmithCertAdded:
        (value as SmithCertAdded).encodeTo(output);
        break;
      case SmithCertRemoved:
        (value as SmithCertRemoved).encodeTo(output);
        break;
      case SmithMembershipAdded:
        (value as SmithMembershipAdded).encodeTo(output);
        break;
      case SmithMembershipRemoved:
        (value as SmithMembershipRemoved).encodeTo(output);
        break;
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Event value) {
    switch (value.runtimeType) {
      case InvitationSent:
        return (value as InvitationSent)._sizeHint();
      case InvitationAccepted:
        return (value as InvitationAccepted)._sizeHint();
      case SmithCertAdded:
        return (value as SmithCertAdded)._sizeHint();
      case SmithCertRemoved:
        return (value as SmithCertRemoved)._sizeHint();
      case SmithMembershipAdded:
        return (value as SmithMembershipAdded)._sizeHint();
      case SmithMembershipRemoved:
        return (value as SmithMembershipRemoved)._sizeHint();
      default:
        throw Exception(
            'Event: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// An identity is being inivited to become a smith.
class InvitationSent extends Event {
  const InvitationSent({
    required this.issuer,
    required this.receiver,
  });

  factory InvitationSent._decode(_i1.Input input) {
    return InvitationSent(
      issuer: _i1.U32Codec.codec.decode(input),
      receiver: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int issuer;

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'InvitationSent': {
          'issuer': issuer,
          'receiver': receiver,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(issuer);
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      issuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      receiver,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is InvitationSent &&
          other.issuer == issuer &&
          other.receiver == receiver;

  @override
  int get hashCode => Object.hash(
        issuer,
        receiver,
      );
}

/// The invitation has been accepted.
class InvitationAccepted extends Event {
  const InvitationAccepted({required this.idtyIndex});

  factory InvitationAccepted._decode(_i1.Input input) {
    return InvitationAccepted(idtyIndex: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int idtyIndex;

  @override
  Map<String, Map<String, int>> toJson() => {
        'InvitationAccepted': {'idtyIndex': idtyIndex}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
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
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is InvitationAccepted && other.idtyIndex == idtyIndex;

  @override
  int get hashCode => idtyIndex.hashCode;
}

/// Certification received
class SmithCertAdded extends Event {
  const SmithCertAdded({
    required this.issuer,
    required this.receiver,
  });

  factory SmithCertAdded._decode(_i1.Input input) {
    return SmithCertAdded(
      issuer: _i1.U32Codec.codec.decode(input),
      receiver: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int issuer;

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'SmithCertAdded': {
          'issuer': issuer,
          'receiver': receiver,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(issuer);
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      issuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      receiver,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SmithCertAdded &&
          other.issuer == issuer &&
          other.receiver == receiver;

  @override
  int get hashCode => Object.hash(
        issuer,
        receiver,
      );
}

/// Certification lost
class SmithCertRemoved extends Event {
  const SmithCertRemoved({
    required this.issuer,
    required this.receiver,
  });

  factory SmithCertRemoved._decode(_i1.Input input) {
    return SmithCertRemoved(
      issuer: _i1.U32Codec.codec.decode(input),
      receiver: _i1.U32Codec.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int issuer;

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'SmithCertRemoved': {
          'issuer': issuer,
          'receiver': receiver,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(issuer);
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      issuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      receiver,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SmithCertRemoved &&
          other.issuer == issuer &&
          other.receiver == receiver;

  @override
  int get hashCode => Object.hash(
        issuer,
        receiver,
      );
}

/// A smith gathered enough certifications to become an authority (can call `go_online()`).
class SmithMembershipAdded extends Event {
  const SmithMembershipAdded({required this.idtyIndex});

  factory SmithMembershipAdded._decode(_i1.Input input) {
    return SmithMembershipAdded(idtyIndex: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int idtyIndex;

  @override
  Map<String, Map<String, int>> toJson() => {
        'SmithMembershipAdded': {'idtyIndex': idtyIndex}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
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
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SmithMembershipAdded && other.idtyIndex == idtyIndex;

  @override
  int get hashCode => idtyIndex.hashCode;
}

/// A smith has been removed from the smiths set.
class SmithMembershipRemoved extends Event {
  const SmithMembershipRemoved({required this.idtyIndex});

  factory SmithMembershipRemoved._decode(_i1.Input input) {
    return SmithMembershipRemoved(idtyIndex: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int idtyIndex;

  @override
  Map<String, Map<String, int>> toJson() => {
        'SmithMembershipRemoved': {'idtyIndex': idtyIndex}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
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
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SmithMembershipRemoved && other.idtyIndex == idtyIndex;

  @override
  int get hashCode => idtyIndex.hashCode;
}
