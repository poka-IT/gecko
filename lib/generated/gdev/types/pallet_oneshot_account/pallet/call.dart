// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../../sp_runtime/multiaddress/multi_address.dart' as _i3;
import '../types/account.dart' as _i4;

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

  Map<String, Map<String, dynamic>> toJson();
}

class $Call {
  const $Call();

  CreateOneshotAccount createOneshotAccount({
    required _i3.MultiAddress dest,
    required BigInt value,
  }) {
    return CreateOneshotAccount(
      dest: dest,
      value: value,
    );
  }

  ConsumeOneshotAccount consumeOneshotAccount({
    required int blockHeight,
    required _i4.Account dest,
  }) {
    return ConsumeOneshotAccount(
      blockHeight: blockHeight,
      dest: dest,
    );
  }

  ConsumeOneshotAccountWithRemaining consumeOneshotAccountWithRemaining({
    required int blockHeight,
    required _i4.Account dest,
    required _i4.Account remainingTo,
    required BigInt balance,
  }) {
    return ConsumeOneshotAccountWithRemaining(
      blockHeight: blockHeight,
      dest: dest,
      remainingTo: remainingTo,
      balance: balance,
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
        return CreateOneshotAccount._decode(input);
      case 1:
        return ConsumeOneshotAccount._decode(input);
      case 2:
        return ConsumeOneshotAccountWithRemaining._decode(input);
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
      case CreateOneshotAccount:
        (value as CreateOneshotAccount).encodeTo(output);
        break;
      case ConsumeOneshotAccount:
        (value as ConsumeOneshotAccount).encodeTo(output);
        break;
      case ConsumeOneshotAccountWithRemaining:
        (value as ConsumeOneshotAccountWithRemaining).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case CreateOneshotAccount:
        return (value as CreateOneshotAccount)._sizeHint();
      case ConsumeOneshotAccount:
        return (value as ConsumeOneshotAccount)._sizeHint();
      case ConsumeOneshotAccountWithRemaining:
        return (value as ConsumeOneshotAccountWithRemaining)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Create an account that can only be consumed once
///
/// - `dest`: The oneshot account to be created.
/// - `balance`: The balance to be transfered to this oneshot account.
///
/// Origin account is kept alive.
class CreateOneshotAccount extends Call {
  const CreateOneshotAccount({
    required this.dest,
    required this.value,
  });

  factory CreateOneshotAccount._decode(_i1.Input input) {
    return CreateOneshotAccount(
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
        'create_oneshot_account': {
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
      0,
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
      other is CreateOneshotAccount &&
          other.dest == dest &&
          other.value == value;

  @override
  int get hashCode => Object.hash(
        dest,
        value,
      );
}

/// Consume a oneshot account and transfer its balance to an account
///
/// - `block_height`: Must be a recent block number. The limit is `BlockHashCount` in the past. (this is to prevent replay attacks)
/// - `dest`: The destination account.
/// - `dest_is_oneshot`: If set to `true`, then a oneshot account is created at `dest`. Else, `dest` has to be an existing account.
class ConsumeOneshotAccount extends Call {
  const ConsumeOneshotAccount({
    required this.blockHeight,
    required this.dest,
  });

  factory ConsumeOneshotAccount._decode(_i1.Input input) {
    return ConsumeOneshotAccount(
      blockHeight: _i1.U32Codec.codec.decode(input),
      dest: _i4.Account.codec.decode(input),
    );
  }

  /// BlockNumberFor<T>
  final int blockHeight;

  /// Account<<T::Lookup as StaticLookup>::Source>
  final _i4.Account dest;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'consume_oneshot_account': {
          'blockHeight': blockHeight,
          'dest': dest.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(blockHeight);
    size = size + _i4.Account.codec.sizeHint(dest);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      blockHeight,
      output,
    );
    _i4.Account.codec.encodeTo(
      dest,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ConsumeOneshotAccount &&
          other.blockHeight == blockHeight &&
          other.dest == dest;

  @override
  int get hashCode => Object.hash(
        blockHeight,
        dest,
      );
}

/// Consume a oneshot account then transfer some amount to an account,
/// and the remaining amount to another account.
///
/// - `block_height`: Must be a recent block number.
///  The limit is `BlockHashCount` in the past. (this is to prevent replay attacks)
/// - `dest`: The destination account.
/// - `dest_is_oneshot`: If set to `true`, then a oneshot account is created at `dest`. Else, `dest` has to be an existing account.
/// - `dest2`: The second destination account.
/// - `dest2_is_oneshot`: If set to `true`, then a oneshot account is created at `dest2`. Else, `dest2` has to be an existing account.
/// - `balance1`: The amount transfered to `dest`, the leftover being transfered to `dest2`.
class ConsumeOneshotAccountWithRemaining extends Call {
  const ConsumeOneshotAccountWithRemaining({
    required this.blockHeight,
    required this.dest,
    required this.remainingTo,
    required this.balance,
  });

  factory ConsumeOneshotAccountWithRemaining._decode(_i1.Input input) {
    return ConsumeOneshotAccountWithRemaining(
      blockHeight: _i1.U32Codec.codec.decode(input),
      dest: _i4.Account.codec.decode(input),
      remainingTo: _i4.Account.codec.decode(input),
      balance: _i1.CompactBigIntCodec.codec.decode(input),
    );
  }

  /// BlockNumberFor<T>
  final int blockHeight;

  /// Account<<T::Lookup as StaticLookup>::Source>
  final _i4.Account dest;

  /// Account<<T::Lookup as StaticLookup>::Source>
  final _i4.Account remainingTo;

  /// BalanceOf<T>
  final BigInt balance;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'consume_oneshot_account_with_remaining': {
          'blockHeight': blockHeight,
          'dest': dest.toJson(),
          'remainingTo': remainingTo.toJson(),
          'balance': balance,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(blockHeight);
    size = size + _i4.Account.codec.sizeHint(dest);
    size = size + _i4.Account.codec.sizeHint(remainingTo);
    size = size + _i1.CompactBigIntCodec.codec.sizeHint(balance);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      blockHeight,
      output,
    );
    _i4.Account.codec.encodeTo(
      dest,
      output,
    );
    _i4.Account.codec.encodeTo(
      remainingTo,
      output,
    );
    _i1.CompactBigIntCodec.codec.encodeTo(
      balance,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ConsumeOneshotAccountWithRemaining &&
          other.blockHeight == blockHeight &&
          other.dest == dest &&
          other.remainingTo == remainingTo &&
          other.balance == balance;

  @override
  int get hashCode => Object.hash(
        blockHeight,
        dest,
        remainingTo,
        balance,
      );
}
