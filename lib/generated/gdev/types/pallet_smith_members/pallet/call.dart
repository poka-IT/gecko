// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

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

  InviteSmith inviteSmith({required int receiver}) {
    return InviteSmith(receiver: receiver);
  }

  AcceptInvitation acceptInvitation() {
    return AcceptInvitation();
  }

  CertifySmith certifySmith({required int receiver}) {
    return CertifySmith(receiver: receiver);
  }
}

class $CallCodec with _i1.Codec<Call> {
  const $CallCodec();

  @override
  Call decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return InviteSmith._decode(input);
      case 1:
        return const AcceptInvitation();
      case 2:
        return CertifySmith._decode(input);
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
      case InviteSmith:
        (value as InviteSmith).encodeTo(output);
        break;
      case AcceptInvitation:
        (value as AcceptInvitation).encodeTo(output);
        break;
      case CertifySmith:
        (value as CertifySmith).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case InviteSmith:
        return (value as InviteSmith)._sizeHint();
      case AcceptInvitation:
        return 1;
      case CertifySmith:
        return (value as CertifySmith)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Invite a member of the Web of Trust to attempt becoming a Smith.
class InviteSmith extends Call {
  const InviteSmith({required this.receiver});

  factory InviteSmith._decode(_i1.Input input) {
    return InviteSmith(receiver: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'invite_smith': {'receiver': receiver}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
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
      other is InviteSmith && other.receiver == receiver;

  @override
  int get hashCode => receiver.hashCode;
}

/// Accept an invitation to become a Smith (must have been invited first).
class AcceptInvitation extends Call {
  const AcceptInvitation();

  @override
  Map<String, dynamic> toJson() => {'accept_invitation': null};

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
  }

  @override
  bool operator ==(Object other) => other is AcceptInvitation;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Certify an invited Smith, which can lead the certified to become a Smith.
class CertifySmith extends Call {
  const CertifySmith({required this.receiver});

  factory CertifySmith._decode(_i1.Input input) {
    return CertifySmith(receiver: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'certify_smith': {'receiver': receiver}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
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
      other is CertifySmith && other.receiver == receiver;

  @override
  int get hashCode => receiver.hashCode;
}
