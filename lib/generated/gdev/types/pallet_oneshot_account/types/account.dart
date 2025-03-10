// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../../sp_runtime/multiaddress/multi_address.dart' as _i3;

abstract class Account {
  const Account();

  factory Account.decode(_i1.Input input) {
    return codec.decode(input);
  }

  static const $AccountCodec codec = $AccountCodec();

  static const $Account values = $Account();

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

class $Account {
  const $Account();

  Normal normal(_i3.MultiAddress value0) {
    return Normal(value0);
  }

  Oneshot oneshot(_i3.MultiAddress value0) {
    return Oneshot(value0);
  }
}

class $AccountCodec with _i1.Codec<Account> {
  const $AccountCodec();

  @override
  Account decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return Normal._decode(input);
      case 1:
        return Oneshot._decode(input);
      default:
        throw Exception('Account: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Account value,
    _i1.Output output,
  ) {
    switch (value.runtimeType) {
      case Normal:
        (value as Normal).encodeTo(output);
        break;
      case Oneshot:
        (value as Oneshot).encodeTo(output);
        break;
      default:
        throw Exception(
            'Account: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Account value) {
    switch (value.runtimeType) {
      case Normal:
        return (value as Normal)._sizeHint();
      case Oneshot:
        return (value as Oneshot)._sizeHint();
      default:
        throw Exception(
            'Account: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

class Normal extends Account {
  const Normal(this.value0);

  factory Normal._decode(_i1.Input input) {
    return Normal(_i3.MultiAddress.codec.decode(input));
  }

  /// AccountId
  final _i3.MultiAddress value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'Normal': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i3.MultiAddress.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i3.MultiAddress.codec.encodeTo(
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
      other is Normal && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Oneshot extends Account {
  const Oneshot(this.value0);

  factory Oneshot._decode(_i1.Input input) {
    return Oneshot(_i3.MultiAddress.codec.decode(input));
  }

  /// AccountId
  final _i3.MultiAddress value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'Oneshot': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i3.MultiAddress.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i3.MultiAddress.codec.encodeTo(
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
      other is Oneshot && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}
