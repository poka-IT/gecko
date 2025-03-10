// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:typed_data' as _i5;

import 'package:polkadart/polkadart.dart' as _i1;
import 'package:polkadart/scale_codec.dart' as _i2;

import '../types/gdev_runtime/runtime_call.dart' as _i6;
import '../types/pallet_provide_randomness/pallet/call.dart' as _i9;
import '../types/pallet_provide_randomness/types/randomness_type.dart' as _i7;
import '../types/pallet_provide_randomness/types/request.dart' as _i3;
import '../types/primitive_types/h256.dart' as _i8;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageValue<int> _nexEpochHookIn = const _i1.StorageValue<int>(
    prefix: 'ProvideRandomness',
    storage: 'NexEpochHookIn',
    valueCodec: _i2.U8Codec.codec,
  );

  final _i1.StorageValue<BigInt> _requestIdProvider =
      const _i1.StorageValue<BigInt>(
    prefix: 'ProvideRandomness',
    storage: 'RequestIdProvider',
    valueCodec: _i2.U64Codec.codec,
  );

  final _i1.StorageValue<List<_i3.Request>> _requestsReadyAtNextBlock =
      const _i1.StorageValue<List<_i3.Request>>(
    prefix: 'ProvideRandomness',
    storage: 'RequestsReadyAtNextBlock',
    valueCodec: _i2.SequenceCodec<_i3.Request>(_i3.Request.codec),
  );

  final _i1.StorageMap<BigInt, List<_i3.Request>> _requestsReadyAtEpoch =
      const _i1.StorageMap<BigInt, List<_i3.Request>>(
    prefix: 'ProvideRandomness',
    storage: 'RequestsReadyAtEpoch',
    valueCodec: _i2.SequenceCodec<_i3.Request>(_i3.Request.codec),
    hasher: _i1.StorageHasher.twoxx64Concat(_i2.U64Codec.codec),
  );

  final _i1.StorageMap<BigInt, dynamic> _requestsIds =
      const _i1.StorageMap<BigInt, dynamic>(
    prefix: 'ProvideRandomness',
    storage: 'RequestsIds',
    valueCodec: _i2.NullCodec.codec,
    hasher: _i1.StorageHasher.twoxx64Concat(_i2.U64Codec.codec),
  );

  final _i1.StorageValue<int> _counterForRequestsIds =
      const _i1.StorageValue<int>(
    prefix: 'ProvideRandomness',
    storage: 'CounterForRequestsIds',
    valueCodec: _i2.U32Codec.codec,
  );

  /// The number of blocks before the next epoch.
  _i4.Future<int> nexEpochHookIn({_i1.BlockHash? at}) async {
    final hashedKey = _nexEpochHookIn.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _nexEpochHookIn.decodeValue(bytes);
    }
    return 0; /* Default */
  }

  /// The request ID.
  _i4.Future<BigInt> requestIdProvider({_i1.BlockHash? at}) async {
    final hashedKey = _requestIdProvider.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _requestIdProvider.decodeValue(bytes);
    }
    return BigInt.zero; /* Default */
  }

  /// The requests that will be fulfilled at the next block.
  _i4.Future<List<_i3.Request>> requestsReadyAtNextBlock(
      {_i1.BlockHash? at}) async {
    final hashedKey = _requestsReadyAtNextBlock.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _requestsReadyAtNextBlock.decodeValue(bytes);
    }
    return []; /* Default */
  }

  /// The requests that will be fulfilled at the next epoch.
  _i4.Future<List<_i3.Request>> requestsReadyAtEpoch(
    BigInt key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _requestsReadyAtEpoch.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _requestsReadyAtEpoch.decodeValue(bytes);
    }
    return []; /* Default */
  }

  /// The requests being processed.
  _i4.Future<dynamic> requestsIds(
    BigInt key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _requestsIds.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _requestsIds.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// Counter for the related counted storage map
  _i4.Future<int> counterForRequestsIds({_i1.BlockHash? at}) async {
    final hashedKey = _counterForRequestsIds.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _counterForRequestsIds.decodeValue(bytes);
    }
    return 0; /* Default */
  }

  /// Returns the storage key for `nexEpochHookIn`.
  _i5.Uint8List nexEpochHookInKey() {
    final hashedKey = _nexEpochHookIn.hashedKey();
    return hashedKey;
  }

  /// Returns the storage key for `requestIdProvider`.
  _i5.Uint8List requestIdProviderKey() {
    final hashedKey = _requestIdProvider.hashedKey();
    return hashedKey;
  }

  /// Returns the storage key for `requestsReadyAtNextBlock`.
  _i5.Uint8List requestsReadyAtNextBlockKey() {
    final hashedKey = _requestsReadyAtNextBlock.hashedKey();
    return hashedKey;
  }

  /// Returns the storage key for `requestsReadyAtEpoch`.
  _i5.Uint8List requestsReadyAtEpochKey(BigInt key1) {
    final hashedKey = _requestsReadyAtEpoch.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `requestsIds`.
  _i5.Uint8List requestsIdsKey(BigInt key1) {
    final hashedKey = _requestsIds.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `counterForRequestsIds`.
  _i5.Uint8List counterForRequestsIdsKey() {
    final hashedKey = _counterForRequestsIds.hashedKey();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `requestsReadyAtEpoch`.
  _i5.Uint8List requestsReadyAtEpochMapPrefix() {
    final hashedKey = _requestsReadyAtEpoch.mapPrefix();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `requestsIds`.
  _i5.Uint8List requestsIdsMapPrefix() {
    final hashedKey = _requestsIds.mapPrefix();
    return hashedKey;
  }
}

class Txs {
  const Txs();

  /// Request randomness.
  _i6.ProvideRandomness request({
    required _i7.RandomnessType randomnessType,
    required _i8.H256 salt,
  }) {
    return _i6.ProvideRandomness(_i9.Request(
      randomnessType: randomnessType,
      salt: salt,
    ));
  }
}

class Constants {
  Constants();

  /// Maximum number of not yet filled requests.
  final int maxRequests = 100;

  /// The price of a request.
  final BigInt requestPrice = BigInt.from(2000);
}
