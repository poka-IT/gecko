// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i37;

import 'package:polkadart/polkadart.dart' as _i1;

import 'pallets/account.dart' as _i33;
import 'pallets/atomic_swap.dart' as _i28;
import 'pallets/authority_discovery.dart' as _i19;
import 'pallets/authority_members.dart' as _i12;
import 'pallets/authorship.dart' as _i13;
import 'pallets/babe.dart' as _i4;
import 'pallets/balances.dart' as _i7;
import 'pallets/certification.dart' as _i26;
import 'pallets/distance.dart' as _i27;
import 'pallets/grandpa.dart' as _i17;
import 'pallets/historical.dart' as _i15;
import 'pallets/identity.dart' as _i24;
import 'pallets/im_online.dart' as _i18;
import 'pallets/membership.dart' as _i25;
import 'pallets/multisig.dart' as _i29;
import 'pallets/offences.dart' as _i14;
import 'pallets/oneshot_account.dart' as _i9;
import 'pallets/parameters.dart' as _i6;
import 'pallets/preimage.dart' as _i21;
import 'pallets/provide_randomness.dart' as _i30;
import 'pallets/proxy.dart' as _i31;
import 'pallets/quota.dart' as _i10;
import 'pallets/scheduler.dart' as _i3;
import 'pallets/session.dart' as _i16;
import 'pallets/smith_members.dart' as _i11;
import 'pallets/sudo.dart' as _i20;
import 'pallets/system.dart' as _i2;
import 'pallets/technical_committee.dart' as _i22;
import 'pallets/timestamp.dart' as _i5;
import 'pallets/transaction_payment.dart' as _i8;
import 'pallets/treasury.dart' as _i32;
import 'pallets/universal_dividend.dart' as _i23;
import 'pallets/upgrade_origin.dart' as _i34;
import 'pallets/utility.dart' as _i35;
import 'pallets/wot.dart' as _i36;

class Queries {
  Queries(_i1.StateApi api)
      : system = _i2.Queries(api),
        scheduler = _i3.Queries(api),
        babe = _i4.Queries(api),
        timestamp = _i5.Queries(api),
        parameters = _i6.Queries(api),
        balances = _i7.Queries(api),
        transactionPayment = _i8.Queries(api),
        oneshotAccount = _i9.Queries(api),
        quota = _i10.Queries(api),
        smithMembers = _i11.Queries(api),
        authorityMembers = _i12.Queries(api),
        authorship = _i13.Queries(api),
        offences = _i14.Queries(api),
        historical = _i15.Queries(api),
        session = _i16.Queries(api),
        grandpa = _i17.Queries(api),
        imOnline = _i18.Queries(api),
        authorityDiscovery = _i19.Queries(api),
        sudo = _i20.Queries(api),
        preimage = _i21.Queries(api),
        technicalCommittee = _i22.Queries(api),
        universalDividend = _i23.Queries(api),
        identity = _i24.Queries(api),
        membership = _i25.Queries(api),
        certification = _i26.Queries(api),
        distance = _i27.Queries(api),
        atomicSwap = _i28.Queries(api),
        multisig = _i29.Queries(api),
        provideRandomness = _i30.Queries(api),
        proxy = _i31.Queries(api),
        treasury = _i32.Queries(api);

  final _i2.Queries system;

  final _i3.Queries scheduler;

  final _i4.Queries babe;

  final _i5.Queries timestamp;

  final _i6.Queries parameters;

  final _i7.Queries balances;

  final _i8.Queries transactionPayment;

  final _i9.Queries oneshotAccount;

  final _i10.Queries quota;

  final _i11.Queries smithMembers;

  final _i12.Queries authorityMembers;

  final _i13.Queries authorship;

  final _i14.Queries offences;

  final _i15.Queries historical;

  final _i16.Queries session;

  final _i17.Queries grandpa;

  final _i18.Queries imOnline;

  final _i19.Queries authorityDiscovery;

  final _i20.Queries sudo;

  final _i21.Queries preimage;

  final _i22.Queries technicalCommittee;

  final _i23.Queries universalDividend;

  final _i24.Queries identity;

  final _i25.Queries membership;

  final _i26.Queries certification;

  final _i27.Queries distance;

  final _i28.Queries atomicSwap;

  final _i29.Queries multisig;

  final _i30.Queries provideRandomness;

  final _i31.Queries proxy;

