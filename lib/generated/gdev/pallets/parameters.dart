// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;
import 'dart:typed_data' as _i4;

import 'package:polkadart/polkadart.dart' as _i1;

import '../types/pallet_duniter_test_parameters/types/parameters.dart' as _i2;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageValue<_i2.Parameters> _parametersStorage =
      const _i1.StorageValue<_i2.Parameters>(
    prefix: 'Parameters',
    storage: 'ParametersStorage',
    valueCodec: _i2.Parameters.codec,
  );

  _i3.Future<_i2.Parameters> parametersStorage({_i1.BlockHash? at}) async {
    final hashedKey = _parametersStorage.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _parametersStorage.decodeValue(bytes);
    }
    return _i2.Parameters(
      babeEpochDuration: BigInt.zero,
      certPeriod: 0,
      certMaxByIssuer: 0,
      certMinReceivedCertToIssueCert: 0,
      certValidityPeriod: 0,
      idtyConfirmPeriod: 0,
      idtyCreationPeriod: 0,
      membershipPeriod: 0,
      membershipRenewalPeriod: 0,
      udCreationPeriod: BigInt.zero,
      udReevalPeriod: BigInt.zero,
      smithCertMaxByIssuer: 0,
      smithWotMinCertForMembership: 0,
      smithInactivityMaxDuration: 0,
      wotFirstCertIssuableOn: 0,
      wotMinCertForCreateIdtyRight: 0,
      wotMinCertForMembership: 0,
    ); /* Default */
  }

  /// Returns the storage key for `parametersStorage`.
  _i4.Uint8List parametersStorageKey() {
    final hashedKey = _parametersStorage.hashedKey();
    return hashedKey;
  }
}
