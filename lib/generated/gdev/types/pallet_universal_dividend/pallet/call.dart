// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../../sp_runtime/multiaddress/multi_address.dart' as _i3;

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

  ClaimUds claimUds() {
    return ClaimUds();
  }

  TransferUd transferUd({
    required _i3.MultiAddress dest,
    required BigInt value,
  }) {
    return TransferUd(
      dest: dest,
      value: value,
    );
  }

  TransferUdKeepAlive transferUdKeepAlive({
    required _i3.MultiAddress dest,
    required BigInt value,
  }) {
    return TransferUdKeepAlive(
      dest: dest,
      value: value,
    );
  }
}

class $CallCodec with _i1.Codec<Call> {
  const $CallCodec();

  @override
  Call decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return const ClaimUds();
      case 1:
        return TransferUd._decode(input);
      case 2:
        return TransferUdKeepAlive._decode(input);
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
      case ClaimUds:
        (value as ClaimUds).encodeTo(output);
        break;
      case TransferUd:
        (value as TransferUd).encodeTo(output);
        break;
      case TransferUdKeepAlive:
        (value as TransferUdKeepAlive).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case ClaimUds:
        return 1;
      case TransferUd:
        return (value as TransferUd)._sizeHint();
      case TransferUdKeepAlive:
        return (value as TransferUdKeepAlive)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Claim Universal Dividends.
class ClaimUds extends Call {
  const ClaimUds();

  @override
  Map<String, dynamic> toJson() => {'claim_uds': null};

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
  }

  @override
  bool operator ==(Object other) => other is ClaimUds;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Transfer some liquid free balance to another account, in milliUD.
class TransferUd extends Call {
  const TransferUd({
    required this.dest,
    required this.value,
  });

  factory TransferUd._decode(_i1.Input input) {
    return TransferUd(
      dest: _i3.MultiAddress.codec.decode(input),
      value: _i1.CompactBigIntCodec.codec.decode(input),
    );
  }

  /// <T::Lookup as StaticLookup>::Source
  final _i3.MultiAddress dest;

  /// BalanceOf<T>
  final BigInt value;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'transfer_ud': {
          'dest': dest.toJson(),
          'value': value,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i3.MultiAddress.codec.sizeHint(dest);
    size = size + _i1.CompactBigIntCodec.codec.sizeHint(value);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i3.MultiAddress.codec.encodeTo(
      dest,
      output,
    );
    _i1.CompactBigIntCodec.codec.encodeTo(
      value,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is TransferUd && other.dest == dest && other.value == value;

  @override
  int get hashCode => Object.hash(
        dest,
        value,
      );
}

/// Transfer some liquid free balance to another account in milliUD and keep the account alive.
class TransferUdKeepAlive extends Call {
  const TransferUdKeepAlive({
    required this.dest,
    required this.value,
  });

  factory TransferUdKeepAlive._decode(_i1.Input input) {
    return TransferUdKeepAlive(
      dest: _i3.MultiAddress.codec.decode(input),
      value: _i1.CompactBigIntCodec.codec.decode(input),
    );
  }

  /// <T::Lookup as StaticLookup>::Source
  final _i3.MultiAddress dest;

  /// BalanceOf<T>
  final BigInt value;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'transfer_ud_keep_alive': {
          'dest': dest.toJson(),
          'value': value,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i3.MultiAddress.codec.sizeHint(dest);
    size = size + _i1.CompactBigIntCodec.codec.sizeHint(value);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i3.MultiAddress.codec.encodeTo(
      dest,
      output,
    );
    _i1.CompactBigIntCodec.codec.encodeTo(
      value,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is TransferUdKeepAlive &&
          other.dest == dest &&
          other.value == value;

  @override
  int get hashCode => Object.hash(
        dest,
        value,
      );
}
