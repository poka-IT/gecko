// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i6;

import '../../sp_core/crypto/account_id32.dart' as _i3;
import '../../sp_runtime/multi_signature.dart' as _i5;
import '../types/idty_name.dart' as _i4;

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

  CreateIdentity createIdentity({required _i3.AccountId32 ownerKey}) {
    return CreateIdentity(ownerKey: ownerKey);
  }

  ConfirmIdentity confirmIdentity({required _i4.IdtyName idtyName}) {
    return ConfirmIdentity(idtyName: idtyName);
  }

  ChangeOwnerKey changeOwnerKey({
    required _i3.AccountId32 newKey,
    required _i5.MultiSignature newKeySig,
  }) {
    return ChangeOwnerKey(
      newKey: newKey,
      newKeySig: newKeySig,
    );
  }

  RevokeIdentity revokeIdentity({
    required int idtyIndex,
    required _i3.AccountId32 revocationKey,
    required _i5.MultiSignature revocationSig,
  }) {
    return RevokeIdentity(
      idtyIndex: idtyIndex,
      revocationKey: revocationKey,
      revocationSig: revocationSig,
    );
  }

  PruneItemIdentitiesNames pruneItemIdentitiesNames(
      {required List<_i4.IdtyName> names}) {
    return PruneItemIdentitiesNames(names: names);
  }

  FixSufficients fixSufficients({
    required _i3.AccountId32 ownerKey,
    required bool inc,
  }) {
    return FixSufficients(
      ownerKey: ownerKey,
      inc: inc,
    );
  }

  LinkAccount linkAccount({
    required _i3.AccountId32 accountId,
    required _i5.MultiSignature payloadSig,
  }) {
    return LinkAccount(
      accountId: accountId,
      payloadSig: payloadSig,
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
        return CreateIdentity._decode(input);
      case 1:
        return ConfirmIdentity._decode(input);
      case 3:
        return ChangeOwnerKey._decode(input);
      case 4:
        return RevokeIdentity._decode(input);
      case 6:
        return PruneItemIdentitiesNames._decode(input);
      case 7:
        return FixSufficients._decode(input);
      case 8:
        return LinkAccount._decode(input);
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
      case CreateIdentity:
        (value as CreateIdentity).encodeTo(output);
        break;
      case ConfirmIdentity:
        (value as ConfirmIdentity).encodeTo(output);
        break;
      case ChangeOwnerKey:
        (value as ChangeOwnerKey).encodeTo(output);
        break;
      case RevokeIdentity:
        (value as RevokeIdentity).encodeTo(output);
        break;
      case PruneItemIdentitiesNames:
        (value as PruneItemIdentitiesNames).encodeTo(output);
        break;
      case FixSufficients:
        (value as FixSufficients).encodeTo(output);
        break;
      case LinkAccount:
        (value as LinkAccount).encodeTo(output);
        break;
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }

  @override
  int sizeHint(Call value) {
    switch (value.runtimeType) {
      case CreateIdentity:
        return (value as CreateIdentity)._sizeHint();
      case ConfirmIdentity:
        return (value as ConfirmIdentity)._sizeHint();
      case ChangeOwnerKey:
        return (value as ChangeOwnerKey)._sizeHint();
      case RevokeIdentity:
        return (value as RevokeIdentity)._sizeHint();
      case PruneItemIdentitiesNames:
        return (value as PruneItemIdentitiesNames)._sizeHint();
      case FixSufficients:
        return (value as FixSufficients)._sizeHint();
      case LinkAccount:
        return (value as LinkAccount)._sizeHint();
      default:
        throw Exception(
            'Call: Unsupported "$value" of type "${value.runtimeType}"');
    }
  }
}

/// Create an identity for an existing account
///
/// - `owner_key`: the public key corresponding to the identity to be created
///
/// The origin must be allowed to create an identity.
class CreateIdentity extends Call {
  const CreateIdentity({required this.ownerKey});

  factory CreateIdentity._decode(_i1.Input input) {
    return CreateIdentity(ownerKey: const _i1.U8ArrayCodec(32).decode(input));
  }

  /// T::AccountId
  final _i3.AccountId32 ownerKey;

