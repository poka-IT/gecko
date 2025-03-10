// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:typed_data' as _i6;

import 'package:polkadart/polkadart.dart' as _i1;
import 'package:polkadart/scale_codec.dart' as _i4;

import '../types/gdev_runtime/runtime_call.dart' as _i7;
import '../types/pallet_atomic_swap/balance_swap_action.dart' as _i8;
import '../types/pallet_atomic_swap/pallet/call.dart' as _i9;
import '../types/pallet_atomic_swap/pending_swap.dart' as _i3;
import '../types/sp_core/crypto/account_id32.dart' as _i2;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageDoubleMap<_i2.AccountId32, List<int>, _i3.PendingSwap>
      _pendingSwaps =
      const _i1.StorageDoubleMap<_i2.AccountId32, List<int>, _i3.PendingSwap>(
    prefix: 'AtomicSwap',
    storage: 'PendingSwaps',
    valueCodec: _i3.PendingSwap.codec,
    hasher1: _i1.StorageHasher.twoxx64Concat(_i2.AccountId32Codec()),
    hasher2: _i1.StorageHasher.blake2b128Concat(_i4.U8ArrayCodec(32)),
  );

  _i5.Future<_i3.PendingSwap?> pendingSwaps(
    _i2.AccountId32 key1,
    List<int> key2, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _pendingSwaps.hashedKeyFor(
      key1,
      key2,
    );
    final bytes = await __api.getStorage(
      hashedKey,
      at: at,
    );
    if (bytes != null) {
      return _pendingSwaps.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// Returns the storage key for `pendingSwaps`.
  _i6.Uint8List pendingSwapsKey(
    _i2.AccountId32 key1,
    List<int> key2,
  ) {
    final hashedKey = _pendingSwaps.hashedKeyFor(
      key1,
      key2,
    );
    return hashedKey;
  }

  /// Returns the storage map key prefix for `pendingSwaps`.
  _i6.Uint8List pendingSwapsMapPrefix(_i2.AccountId32 key1) {
    final hashedKey = _pendingSwaps.mapPrefix(key1);
    return hashedKey;
  }
}

class Txs {
  const Txs();

  /// Register a new atomic swap, declaring an intention to send funds from origin to target
  /// on the current blockchain. The target can claim the fund using the revealed proof. If
  /// the fund is not claimed after `duration` blocks, then the sender can cancel the swap.
  ///
  /// The dispatch origin for this call must be _Signed_.
  ///
  /// - `target`: Receiver of the atomic swap.
  /// - `hashed_proof`: The blake2_256 hash of the secret proof.
  /// - `balance`: Funds to be sent from origin.
  /// - `duration`: Locked duration of the atomic swap. For safety reasons, it is recommended
  ///  that the revealer uses a shorter duration than the counterparty, to prevent the
  ///  situation where the revealer reveals the proof too late around the end block.
  _i7.AtomicSwap createSwap({
    required _i2.AccountId32 target,
    required List<int> hashedProof,
    required _i8.BalanceSwapAction action,
    required int duration,
  }) {
    return _i7.AtomicSwap(_i9.CreateSwap(
      target: target,
      hashedProof: hashedProof,
      action: action,
      duration: duration,
    ));
  }

  /// Claim an atomic swap.
  ///
  /// The dispatch origin for this call must be _Signed_.
  ///
  /// - `proof`: Revealed proof of the claim.
  /// - `action`: Action defined in the swap, it must match the entry in blockchain. Otherwise
  ///  the operation fails. This is used for weight calculation.
  _i7.AtomicSwap claimSwap({
    required List<int> proof,
    required _i8.BalanceSwapAction action,
  }) {
    return _i7.AtomicSwap(_i9.ClaimSwap(
      proof: proof,
      action: action,
    ));
  }

  /// Cancel an atomic swap. Only possible after the originally set duration has passed.
  ///
  /// The dispatch origin for this call must be _Signed_.
  ///
  /// - `target`: Target of the original atomic swap.
  /// - `hashed_proof`: Hashed proof of the original atomic swap.
  _i7.AtomicSwap cancelSwap({
    required _i2.AccountId32 target,
    required List<int> hashedProof,
  }) {
    return _i7.AtomicSwap(_i9.CancelSwap(
      target: target,
      hashedProof: hashedProof,
    ));
  }
}

class Constants {
  Constants();

  /// Limit of proof size.
  ///
  /// Atomic swap is only atomic if once the proof is revealed, both parties can submit the
  /// proofs on-chain. If A is the one that generates the proof, then it requires that either:
  /// - A's blockchain has the same proof length limit as B's blockchain.
  /// - Or A's blockchain has shorter proof length limit as B's blockchain.
  ///
  /// If B sees A is on a blockchain with larger proof length limit, then it should kindly
  /// refuse to accept the atomic swap request if A generates the proof, and asks that B
  /// generates the proof instead.
  final int proofLimit = 1024;
}
