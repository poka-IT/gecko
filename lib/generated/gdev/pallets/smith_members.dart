// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:typed_data' as _i5;

import 'package:polkadart/polkadart.dart' as _i1;
import 'package:polkadart/scale_codec.dart' as _i3;

import '../types/gdev_runtime/runtime_call.dart' as _i6;
import '../types/pallet_smith_members/pallet/call.dart' as _i7;
import '../types/pallet_smith_members/types/smith_meta.dart' as _i2;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageMap<int, _i2.SmithMeta> _smiths =
      const _i1.StorageMap<int, _i2.SmithMeta>(
    prefix: 'SmithMembers',
    storage: 'Smiths',
    valueCodec: _i2.SmithMeta.codec,
    hasher: _i1.StorageHasher.twoxx64Concat(_i3.U32Codec.codec),
  );

  final _i1.StorageMap<int, List<int>> _expiresOn =
      const _i1.StorageMap<int, List<int>>(
    prefix: 'SmithMembers',
    storage: 'ExpiresOn',
    valueCodec: _i3.U32SequenceCodec.codec,
    hasher: _i1.StorageHasher.twoxx64Concat(_i3.U32Codec.codec),
  );

  final _i1.StorageValue<int> _currentSession = const _i1.StorageValue<int>(
    prefix: 'SmithMembers',
    storage: 'CurrentSession',
    valueCodec: _i3.U32Codec.codec,
  );

  /// The Smith metadata for each identity.
  _i4.Future<_i2.SmithMeta?> smiths(
    int key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _smiths.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _smiths.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// The indexes of Smith to remove at a given session.
  _i4.Future<List<int>?> expiresOn(
    int key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _expiresOn.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _expiresOn.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// The current session index.
  _i4.Future<int> currentSession({_i1.BlockHash? at}) async {
    final hashedKey = _currentSession.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _currentSession.decodeValue(bytes);
    }
    return 0; /* Default */
  }

  /// Returns the storage key for `smiths`.
  _i5.Uint8List smithsKey(int key1) {
    final hashedKey = _smiths.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `expiresOn`.
  _i5.Uint8List expiresOnKey(int key1) {
    final hashedKey = _expiresOn.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `currentSession`.
  _i5.Uint8List currentSessionKey() {
    final hashedKey = _currentSession.hashedKey();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `smiths`.
  _i5.Uint8List smithsMapPrefix() {
    final hashedKey = _smiths.mapPrefix();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `expiresOn`.
  _i5.Uint8List expiresOnMapPrefix() {
    final hashedKey = _expiresOn.mapPrefix();
    return hashedKey;
  }
}

class Txs {
  const Txs();

  /// Invite a member of the Web of Trust to attempt becoming a Smith.
  _i6.SmithMembers inviteSmith({required int receiver}) {
    return _i6.SmithMembers(_i7.InviteSmith(receiver: receiver));
  }

  /// Accept an invitation to become a Smith (must have been invited first).
  _i6.SmithMembers acceptInvitation() {
    return _i6.SmithMembers(_i7.AcceptInvitation());
  }

  /// Certify an invited Smith, which can lead the certified to become a Smith.
  _i6.SmithMembers certifySmith({required int receiver}) {
    return _i6.SmithMembers(_i7.CertifySmith(receiver: receiver));
  }
}

class Constants {
  Constants();

  /// Maximum number of active certifications per issuer.
  final int maxByIssuer = 15;

  /// Minimum number of certifications required to become a Smith.
  final int minCertForMembership = 2;

  /// Maximum duration of inactivity allowed before a Smith is removed.
  final int smithInactivityMaxDuration = 336;
}
