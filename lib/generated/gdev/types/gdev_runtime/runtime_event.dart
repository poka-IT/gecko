// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

import '../frame_system/pallet/event.dart' as _i3;
import '../pallet_atomic_swap/pallet/event.dart' as _i25;
import '../pallet_authority_members/pallet/event.dart' as _i11;
import '../pallet_balances/pallet/event.dart' as _i6;
import '../pallet_certification/pallet/event.dart' as _i23;
import '../pallet_collective/pallet/event.dart' as _i19;
import '../pallet_distance/pallet/event.dart' as _i24;
import '../pallet_duniter_account/pallet/event.dart' as _i4;
import '../pallet_grandpa/pallet/event.dart' as _i14;
import '../pallet_identity/pallet/event.dart' as _i21;
import '../pallet_im_online/pallet/event.dart' as _i15;
import '../pallet_membership/pallet/event.dart' as _i22;
import '../pallet_multisig/pallet/event.dart' as _i26;
import '../pallet_offences/pallet/event.dart' as _i12;
import '../pallet_oneshot_account/pallet/event.dart' as _i8;
import '../pallet_preimage/pallet/event.dart' as _i18;
import '../pallet_provide_randomness/pallet/event.dart' as _i27;
import '../pallet_proxy/pallet/event.dart' as _i28;
import '../pallet_quota/pallet/event.dart' as _i9;
import '../pallet_scheduler/pallet/event.dart' as _i5;
import '../pallet_session/pallet/event.dart' as _i13;
import '../pallet_smith_members/pallet/event.dart' as _i10;
import '../pallet_sudo/pallet/event.dart' as _i16;
import '../pallet_transaction_payment/pallet/event.dart' as _i7;
import '../pallet_treasury/pallet/event.dart' as _i30;
import '../pallet_universal_dividend/pallet/event.dart' as _i20;
import '../pallet_upgrade_origin/pallet/event.dart' as _i17;
import '../pallet_utility/pallet/event.dart' as _i29;

abstract class RuntimeEvent {
  const RuntimeEvent();

  factory RuntimeEvent.decode(_i1.Input input) {
    return codec.decode(input);
  }

  static const $RuntimeEventCodec codec = $RuntimeEventCodec();

  static const $RuntimeEvent values = $RuntimeEvent();

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

class $RuntimeEvent {
  const $RuntimeEvent();

  System system(_i3.Event value0) {
    return System(value0);
  }

  Account account(_i4.Event value0) {
    return Account(value0);
  }

  Scheduler scheduler(_i5.Event value0) {
    return Scheduler(value0);
  }

  Balances balances(_i6.Event value0) {
    return Balances(value0);
  }

  TransactionPayment transactionPayment(_i7.Event value0) {
    return TransactionPayment(value0);
  }

  OneshotAccount oneshotAccount(_i8.Event value0) {
    return OneshotAccount(value0);
  }

  Quota quota(_i9.Event value0) {
    return Quota(value0);
  }

  SmithMembers smithMembers(_i10.Event value0) {
    return SmithMembers(value0);
  }

  AuthorityMembers authorityMembers(_i11.Event value0) {
    return AuthorityMembers(value0);
  }

  Offences offences(_i12.Event value0) {
    return Offences(value0);
  }

  Session session(_i13.Event value0) {
    return Session(value0);
  }

  Grandpa grandpa(_i14.Event value0) {
    return Grandpa(value0);
  }

  ImOnline imOnline(_i15.Event value0) {
    return ImOnline(value0);
  }

  Sudo sudo(_i16.Event value0) {
    return Sudo(value0);
  }

  UpgradeOrigin upgradeOrigin(_i17.Event value0) {
    return UpgradeOrigin(value0);
  }

  Preimage preimage(_i18.Event value0) {
    return Preimage(value0);
  }

  TechnicalCommittee technicalCommittee(_i19.Event value0) {
    return TechnicalCommittee(value0);
  }

  UniversalDividend universalDividend(_i20.Event value0) {
    return UniversalDividend(value0);
  }

  Identity identity(_i21.Event value0) {
    return Identity(value0);
  }

  Membership membership(_i22.Event value0) {
    return Membership(value0);
  }

  Certification certification(_i23.Event value0) {
    return Certification(value0);
  }

  Distance distance(_i24.Event value0) {
    return Distance(value0);
  }

  AtomicSwap atomicSwap(_i25.Event value0) {
    return AtomicSwap(value0);
  }

  Multisig multisig(_i26.Event value0) {
    return Multisig(value0);
  }

  ProvideRandomness provideRandomness(_i27.Event value0) {
    return ProvideRandomness(value0);
  }

