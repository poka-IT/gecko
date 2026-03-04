// Headless integration test for identity migration (changeOwnerKey batch).
//
// Requires duniter-mocks running in sealing mode:
//   cd ../duniter-mocks && ./run.sh restart --sealing && ./run.sh wait-ready
//
// Run with:
//   flutter test test/integration/migrate_identity_test.dart

import 'dart:io';
import 'package:durt2/durt2.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Eve's well-known address on duniter-mocks.
const eveAddress = '5HGjWAeFDfFCWPsjFQdVV2Msvz2XtMktvgocEZcCj68kUMaw';

/// Eve's secret URI on duniter-mocks.
const eveUri = 'bottom drive obey lake curtain smoke basket hold race lonely fit walk//Eve';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DurtKeyPair eveKeypair;
  late DurtKeyPair destKeypair;
  late String destAddress;
  late int eveIdtyIndex;

  setUpAll(() async {
    // Mock path_provider so ObjectBox can find a directory in test environment
    final tempDir = await Directory.systemTemp.createTemp('gecko_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    // Init durt2 on local network
    await Durt().init(network: Networks.local, keyPairType: KeyPairType.ed25519);

    // Point to local duniter-mocks node
    Durt.i.configBox.putValue('customEndpoint', 'ws://localhost:9944');

    // Connect only to Duniter (no Squid, no Datapod)
    await Durt.i.connect(initDuniter: true, initSquid: false, initDatapod: false, verbose: true);

    // Wait for effective connection
    await _waitForConnection(timeout: const Duration(seconds: 15));

    // Create Eve's keypair from URI (sr25519 - default Substrate dev account type)
    eveKeypair = await Durt.i.keyring.fromUri(eveUri, keyPairType: KeyPairType.sr25519);

    // Generate a random destination keypair
    final destMnemonic = Durt.i.wallets.generateMnemonic().sentence;
    destKeypair = await Durt.i.wallets.getKeyPairFromMnemonic(destMnemonic, keyPairType: KeyPairType.ed25519);
    destAddress = destKeypair.address;
  });

  tearDownAll(() {
    try {
      Durt.i.dispose();
    } catch (_) {
      // Ignore "Concurrent modification during iteration" in DuniterConnector.disconnect
      // This is a known durt2 issue during teardown, harmless in tests.
    }
  });

  test('Pre-validation: Eve has identity + balance, dest is empty', () async {
    // Eve should have a positive balance
    final eveBalance = await Durt.i.storage.getBalance(eveAddress);
    expect(eveBalance.transferableBalance, greaterThan(BigInt.zero), reason: 'Eve should have balance > 0');

    // Eve should have a validated identity
    final eveIdtyStatus = await Durt.i.storage.getIdtyStatus(eveAddress);
    expect(eveIdtyStatus, equals(IdtyStatus.validated), reason: 'Eve should be validated');

    // Destination should be empty
    final destBalance = await Durt.i.storage.getBalance(destAddress);
    expect(destBalance.transferableBalance, equals(BigInt.zero), reason: 'Dest should have 0 balance');

    final destIdtyStatus = await Durt.i.storage.getIdtyStatus(destAddress);
    expect(destIdtyStatus, equals(IdtyStatus.none), reason: 'Dest should have no identity');

    // Eve should have a valid identity index (save for post-migration check)
    final eveIndex = await Durt.i.storage.getIdentityIndexOf(eveAddress);
    expect(eveIndex, isNotNull, reason: 'Eve should have an identity index');
    eveIdtyIndex = eveIndex!;

    // Migration checks should pass
    final checks = await Durt.i.storage.getMigrateWalletChecks(fromAddress: eveAddress, toAddress: destAddress);
    expect(checks.canMigrate, isTrue, reason: 'Migration should be allowed');
    expect(checks.errors, isEmpty, reason: 'No validation errors expected');
  });

  test('Execute migrateIdentity batch and reach inBlock/finalized', () async {
    final statuses = <TransactionStatus>[];

    await for (final status in Durt.i.duniter.migrateIdentity(
      fromKeypair: eveKeypair,
      toKeypair: destKeypair,
      withBalance: true,
    )) {
      statuses.add(status);

      if (status.state == TransactionState.pending) {
        // In sealing mode, we must manually produce blocks
        await Durt.i.duniter.spawnBlock();
      }

      // Stop listening once we reach a terminal state
      if (status.state == TransactionState.inBlock ||
          status.state == TransactionState.finalized ||
          status.state == TransactionState.error ||
          status.state == TransactionState.timeout) {
        break;
      }
    }

    // Should have received at least pending + a terminal state
    expect(statuses, isNotEmpty);

    final terminalStatus = statuses.last;
    expect(
      terminalStatus.state,
      anyOf(TransactionState.inBlock, TransactionState.finalized),
      reason:
          'Transaction should succeed (got: ${terminalStatus.state}, '
          'error: ${terminalStatus.errorMessage})',
    );
  });

  test('Post-migration: identity transferred, balance moved', () async {
    // Spawn a few extra blocks to ensure finalization
    await Durt.i.duniter.spawnBlock(number: 3);
    await Future.delayed(const Duration(seconds: 1));

    // Destination should now have Eve's validated identity
    final destIdtyStatus = await Durt.i.storage.getIdtyStatus(destAddress);
    expect(destIdtyStatus, equals(IdtyStatus.validated), reason: 'Dest should now be validated');

    // Destination should have received the balance
    final destBalance = await Durt.i.storage.getBalance(destAddress);
    expect(destBalance.transferableBalance, greaterThan(BigInt.zero), reason: 'Dest should have balance > 0');

    // Eve's old account should be emptied
    final eveBalance = await Durt.i.storage.getBalance(eveAddress);
    expect(eveBalance.transferableBalance, equals(BigInt.zero), reason: 'Eve old account should be empty');

    // Eve's old account should no longer have an identity
    final eveIdtyStatus = await Durt.i.storage.getIdtyStatus(eveAddress);
    expect(eveIdtyStatus, isNot(IdtyStatus.validated), reason: 'Eve old account should no longer be validated');

    // Destination should have the SAME identity index Eve had (proof of migration, not new identity)
    final destIdtyIndex = await Durt.i.storage.getIdentityIndexOf(destAddress);
    expect(destIdtyIndex, isNotNull, reason: 'Dest should have an identity index');
    expect(destIdtyIndex, equals(eveIdtyIndex), reason: 'Dest should have Eve\'s original identity index');
  });

  test('Second changeOwnerKey immediately after migration should fail cleanly', () async {
    // Reproduce the hypericum bug: after a successful migration,
    // a second changeOwnerKey from the new address should fail with a clear error,
    // NOT corrupt the first migration's result.

    // Generate a third keypair as the "mystery" destination
    final thirdMnemonic = Durt.i.wallets.generateMnemonic().sentence;
    final thirdKeypair = await Durt.i.wallets.getKeyPairFromMnemonic(thirdMnemonic, keyPairType: KeyPairType.ed25519);

    // Attempt a second migration from the NEW address (destKeypair) to the third keypair.
    // This should fail because ChangeOwnerKeyPeriod hasn't elapsed yet.
    final statuses = <TransactionStatus>[];

    await for (final status in Durt.i.duniter.migrateIdentity(
      fromKeypair: destKeypair,
      toKeypair: thirdKeypair,
      withBalance: true,
    )) {
      statuses.add(status);

      if (status.state == TransactionState.pending) {
        await Durt.i.duniter.spawnBlock();
      }

      if (status.state == TransactionState.inBlock ||
          status.state == TransactionState.finalized ||
          status.state == TransactionState.error ||
          status.state == TransactionState.timeout) {
        break;
      }
    }

    expect(statuses, isNotEmpty);

    final terminalStatus = statuses.last;
    // The second changeOwnerKey should fail (OwnerKeyAlreadyRecentlyChanged or similar)
    expect(
      terminalStatus.state,
      equals(TransactionState.error),
      reason:
          'Second changeOwnerKey should fail due to cooldown period '
          '(got: ${terminalStatus.state}, error: ${terminalStatus.errorMessage})',
    );

    // The error message should mention owner key, not some unrelated error
    expect(
      terminalStatus.errorMessage,
      anyOf(contains('OwnerKeyAlreadyRecentlyChanged'), contains('OwnerKeyAlreadyUsed'), contains('OwnerKey')),
      reason: 'Error should be about owner key cooldown, not a false positive from another extrinsic',
    );

    // The identity should still be on the dest address (first migration), NOT on the third
    final destIdtyStatus = await Durt.i.storage.getIdtyStatus(destAddress);
    expect(destIdtyStatus, equals(IdtyStatus.validated), reason: 'Identity should remain on first migration dest');

    final thirdIdtyStatus = await Durt.i.storage.getIdtyStatus(thirdKeypair.address);
    expect(
      thirdIdtyStatus,
      equals(IdtyStatus.none),
      reason: 'Third address should have no identity (migration failed)',
    );
  });
}

/// Wait until the Duniter node connection is established.
Future<void> _waitForConnection({required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    if (Durt.i.duniterConnectionStatus == ConnectionStatus.connected) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }

  throw Exception(
    'Failed to connect to duniter-mocks within ${timeout.inSeconds}s. '
    'Current status: ${Durt.i.duniterConnectionStatus}',
  );
}
