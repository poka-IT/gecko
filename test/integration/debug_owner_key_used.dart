// Debug script: query on-chain state for the OwnerKeyAlreadyUsed bug on gtest.
//
// Run with:
//   flutter test test/integration/debug_owner_key_used.dart

import 'dart:io';
import 'dart:convert';
import 'package:durt2/durt2.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mnemonic that was used as destination for "hypericum" migration (French).
const targetMnemonicFr = 'exaucer appeler gymnaste envoyer jovial flore arriver crainte jovial machine horizon navire';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('gecko_debug_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    // Init durt2 on G1 production network
    await Durt().init(network: Networks.g1, keyPairType: KeyPairType.ed25519);

    // Point to the specific G1 node
    Durt.i.configBox.putValue('customEndpoint', 'wss://g1.p2p.legal/ws');

    // Connect only to Duniter
    await Durt.i.connect(initDuniter: true, initSquid: false, initDatapod: false, verbose: true);

    // Wait for connection
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      if (Durt.i.duniterConnectionStatus == ConnectionStatus.connected) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (Durt.i.duniterConnectionStatus != ConnectionStatus.connected) {
      throw Exception('Failed to connect to gtest node');
    }
    print('Connected to gtest node');
  });

  tearDownAll(() {
    try {
      Durt.i.dispose();
    } catch (_) {}
  });

  test('Investigate OwnerKeyAlreadyUsed for target mnemonic', () async {
    // Convert French mnemonic to English for crypto operations
    final englishMnemonic = await Durt.i.wallets.multilangService.convertToEnglish(
      targetMnemonicFr,
      sourceLanguage: BidouilleLang.french,
    );
    print('\n=== Mnemonic conversion ===');
    print('French:  $targetMnemonicFr');
    print('English: $englishMnemonic');

    // Derive the destination address (ed25519 - Gecko default for new wallets)
    final destKeypairEd = await Durt.i.wallets.getKeyPairFromMnemonic(
      englishMnemonic,
      keyPairType: KeyPairType.ed25519,
    );
    print('\n=== Target mnemonic derived addresses ===');
    print('ed25519 address: ${destKeypairEd.address}');

    // Also check sr25519
    final destKeypairSr = await Durt.i.wallets.getKeyPairFromMnemonic(
      englishMnemonic,
      keyPairType: KeyPairType.sr25519,
    );
    print('sr25519 address: ${destKeypairSr.address}');

    // Check all derivations (0-5) too
    print('\n=== Derivation addresses (ed25519) ===');
    for (int i = 0; i < 5; i++) {
      final kp = await Durt.i.wallets.getKeyPairFromMnemonic(
        englishMnemonic,
        derivation: i,
        keyPairType: KeyPairType.ed25519,
      );
      final idtyIndex = await Durt.i.storage.getIdentityIndexOf(kp.address);
      final idtyStatus = await Durt.i.storage.getIdtyStatus(kp.address);
      print('  /$i: ${kp.address} -> idtyIndex=$idtyIndex, status=$idtyStatus');
    }

    // Check on-chain state for root ed25519 address
    print('\n=== On-chain state for ROOT ed25519: ${destKeypairEd.address} ===');
    final edIdtyStatus = await Durt.i.storage.getIdtyStatus(destKeypairEd.address);
    print('Identity status: $edIdtyStatus');

    final edIdtyIndex = await Durt.i.storage.getIdentityIndexOf(destKeypairEd.address);
    print('Identity index: $edIdtyIndex');

    final edBalance = await Durt.i.storage.getBalance(destKeypairEd.address);
    print('Balance: ${edBalance.transferableBalance}');

    // Check on-chain state for root sr25519 address
    print('\n=== On-chain state for ROOT sr25519: ${destKeypairSr.address} ===');
    final srIdtyStatus = await Durt.i.storage.getIdtyStatus(destKeypairSr.address);
    print('Identity status: $srIdtyStatus');

    final srIdtyIndex = await Durt.i.storage.getIdentityIndexOf(destKeypairSr.address);
    print('Identity index: $srIdtyIndex');

    final srBalance = await Durt.i.storage.getBalance(destKeypairSr.address);
    print('Balance: ${srBalance.transferableBalance}');

    // Check the mystery key 0x04c67def... from the failed tx at block 19555
    print('\n=== Investigating failed tx destination key ===');
    print('Failed tx destination (hex): 0x04c67def511dccd144a063d2fa53b9684caf363eabf4be72c226e4eaf42f2c64');

    // Print hex public keys for all derivations to find a match
    String toHex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

    const targetHex = '04c67def511dccd144a063d2fa53b9684caf363eabf4be72c226e4eaf42f2c64';
    const signerHex = '170f5bee192640bb994bb258a7afac2ed3fba6fbd6f6f3f3c3832196a335d692';

    print('\nRoot ed25519 pubkey: ${toHex(destKeypairEd.publicKey.bytes)}');
    print('Root sr25519 pubkey: ${toHex(destKeypairSr.publicKey.bytes)}');
    print('Signer match root ed25519: ${toHex(destKeypairEd.publicKey.bytes) == signerHex}');

    for (int i = 0; i < 10; i++) {
      final kp = await Durt.i.wallets.getKeyPairFromMnemonic(
        englishMnemonic,
        derivation: i,
        keyPairType: KeyPairType.ed25519,
      );
      final hex = toHex(kp.publicKey.bytes);
      final match = hex == targetHex;
      print('  ed25519 //$i: ${kp.address} pubkey=$hex ${match ? "*** MATCH ***" : ""}');
    }

    for (int i = 0; i < 10; i++) {
      final kp = await Durt.i.wallets.getKeyPairFromMnemonic(
        englishMnemonic,
        derivation: i,
        keyPairType: KeyPairType.sr25519,
      );
      final hex = toHex(kp.publicKey.bytes);
      final match = hex == targetHex;
      print('  sr25519 //$i: ${kp.address} pubkey=$hex ${match ? "*** MATCH ***" : ""}');
    }

    // Also check the identity status of 0x04c67def via its SS58 address
    // Try to find it in Squid or on-chain
    print('\n=== On-chain identity for mystery key ===');
    // We need to query by address - let's try to encode 0x04c67def as SS58
    // For now, let's check a few known addresses

    // Summary
    print('\n=== SUMMARY ===');
    if (edIdtyIndex != null) {
      print('FOUND: ed25519 ROOT address HAS identity index $edIdtyIndex (status: $edIdtyStatus)');
      print('This is hypericum identity - migration at block 19545 SUCCEEDED');
    }
    print('Failed tx at block 19555: signer=new root (0x170f5bee...), dest=0x04c67def...');
    print('Error: identity.OwnerKeyAlreadyUsed');
  });
}
