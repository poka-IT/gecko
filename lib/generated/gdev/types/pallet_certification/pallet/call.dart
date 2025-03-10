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

  Map<String, Map<String, int>> toJson();
}

class $Call {
  const $Call();

  AddCert addCert({required int receiver}) {
    return AddCert(receiver: receiver);
  }

  RenewCert renewCert({required int receiver}) {
    return RenewCert(receiver: receiver);
  }

  DelCert delCert({
    required int issuer,
    required int receiver,
  }) {
    return DelCert(
      issuer: issuer,
      receiver: receiver,
    );
  }

  RemoveAllCertsReceivedBy removeAllCertsReceivedBy({required int idtyIndex}) {
    return RemoveAllCertsReceivedBy(idtyIndex: idtyIndex);
  }
}

class $CallCodec with _i1.Codec<Call> {
  const $CallCodec();

  @override
  Call decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return AddCert._decode(input);
      case 3:
        return RenewCert._decode(input);
      case 1:
        return DelCert._decode(input);
      case 2:
        return RemoveAllCertsReceivedBy._decode(input);
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
      case AddCert:
        (value as AddCert).encodeTo(output);
        break;
      case RenewCert:
        (value as RenewCert).encodeTo(output);
        break;
      case DelCert:
        (value as DelCert).encodeTo(output);
        break;
      case RemoveAllCertsReceivedBy:
        (value as RemoveAllCertsReceivedBy).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case AddCert:
        return (value as AddCert)._sizeHint();
      case RenewCert:
        return (value as RenewCert)._sizeHint();
      case DelCert:
        return (value as DelCert)._sizeHint();
      case RemoveAllCertsReceivedBy:
        return (value as RemoveAllCertsReceivedBy)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Add a new certification.
class AddCert extends Call {
  const AddCert({required this.receiver});

  factory AddCert._decode(_i1.Input input) {
    return AddCert(receiver: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'add_cert': {'receiver': receiver}
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
      other is AddCert && other.receiver == receiver;

  @override
  int get hashCode => receiver.hashCode;
}

/// Renew an existing certification.
class RenewCert extends Call {
  const RenewCert({required this.receiver});

  factory RenewCert._decode(_i1.Input input) {
    return RenewCert(receiver: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int receiver;

  @override
  Map<String, Map<String, int>> toJson() => {
        'renew_cert': {'receiver': receiver}
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(receiver);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
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
      other is RenewCert && other.receiver == receiver;

  @override
  int get hashCode => receiver.hashCode;
}

/// Remove one certification given the issuer and the receiver.
///
/// - `origin`: Must be `Root`.
class DelCert extends Call {
  const DelCert({
    required this.issuer,
    required this.receiver,
  });

  factory DelCert._decode(_i1.Input input) {
    return DelCert(
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
        'del_cert': {
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
      1,
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
      other is DelCert && other.issuer == issuer && other.receiver == receiver;

  @override
  int get hashCode => Object.hash(
        issuer,
        receiver,
      );
}

/// Remove all certifications received by an identity.
///
/// - `origin`: Must be `Root`.
class RemoveAllCertsReceivedBy extends Call {
  const RemoveAllCertsReceivedBy({required this.idtyIndex});

  factory RemoveAllCertsReceivedBy._decode(_i1.Input input) {
    return RemoveAllCertsReceivedBy(
        idtyIndex: _i1.U32Codec.codec.decode(input));
  }

  /// T::IdtyIndex
  final int idtyIndex;

  @override
  Map<String, Map<String, int>> toJson() => {
        'remove_all_certs_received_by': {'idtyIndex': idtyIndex}
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
      other is RemoveAllCertsReceivedBy && other.idtyIndex == idtyIndex;

  @override
  int get hashCode => idtyIndex.hashCode;
}
