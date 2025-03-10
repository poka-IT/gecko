// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:typed_data' as _i6;

import 'package:polkadart/polkadart.dart' as _i1;
import 'package:polkadart/scale_codec.dart' as _i3;

import '../types/gdev_runtime/runtime_call.dart' as _i7;
import '../types/pallet_certification/pallet/call.dart' as _i8;
import '../types/pallet_certification/types/idty_cert_meta.dart' as _i2;
import '../types/tuples_1.dart' as _i4;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageMap<int, _i2.IdtyCertMeta> _storageIdtyCertMeta =
      const _i1.StorageMap<int, _i2.IdtyCertMeta>(
    prefix: 'Certification',
    storage: 'StorageIdtyCertMeta',
    valueCodec: _i2.IdtyCertMeta.codec,
    hasher: _i1.StorageHasher.twoxx64Concat(_i3.U32Codec.codec),
  );

  final _i1.StorageMap<int, List<_i4.Tuple2<int, int>>> _certsByReceiver =
      const _i1.StorageMap<int, List<_i4.Tuple2<int, int>>>(
    prefix: 'Certification',
    storage: 'CertsByReceiver',
    valueCodec:
        _i3.SequenceCodec<_i4.Tuple2<int, int>>(_i4.Tuple2Codec<int, int>(
      _i3.U32Codec.codec,
      _i3.U32Codec.codec,
    )),
    hasher: _i1.StorageHasher.twoxx64Concat(_i3.U32Codec.codec),
  );

  final _i1.StorageMap<int, List<_i4.Tuple2<int, int>>> _certsRemovableOn =
      const _i1.StorageMap<int, List<_i4.Tuple2<int, int>>>(
    prefix: 'Certification',
    storage: 'CertsRemovableOn',
    valueCodec:
        _i3.SequenceCodec<_i4.Tuple2<int, int>>(_i4.Tuple2Codec<int, int>(
      _i3.U32Codec.codec,
      _i3.U32Codec.codec,
    )),
    hasher: _i1.StorageHasher.twoxx64Concat(_i3.U32Codec.codec),
  );

  /// The certification metadata for each issuer.
  _i5.Future<_i2.IdtyCertMeta> storageIdtyCertMeta(
    int key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _storageIdtyCertMeta.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _storageIdtyCertMeta.decodeValue(bytes);
    }
    return _i2.IdtyCertMeta(
      issuedCount: 0,
      nextIssuableOn: 0,
      receivedCount: 0,
    ); /* Default */
  }

  /// The certifications for each receiver.
  _i5.Future<List<_i4.Tuple2<int, int>>> certsByReceiver(
    int key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _certsByReceiver.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _certsByReceiver.decodeValue(bytes);
    }
    return []; /* Default */
  }

  /// The certifications that should expire at a given block.
  _i5.Future<List<_i4.Tuple2<int, int>>?> certsRemovableOn(
    int key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _certsRemovableOn.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _certsRemovableOn.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// Returns the storage key for `storageIdtyCertMeta`.
  _i6.Uint8List storageIdtyCertMetaKey(int key1) {
    final hashedKey = _storageIdtyCertMeta.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `certsByReceiver`.
  _i6.Uint8List certsByReceiverKey(int key1) {
    final hashedKey = _certsByReceiver.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `certsRemovableOn`.
  _i6.Uint8List certsRemovableOnKey(int key1) {
    final hashedKey = _certsRemovableOn.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage map key prefix for `storageIdtyCertMeta`.
  _i6.Uint8List storageIdtyCertMetaMapPrefix() {
    final hashedKey = _storageIdtyCertMeta.mapPrefix();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `certsByReceiver`.
  _i6.Uint8List certsByReceiverMapPrefix() {
    final hashedKey = _certsByReceiver.mapPrefix();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `certsRemovableOn`.
  _i6.Uint8List certsRemovableOnMapPrefix() {
    final hashedKey = _certsRemovableOn.mapPrefix();
    return hashedKey;
  }
}

class Txs {
  const Txs();

  /// Add a new certification.
  _i7.Certification addCert({required int receiver}) {
    return _i7.Certification(_i8.AddCert(receiver: receiver));
  }

  /// Renew an existing certification.
  _i7.Certification renewCert({required int receiver}) {
    return _i7.Certification(_i8.RenewCert(receiver: receiver));
  }

  /// Remove one certification given the issuer and the receiver.
  ///
  /// - `origin`: Must be `Root`.
  _i7.Certification delCert({
    required int issuer,
    required int receiver,
  }) {
    return _i7.Certification(_i8.DelCert(
      issuer: issuer,
      receiver: receiver,
    ));
  }

  /// Remove all certifications received by an identity.
  ///
  /// - `origin`: Must be `Root`.
  _i7.Certification removeAllCertsReceivedBy({required int idtyIndex}) {
    return _i7.Certification(
        _i8.RemoveAllCertsReceivedBy(idtyIndex: idtyIndex));
  }
}

class Constants {
  Constants();

  /// The minimum duration (in blocks) between two certifications issued by the same issuer.
  final int certPeriod = 14400;

  /// The maximum number of active certifications that can be issued by a single issuer.
  final int maxByIssuer = 100;

  /// The minimum number of certifications received that an identity must have
  /// to be allowed to issue a certification.
  final int minReceivedCertToBeAbleToIssueCert = 3;

  /// The duration (in blocks) for which a certification remains valid.
  final int validityPeriod = 2102400;
}