  @override
  Map<String, Map<String, List<int>>> toJson() => {
        'create_identity': {'ownerKey': ownerKey.toList()}
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(ownerKey);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      0,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      ownerKey,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is CreateIdentity &&
          _i6.listsEqual(
            other.ownerKey,
            ownerKey,
          );

  @override
  int get hashCode => ownerKey.hashCode;
}

/// Confirm the creation of an identity and give it a name
///
/// - `idty_name`: the name uniquely associated to this identity. Must match the validation rules defined by the runtime.
///
/// The identity must have been created using `create_identity` before it can be confirmed.
class ConfirmIdentity extends Call {
  const ConfirmIdentity({required this.idtyName});

  factory ConfirmIdentity._decode(_i1.Input input) {
    return ConfirmIdentity(idtyName: _i1.U8SequenceCodec.codec.decode(input));
  }

  /// IdtyName
  final _i4.IdtyName idtyName;

  @override
  Map<String, Map<String, List<int>>> toJson() => {
        'confirm_identity': {'idtyName': idtyName}
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i4.IdtyNameCodec().sizeHint(idtyName);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      1,
      output,
    );
    _i1.U8SequenceCodec.codec.encodeTo(
      idtyName,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ConfirmIdentity &&
          _i6.listsEqual(
            other.idtyName,
            idtyName,
          );

  @override
  int get hashCode => idtyName.hashCode;
}

/// Change identity owner key.
///
/// - `new_key`: the new owner key.
/// - `new_key_sig`: the signature of the encoded form of `IdtyIndexAccountIdPayload`.
///                 Must be signed by `new_key`.
///
/// The origin should be the old identity owner key.
class ChangeOwnerKey extends Call {
  const ChangeOwnerKey({
    required this.newKey,
    required this.newKeySig,
  });