  final _i32.Queries treasury;
}

class Extrinsics {
  Extrinsics();

  final _i2.Txs system = _i2.Txs();

  final _i33.Txs account = _i33.Txs();

  final _i3.Txs scheduler = _i3.Txs();

  final _i4.Txs babe = _i4.Txs();

  final _i5.Txs timestamp = _i5.Txs();

  final _i7.Txs balances = _i7.Txs();

  final _i9.Txs oneshotAccount = _i9.Txs();

  final _i11.Txs smithMembers = _i11.Txs();

  final _i12.Txs authorityMembers = _i12.Txs();

  final _i16.Txs session = _i16.Txs();

  final _i17.Txs grandpa = _i17.Txs();

  final _i18.Txs imOnline = _i18.Txs();

  final _i20.Txs sudo = _i20.Txs();

  final _i34.Txs upgradeOrigin = _i34.Txs();

  final _i21.Txs preimage = _i21.Txs();

  final _i22.Txs technicalCommittee = _i22.Txs();

  final _i23.Txs universalDividend = _i23.Txs();

  final _i24.Txs identity = _i24.Txs();

  final _i26.Txs certification = _i26.Txs();

  final _i27.Txs distance = _i27.Txs();

  final _i28.Txs atomicSwap = _i28.Txs();

  final _i29.Txs multisig = _i29.Txs();

  final _i30.Txs provideRandomness = _i30.Txs();

  final _i31.Txs proxy = _i31.Txs();

  final _i35.Txs utility = _i35.Txs();

  final _i32.Txs treasury = _i32.Txs();
}

class Constants {
  Constants();

  final _i2.Constants system = _i2.Constants();

  final _i3.Constants scheduler = _i3.Constants();

  final _i4.Constants babe = _i4.Constants();

  final _i5.Constants timestamp = _i5.Constants();

  final _i7.Constants balances = _i7.Constants();

  final _i8.Constants transactionPayment = _i8.Constants();

  final _i10.Constants quota = _i10.Constants();

  final _i11.Constants smithMembers = _i11.Constants();

  final _i12.Constants authorityMembers = _i12.Constants();

  final _i17.Constants grandpa = _i17.Constants();

  final _i18.Constants imOnline = _i18.Constants();

  final _i22.Constants technicalCommittee = _i22.Constants();

  final _i23.Constants universalDividend = _i23.Constants();

  final _i36.Constants wot = _i36.Constants();

  final _i24.Constants identity = _i24.Constants();

  final _i25.Constants membership = _i25.Constants();

  final _i26.Constants certification = _i26.Constants();

  final _i27.Constants distance = _i27.Constants();

  final _i28.Constants atomicSwap = _i28.Constants();

  final _i29.Constants multisig = _i29.Constants();

  final _i30.Constants provideRandomness = _i30.Constants();

  final _i31.Constants proxy = _i31.Constants();

  final _i35.Constants utility = _i35.Constants();

  final _i32.Constants treasury = _i32.Constants();
}

class Rpc {
  const Rpc({
    required this.state,
    required this.system,
  });

  final _i1.StateApi state;

  final _i1.SystemApi system;
}

class Registry {
  Registry();

  final int extrinsicVersion = 4;

  List getSignedExtensionTypes() {
    return ['CheckMortality', 'CheckNonce', 'ChargeTransactionPayment'];
  }

  List getSignedExtensionExtra() {
    return [
      'CheckSpecVersion',
      'CheckTxVersion',
      'CheckGenesis',
      'CheckMortality'
    ];
  }
}

class Gdev {
  Gdev._(
    this._provider,
    this.rpc,
  )   : query = Queries(rpc.state),
        constant = Constants(),
        tx = Extrinsics(),
        registry = Registry();

  factory Gdev(_i1.Provider provider) {
    final rpc = Rpc(
      state: _i1.StateApi(provider),
      system: _i1.SystemApi(provider),
    );
    return Gdev._(
      provider,
      rpc,
    );
  }

  factory Gdev.url(Uri url) {
    final provider = _i1.Provider.fromUri(url);
    return Gdev(provider);
  }

  final _i1.Provider _provider;

  final Queries query;

  final Constants constant;

  final Rpc rpc;

  final Extrinsics tx;

  final Registry registry;

  _i37.Future connect() async {
    return await _provider.connect();
  }

  _i37.Future disconnect() async {
    return await _provider.disconnect();
  }
}