  Proxy proxy(_i28.Event value0) {
    return Proxy(value0);
  }

  Utility utility(_i29.Event value0) {
    return Utility(value0);
  }

  Treasury treasury(_i30.Event value0) {
    return Treasury(value0);
  }
}

class $RuntimeEventCodec with _i1.Codec<RuntimeEvent> {
  const $RuntimeEventCodec();

  @override
  RuntimeEvent decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return System._decode(input);
      case 1:
        return Account._decode(input);
      case 2:
        return Scheduler._decode(input);
      case 6:
        return Balances._decode(input);
      case 32:
        return TransactionPayment._decode(input);
      case 7:
        return OneshotAccount._decode(input);
      case 66:
        return Quota._decode(input);
      case 10:
        return SmithMembers._decode(input);
      case 11:
        return AuthorityMembers._decode(input);
      case 13:
        return Offences._decode(input);
      case 15:
        return Session._decode(input);
      case 16:
        return Grandpa._decode(input);
      case 17:
        return ImOnline._decode(input);
      case 20:
        return Sudo._decode(input);
      case 21:
        return UpgradeOrigin._decode(input);
      case 22:
        return Preimage._decode(input);
      case 23:
        return TechnicalCommittee._decode(input);
      case 30:
        return UniversalDividend._decode(input);
      case 41:
        return Identity._decode(input);
      case 42:
        return Membership._decode(input);
      case 43:
        return Certification._decode(input);
      case 44:
        return Distance._decode(input);
      case 50:
        return AtomicSwap._decode(input);
      case 51:
        return Multisig._decode(input);
      case 52:
        return ProvideRandomness._decode(input);
      case 53:
        return Proxy._decode(input);
      case 54:
        return Utility._decode(input);
      case 55:
        return Treasury._decode(input);
      default:
        throw Exception('RuntimeEvent: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    RuntimeEvent value,
    _i1.Output output,
  ) {
    switch (value.runtimeType) {
      case System:
        (value as System).encodeTo(output);
        break;
      case Account:
        (value as Account).encodeTo(output);
        break;
      case Scheduler:
        (value as Scheduler).encodeTo(output);
        break;
      case Balances:
        (value as Balances).encodeTo(output);
        break;
      case TransactionPayment:
        (value as TransactionPayment).encodeTo(output);
        break;
      case OneshotAccount:
        (value as OneshotAccount).encodeTo(output);
        break;
      case Quota:
        (value as Quota).encodeTo(output);
        break;
      case SmithMembers:
        (value as SmithMembers).encodeTo(output);
        break;
      case AuthorityMembers:
        (value as AuthorityMembers).encodeTo(output);
        break;
      case Offences:
        (value as Offences).encodeTo(output);
        break;
      case Session:
        (value as Session).encodeTo(output);
        break;
      case Grandpa:
        (value as Grandpa).encodeTo(output);
        break;
      case ImOnline:
        (value as ImOnline).encodeTo(output);
        break;
      case Sudo:
        (value as Sudo).encodeTo(output);
        break;
      case UpgradeOrigin:
        (value as UpgradeOrigin).encodeTo(output);
        break;
      case Preimage:
        (value as Preimage).encodeTo(output);
        break;
      case TechnicalCommittee:
        (value as TechnicalCommittee).encodeTo(output);
        break;
      case UniversalDividend:
        (value as UniversalDividend).encodeTo(output);
        break;
      case Identity:
        (value as Identity).encodeTo(output);
        break;
      case Membership:
        (value as Membership).encodeTo(output);
        break;
      case Certification:
        (value as Certification).encodeTo(output);
        break;
      case Distance:
        (value as Distance).encodeTo(output);
        break;
      case AtomicSwap:
        (value as AtomicSwap).encodeTo(output);
        break;
      case Multisig:
        (value as Multisig).encodeTo(output);
        break;
      case ProvideRandomness:
        (value as ProvideRandomness).encodeTo(output);
        break;
      case Proxy:
        (value as Proxy).encodeTo(output);
        break;
      case Utility:
        (value as Utility).encodeTo(output);
        break;
      case Treasury:
        (value as Treasury).encodeTo(output);
        break;
      default:
        throw Exception(
            'RuntimeEvent: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(RuntimeEvent value) {
    switch (value.runtimeType) {
      case System:
        return (value as System)._sizeHint();
      case Account:
        return (value as Account)._sizeHint();
      case Scheduler:
        return (value as Scheduler)._sizeHint();
      case Balances:
        return (value as Balances)._sizeHint();
      case TransactionPayment:
        return (value as TransactionPayment)._sizeHint();
      case OneshotAccount:
        return (value as OneshotAccount)._sizeHint();
      case Quota:
        return (value as Quota)._sizeHint();
      case SmithMembers:
        return (value as SmithMembers)._sizeHint();
      case AuthorityMembers:
        return (value as AuthorityMembers)._sizeHint();
      case Offences:
        return (value as Offences)._sizeHint();
      case Session:
        return (value as Session)._sizeHint();
      case Grandpa:
        return (value as Grandpa)._sizeHint();
      case ImOnline:
        return (value as ImOnline)._sizeHint();
      case Sudo:
        return (value as Sudo)._sizeHint();
      case UpgradeOrigin:
        return (value as UpgradeOrigin)._sizeHint();
      case Preimage:
        return (value as Preimage)._sizeHint();
      case TechnicalCommittee:
        return (value as TechnicalCommittee)._sizeHint();
      case UniversalDividend:
        return (value as UniversalDividend)._sizeHint();
      case Identity:
        return (value as Identity)._sizeHint();
      case Membership:
        return (value as Membership)._sizeHint();
      case Certification:
        return (value as Certification)._sizeHint();
      case Distance:
        return (value as Distance)._sizeHint();
      case AtomicSwap:
        return (value as AtomicSwap)._sizeHint();
      case Multisig:
        return (value as Multisig)._sizeHint();
      case ProvideRandomness:
        return (value as ProvideRandomness)._sizeHint();
      case Proxy:
        return (value as Proxy)._sizeHint();
      case Utility:
        return (value as Utility)._sizeHint();
      case Treasury:
        return (value as Treasury)._sizeHint();
      default:
        throw Exception(
            'RuntimeEvent: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

class System extends RuntimeEvent {
  const System(this.value0);

  factory System._decode(_i1.Input input) {
    return System(_i3.Event.codec.decode(input));
  }

  /// frame_system::Event<Runtime>
  final _i3.Event value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'System': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i3.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    _i3.Event.codec.encodeTo(
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
      other is System && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Account extends RuntimeEvent {
  const Account(this.value0);

  factory Account._decode(_i1.Input input) {
    return Account(_i4.Event.codec.decode(input));
  }

  /// pallet_duniter_account::Event<Runtime>
  final _i4.Event value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'Account': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i4.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i4.Event.codec.encodeTo(
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
      other is Account && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Scheduler extends RuntimeEvent {
  const Scheduler(this.value0);

  factory Scheduler._decode(_i1.Input input) {
    return Scheduler(_i5.Event.codec.decode(input));
  }

  /// pallet_scheduler::Event<Runtime>
  final _i5.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Scheduler': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i5.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      2,
      output,
    );
    _i5.Event.codec.encodeTo(
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
      other is Scheduler && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Balances extends RuntimeEvent {
  const Balances(this.value0);

  factory Balances._decode(_i1.Input input) {
    return Balances(_i6.Event.codec.decode(input));
  }

  /// pallet_balances::Event<Runtime>
  final _i6.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Balances': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i6.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      6,
      output,
    );
    _i6.Event.codec.encodeTo(
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
      other is Balances && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class TransactionPayment extends RuntimeEvent {
  const TransactionPayment(this.value0);

  factory TransactionPayment._decode(_i1.Input input) {
    return TransactionPayment(_i7.Event.codec.decode(input));
  }

  /// pallet_transaction_payment::Event<Runtime>
  final _i7.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'TransactionPayment': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i7.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      32,
      output,
    );
    _i7.Event.codec.encodeTo(
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
      other is TransactionPayment && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class OneshotAccount extends RuntimeEvent {
  const OneshotAccount(this.value0);

  factory OneshotAccount._decode(_i1.Input input) {
    return OneshotAccount(_i8.Event.codec.decode(input));
  }

  /// pallet_oneshot_account::Event<Runtime>
  final _i8.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'OneshotAccount': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i8.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      7,
      output,
    );
    _i8.Event.codec.encodeTo(
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
      other is OneshotAccount && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Quota extends RuntimeEvent {
  const Quota(this.value0);

  factory Quota._decode(_i1.Input input) {
    return Quota(_i9.Event.codec.decode(input));
  }

  /// pallet_quota::Event<Runtime>
  final _i9.Event value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'Quota': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i9.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      66,
      output,
    );
    _i9.Event.codec.encodeTo(
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
      other is Quota && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class SmithMembers extends RuntimeEvent {
  const SmithMembers(this.value0);

  factory SmithMembers._decode(_i1.Input input) {
    return SmithMembers(_i10.Event.codec.decode(input));
  }

  /// pallet_smith_members::Event<Runtime>
  final _i10.Event value0;

  @override
  Map<String, Map<String, Map<String, int>>> toJson() =>
      {'SmithMembers': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i10.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      10,
      output,
    );
    _i10.Event.codec.encodeTo(
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
      other is SmithMembers && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class AuthorityMembers extends RuntimeEvent {
  const AuthorityMembers(this.value0);

  factory AuthorityMembers._decode(_i1.Input input) {
    return AuthorityMembers(_i11.Event.codec.decode(input));
  }

  /// pallet_authority_members::Event<Runtime>
  final _i11.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'AuthorityMembers': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i11.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      11,
      output,
    );
    _i11.Event.codec.encodeTo(
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
      other is AuthorityMembers && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Offences extends RuntimeEvent {
  const Offences(this.value0);

  factory Offences._decode(_i1.Input input) {
    return Offences(_i12.Event.codec.decode(input));
  }

  /// pallet_offences::Event
  final _i12.Event value0;

  @override
  Map<String, Map<String, Map<String, List<int>>>> toJson() =>
      {'Offences': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i12.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      13,
      output,
    );
    _i12.Event.codec.encodeTo(
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
      other is Offences && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Session extends RuntimeEvent {
  const Session(this.value0);

  factory Session._decode(_i1.Input input) {
    return Session(_i13.Event.codec.decode(input));
  }

  /// pallet_session::Event
  final _i13.Event value0;

  @override
  Map<String, Map<String, Map<String, int>>> toJson() =>
      {'Session': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i13.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      15,
      output,
    );
    _i13.Event.codec.encodeTo(
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
      other is Session && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Grandpa extends RuntimeEvent {
  const Grandpa(this.value0);

  factory Grandpa._decode(_i1.Input input) {
    return Grandpa(_i14.Event.codec.decode(input));
  }

  /// pallet_grandpa::Event
  final _i14.Event value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'Grandpa': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i14.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      16,
      output,
    );
    _i14.Event.codec.encodeTo(
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
      other is Grandpa && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class ImOnline extends RuntimeEvent {
  const ImOnline(this.value0);

  factory ImOnline._decode(_i1.Input input) {
    return ImOnline(_i15.Event.codec.decode(input));
  }

  /// pallet_im_online::Event<Runtime>
  final _i15.Event value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'ImOnline': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i15.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      17,
      output,
    );
    _i15.Event.codec.encodeTo(
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
      other is ImOnline && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Sudo extends RuntimeEvent {
  const Sudo(this.value0);

  factory Sudo._decode(_i1.Input input) {
    return Sudo(_i16.Event.codec.decode(input));
  }

  /// pallet_sudo::Event<Runtime>
  final _i16.Event value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'Sudo': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i16.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      20,
      output,
    );
    _i16.Event.codec.encodeTo(
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
      other is Sudo && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class UpgradeOrigin extends RuntimeEvent {
  const UpgradeOrigin(this.value0);

  factory UpgradeOrigin._decode(_i1.Input input) {
    return UpgradeOrigin(_i17.Event.codec.decode(input));
  }

  /// pallet_upgrade_origin::Event
  final _i17.Event value0;

  @override
  Map<String, Map<String, Map<String, Map<String, dynamic>>>> toJson() =>
      {'UpgradeOrigin': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i17.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      21,
      output,
    );
    _i17.Event.codec.encodeTo(
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
      other is UpgradeOrigin && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Preimage extends RuntimeEvent {
  const Preimage(this.value0);

  factory Preimage._decode(_i1.Input input) {
    return Preimage(_i18.Event.codec.decode(input));
  }

  /// pallet_preimage::Event<Runtime>
  final _i18.Event value0;

  @override
  Map<String, Map<String, Map<String, List<int>>>> toJson() =>
      {'Preimage': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i18.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      22,
      output,
    );
    _i18.Event.codec.encodeTo(
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
      other is Preimage && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class TechnicalCommittee extends RuntimeEvent {
  const TechnicalCommittee(this.value0);

  factory TechnicalCommittee._decode(_i1.Input input) {
    return TechnicalCommittee(_i19.Event.codec.decode(input));
  }

  /// pallet_collective::Event<Runtime, pallet_collective::Instance2>
  final _i19.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'TechnicalCommittee': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i19.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      23,
      output,
    );
    _i19.Event.codec.encodeTo(
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
      other is TechnicalCommittee && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class UniversalDividend extends RuntimeEvent {
  const UniversalDividend(this.value0);

  factory UniversalDividend._decode(_i1.Input input) {
    return UniversalDividend(_i20.Event.codec.decode(input));
  }

  /// pallet_universal_dividend::Event<Runtime>
  final _i20.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'UniversalDividend': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i20.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      30,
      output,
    );
    _i20.Event.codec.encodeTo(
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
      other is UniversalDividend && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Identity extends RuntimeEvent {
  const Identity(this.value0);

  factory Identity._decode(_i1.Input input) {
    return Identity(_i21.Event.codec.decode(input));
  }

  /// pallet_identity::Event<Runtime>
  final _i21.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Identity': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i21.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      41,
      output,
    );
    _i21.Event.codec.encodeTo(
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
      other is Identity && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Membership extends RuntimeEvent {
  const Membership(this.value0);

  factory Membership._decode(_i1.Input input) {
    return Membership(_i22.Event.codec.decode(input));
  }

  /// pallet_membership::Event<Runtime>
  final _i22.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Membership': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i22.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      42,
      output,
    );
    _i22.Event.codec.encodeTo(
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
      other is Membership && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Certification extends RuntimeEvent {
  const Certification(this.value0);

  factory Certification._decode(_i1.Input input) {
    return Certification(_i23.Event.codec.decode(input));
  }

  /// pallet_certification::Event<Runtime>
  final _i23.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Certification': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i23.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      43,
      output,
    );
    _i23.Event.codec.encodeTo(
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
      other is Certification && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Distance extends RuntimeEvent {
  const Distance(this.value0);

  factory Distance._decode(_i1.Input input) {
    return Distance(_i24.Event.codec.decode(input));
  }

  /// pallet_distance::Event<Runtime>
  final _i24.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Distance': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i24.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      44,
      output,
    );
    _i24.Event.codec.encodeTo(
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
      other is Distance && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class AtomicSwap extends RuntimeEvent {
  const AtomicSwap(this.value0);

  factory AtomicSwap._decode(_i1.Input input) {
    return AtomicSwap(_i25.Event.codec.decode(input));
  }

  /// pallet_atomic_swap::Event<Runtime>
  final _i25.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'AtomicSwap': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i25.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      50,
      output,
    );
    _i25.Event.codec.encodeTo(
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
      other is AtomicSwap && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Multisig extends RuntimeEvent {
  const Multisig(this.value0);

  factory Multisig._decode(_i1.Input input) {
    return Multisig(_i26.Event.codec.decode(input));
  }

  /// pallet_multisig::Event<Runtime>
  final _i26.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Multisig': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i26.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      51,
      output,
    );
    _i26.Event.codec.encodeTo(
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
      other is Multisig && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class ProvideRandomness extends RuntimeEvent {
  const ProvideRandomness(this.value0);

  factory ProvideRandomness._decode(_i1.Input input) {
    return ProvideRandomness(_i27.Event.codec.decode(input));
  }

  /// pallet_provide_randomness::Event
  final _i27.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'ProvideRandomness': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i27.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      52,
      output,
    );
    _i27.Event.codec.encodeTo(
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
      other is ProvideRandomness && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Proxy extends RuntimeEvent {
  const Proxy(this.value0);

  factory Proxy._decode(_i1.Input input) {
    return Proxy(_i28.Event.codec.decode(input));
  }

  /// pallet_proxy::Event<Runtime>
  final _i28.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Proxy': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i28.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      53,
      output,
    );
    _i28.Event.codec.encodeTo(
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
      other is Proxy && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Utility extends RuntimeEvent {
  const Utility(this.value0);

  factory Utility._decode(_i1.Input input) {
    return Utility(_i29.Event.codec.decode(input));
  }

  /// pallet_utility::Event
  final _i29.Event value0;

  @override
  Map<String, Map<String, dynamic>> toJson() => {'Utility': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i29.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      54,
      output,
    );
    _i29.Event.codec.encodeTo(
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
      other is Utility && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}

class Treasury extends RuntimeEvent {
  const Treasury(this.value0);

  factory Treasury._decode(_i1.Input input) {
    return Treasury(_i30.Event.codec.decode(input));
  }

  /// pallet_treasury::Event<Runtime>
  final _i30.Event value0;

  @override
  Map<String, Map<String, Map<String, dynamic>>> toJson() =>
      {'Treasury': value0.toJson()};

  int _sizeHint() {
    int size = 1;
    size = size + _i30.Event.codec.sizeHint(value0);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      55,
      output,
    );
    _i30.Event.codec.encodeTo(
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
      other is Treasury && other.value0 == value0;

  @override
  int get hashCode => value0.hashCode;
}