  factory ChangeOwnerKey._decode(_i1.Input input) {
    return ChangeOwnerKey(
      newKey: const _i1.U8ArrayCodec(32).decode(input),
      newKeySig: _i5.MultiSignature.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 newKey;

  /// T::Signature
  final _i5.MultiSignature newKeySig;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'change_owner_key': {
          'newKey': newKey.toList(),
          'newKeySig': newKeySig.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(newKey);
    size = size + _i5.MultiSignature.codec.sizeHint(newKeySig);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      3,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      newKey,
      output,
    );
    _i5.MultiSignature.codec.encodeTo(
      newKeySig,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is ChangeOwnerKey &&
          _i6.listsEqual(
            other.newKey,
            newKey,
          ) &&
          other.newKeySig == newKeySig;

  @override
  int get hashCode => Object.hash(
        newKey,
        newKeySig,
      );
}

/// Revoke an identity using a revocation signature
///
/// - `idty_index`: the index of the identity to be revoked.
/// - `revocation_key`: the key used to sign the revocation payload.
/// - `revocation_sig`: the signature of the encoded form of `RevocationPayload`.
///                    Must be signed by `revocation_key`.
///
/// Any signed origin can execute this call.
class RevokeIdentity extends Call {
  const RevokeIdentity({
    required this.idtyIndex,
    required this.revocationKey,
    required this.revocationSig,
  });

  factory RevokeIdentity._decode(_i1.Input input) {
    return RevokeIdentity(
      idtyIndex: _i1.U32Codec.codec.decode(input),
      revocationKey: const _i1.U8ArrayCodec(32).decode(input),
      revocationSig: _i5.MultiSignature.codec.decode(input),
    );
  }

  /// T::IdtyIndex
  final int idtyIndex;

  /// T::AccountId
  final _i3.AccountId32 revocationKey;

  /// T::Signature
  final _i5.MultiSignature revocationSig;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'revoke_identity': {
          'idtyIndex': idtyIndex,
          'revocationKey': revocationKey.toList(),
          'revocationSig': revocationSig.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + _i1.U32Codec.codec.sizeHint(idtyIndex);
    size = size + const _i3.AccountId32Codec().sizeHint(revocationKey);
    size = size + _i5.MultiSignature.codec.sizeHint(revocationSig);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      4,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      idtyIndex,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      revocationKey,
      output,
    );
    _i5.MultiSignature.codec.encodeTo(
      revocationSig,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is RevokeIdentity &&
          other.idtyIndex == idtyIndex &&
          _i6.listsEqual(
            other.revocationKey,
            revocationKey,
          ) &&
          other.revocationSig == revocationSig;

  @override
  int get hashCode => Object.hash(
        idtyIndex,
        revocationKey,
        revocationSig,
      );
}

/// Remove identity names from storage.
///
/// This function allows a privileged root origin to remove multiple identity names from storage
/// in bulk.
///
/// - `origin` - The origin of the call. It must be root.
/// - `names` - A vector containing the identity names to be removed from storage.
class PruneItemIdentitiesNames extends Call {
  const PruneItemIdentitiesNames({required this.names});

  factory PruneItemIdentitiesNames._decode(_i1.Input input) {
    return PruneItemIdentitiesNames(
        names: const _i1.SequenceCodec<_i4.IdtyName>(_i4.IdtyNameCodec())
            .decode(input));
  }

  /// Vec<IdtyName>
  final List<_i4.IdtyName> names;

  @override
  Map<String, Map<String, List<List<int>>>> toJson() => {
        'prune_item_identities_names': {
          'names': names.map((value) => value).toList()
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size +
        const _i1.SequenceCodec<_i4.IdtyName>(_i4.IdtyNameCodec())
            .sizeHint(names);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      6,
      output,
    );
    const _i1.SequenceCodec<_i4.IdtyName>(_i4.IdtyNameCodec()).encodeTo(
      names,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is PruneItemIdentitiesNames &&
          _i6.listsEqual(
            other.names,
            names,
          );

  @override
  int get hashCode => names.hashCode;
}

/// Change sufficient reference count for a given key.
///
/// This function allows a privileged root origin to increment or decrement the sufficient
/// reference count associated with a specified owner key.
///
/// - `origin` - The origin of the call. It must be root.
/// - `owner_key` - The account whose sufficient reference count will be modified.
/// - `inc` - A boolean indicating whether to increment (`true`) or decrement (`false`) the count.
///
class FixSufficients extends Call {
  const FixSufficients({
    required this.ownerKey,
    required this.inc,
  });

  factory FixSufficients._decode(_i1.Input input) {
    return FixSufficients(
      ownerKey: const _i1.U8ArrayCodec(32).decode(input),
      inc: _i1.BoolCodec.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 ownerKey;

  /// bool
  final bool inc;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'fix_sufficients': {
          'ownerKey': ownerKey.toList(),
          'inc': inc,
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(ownerKey);
    size = size + _i1.BoolCodec.codec.sizeHint(inc);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      7,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      ownerKey,
      output,
    );
    _i1.BoolCodec.codec.encodeTo(
      inc,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is FixSufficients &&
          _i6.listsEqual(
            other.ownerKey,
            ownerKey,
          ) &&
          other.inc == inc;

  @override
  int get hashCode => Object.hash(
        ownerKey,
        inc,
      );
}

/// Link an account to an identity.
///
/// This function links a specified account to an identity, requiring both the account and the
/// identity to sign the operation.
///
/// - `origin` - The origin of the call, which must have an associated identity index.
/// - `account_id` - The account ID to link, which must sign the payload.
/// - `payload_sig` - The signature with the linked identity.
class LinkAccount extends Call {
  const LinkAccount({
    required this.accountId,
    required this.payloadSig,
  });

  factory LinkAccount._decode(_i1.Input input) {
    return LinkAccount(
      accountId: const _i1.U8ArrayCodec(32).decode(input),
      payloadSig: _i5.MultiSignature.codec.decode(input),
    );
  }

  /// T::AccountId
  final _i3.AccountId32 accountId;

  /// T::Signature
  final _i5.MultiSignature payloadSig;

  @override
  Map<String, Map<String, dynamic>> toJson() => {
        'link_account': {
          'accountId': accountId.toList(),
          'payloadSig': payloadSig.toJson(),
        }
      };

  int _sizeHint() {
    int size = 1;
    size = size + const _i3.AccountId32Codec().sizeHint(accountId);
    size = size + _i5.MultiSignature.codec.sizeHint(payloadSig);
    return size;
  }

  void encodeTo(_i1.Output output) {
    _i1.U8Codec.codec.encodeTo(
      8,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      accountId,
      output,
    );
    _i5.MultiSignature.codec.encodeTo(
      payloadSig,
      output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is LinkAccount &&
          _i6.listsEqual(
            other.accountId,
            accountId,
          ) &&
          other.payloadSig == payloadSig;

  @override
  int get hashCode => Object.hash(
        accountId,
        payloadSig,
      );
}
