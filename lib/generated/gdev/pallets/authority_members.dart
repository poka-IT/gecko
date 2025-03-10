// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:typed_data' as _i5;

import 'package:polkadart/polkadart.dart' as _i1;
import 'package:polkadart/scale_codec.dart' as _i2;

import '../types/gdev_runtime/opaque/session_keys.dart' as _i8;
import '../types/gdev_runtime/runtime_call.dart' as _i6;
import '../types/pallet_authority_members/pallet/call.dart' as _i7;
import '../types/pallet_authority_members/types/member_data.dart' as _i3;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageValue<List<int>> _incomingAuthorities =
      const _i1.StorageValue<List<int>>(
    prefix: 'AuthorityMembers',
    storage: 'IncomingAuthorities',
    valueCodec: _i2.U32SequenceCodec.codec,
  );

  final _i1.StorageValue<List<int>> _onlineAuthorities =
      const _i1.StorageValue<List<int>>(
    prefix: 'AuthorityMembers',
    storage: 'OnlineAuthorities',
    valueCodec: _i2.U32SequenceCodec.codec,
  );

  final _i1.StorageValue<List<int>> _outgoingAuthorities =
      const _i1.StorageValue<List<int>>(
    prefix: 'AuthorityMembers',
    storage: 'OutgoingAuthorities',
    valueCodec: _i2.U32SequenceCodec.codec,
  );

  final _i1.StorageMap<int, _i3.MemberData> _members =
      const _i1.StorageMap<int, _i3.MemberData>(
    prefix: 'AuthorityMembers',
    storage: 'Members',
    valueCodec: _i3.MemberData.codec,
    hasher: _i1.StorageHasher.twoxx64Concat(_i2.U32Codec.codec),
  );

  final _i1.StorageValue<List<int>> _blacklist =
      const _i1.StorageValue<List<int>>(
    prefix: 'AuthorityMembers',
    storage: 'Blacklist',
    valueCodec: _i2.U32SequenceCodec.codec,
  );

  /// The incoming authorities.
  _i4.Future<List<int>> incomingAuthorities({_i1.BlockHash? at}) async {
    final hashedKey = _incomingAuthorities.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _incomingAuthorities.decodeValue(bytes);
    }
    return List<int>.filled(
      0,
      0,
      growable: true,
    ); /* Default */
  }

  /// The online authorities.
  _i4.Future<List<int>> onlineAuthorities({_i1.BlockHash? at}) async {
    final hashedKey = _onlineAuthorities.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _onlineAuthorities.decodeValue(bytes);
    }
    return List<int>.filled(
      0,
      0,
      growable: true,
    ); /* Default */
  }

  /// The outgoing authorities.
  _i4.Future<List<int>> outgoingAuthorities({_i1.BlockHash? at}) async {
    final hashedKey = _outgoingAuthorities.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _outgoingAuthorities.decodeValue(bytes);
    }
    return List<int>.filled(
      0,
      0,
      growable: true,
    ); /* Default */
  }

  /// The member data.
  _i4.Future<_i3.MemberData?> members(
    int key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _members.hashedKeyFor(key1);
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _members.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// The blacklisted authorities.
  _i4.Future<List<int>> blacklist({_i1.BlockHash? at}) async {
    final hashedKey = _blacklist.hashedKey();
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _blacklist.decodeValue(bytes);
    }
    return List<int>.filled(
      0,
      0,
      growable: true,
    ); /* Default */
  }

  /// Returns the storage key for `incomingAuthorities`.
  _i5.Uint8List incomingAuthoritiesKey() {
    final hashedKey = _incomingAuthorities.hashedKey();
    return hashedKey;
  }

  /// Returns the storage key for `onlineAuthorities`.
  _i5.Uint8List onlineAuthoritiesKey() {
    final hashedKey = _onlineAuthorities.hashedKey();
    return hashedKey;
  }

  /// Returns the storage key for `outgoingAuthorities`.
  _i5.Uint8List outgoingAuthoritiesKey() {
    final hashedKey = _outgoingAuthorities.hashedKey();
    return hashedKey;
  }

  /// Returns the storage key for `members`.
  _i5.Uint8List membersKey(int key1) {
    final hashedKey = _members.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `blacklist`.
  _i5.Uint8List blacklistKey() {
    final hashedKey = _blacklist.hashedKey();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `members`.
  _i5.Uint8List membersMapPrefix() {
    final hashedKey = _members.mapPrefix();
    return hashedKey;
  }
}

class Txs {
  const Txs();

  /// Request to leave the set of validators two sessions later.
  _i6.AuthorityMembers goOffline() {
    return _i6.AuthorityMembers(_i7.GoOffline());
  }

  /// Request to join the set of validators two sessions later.
  _i6.AuthorityMembers goOnline() {
    return _i6.AuthorityMembers(_i7.GoOnline());
  }

  /// Declare new session keys to replace current ones.
  _i6.AuthorityMembers setSessionKeys({required _i8.SessionKeys keys}) {
    return _i6.AuthorityMembers(_i7.SetSessionKeys(keys: keys));
  }

  /// Remove a member from the set of validators.
  _i6.AuthorityMembers removeMember({required int memberId}) {
    return _i6.AuthorityMembers(_i7.RemoveMember(memberId: memberId));
  }

  /// Remove a member from the blacklist.
  /// remove an identity from the blacklist
  _i6.AuthorityMembers removeMemberFromBlacklist({required int memberId}) {
    return _i6.AuthorityMembers(
        _i7.RemoveMemberFromBlacklist(memberId: memberId));
  }
}

class Constants {
  Constants();

  /// Maximum number of authorities allowed.
  final int maxAuthorities = 32;
}
