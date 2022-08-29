import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'tests_utility.dart';

// GENERAL ACTIONS

Future changeNode() async {
  final ipAddress = dotenv.env['ip_address'] ?? '127.0.0.1';
  log.d('ip address: $ipAddress');

  await tapKey(keyDrawerMenu);
  await tapKey(keyParameters);
  await tapKey(keySelectDuniterNodeDropDown, duration: 5);
  await tapKey(keySelectDuniterNode('Personnalisé'), selectLast: true);
  await enterText(keyCustomDuniterEndpoint, 'ws://$ipAddress:9944');
  await tapKey(keyConnectToEndpoint);
  await isIconPresent(Icons.add_card_sharp,
      timeout: const Duration(seconds: 8));
  await goBack();
}

Future deleteAllWallets() async {
  if (await isPresent('Rechercher')) {
    await tapKey(keyDrawerMenu);
    await tapKey(keyParameters);
    await tapKey(keyDeleteAllWallets);
    await tapKey(keyConfirm);
    await tester.pumpAndSettle();
  }
}

Future restoreChest() async {
  // Copy test mnemonic in clipboard
  await clipCopy(testMnemonic);

  // Open screen import chest
  await tapKey(keyRestoreChest, duration: 0);

  // Tap on button to paste mnemonic
  await tapKey(keyPastMnemonic);

  // Tap on next button 4 times to skip 3 screen
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);

  // Check if cached password checkbox is checked
  final isCached = await isIconPresent(Icons.check_box);

  // If not, tap on to cache password
  if (!isCached) await tapKey(keyCachePassword, duration: 0);

  // Enter password
  await enterText(keyPinForm, 'AAAAA', 0);

  // Check if string "Accéder à mon coffre" is present in screen
  await waitFor('Accéder à mon coffre');

  // Go to wallets home
  await tapKey(keyGoWalletsHome, duration: 0);

  // Check if string "ĞD" is present in screen
  await waitFor('ĞD');

  // Tap on add a new derivation button
  await addDerivation();

  // Tap on Wallet 5
  await tapKey(keyOpenWallet(test5.address));

  // Copy address of Wallet 5
  await tapKey(keyCopyAddress);

  // Check if string "Cette adresse a été copié" is present in screen
  await waitFor('Cette adresse a été copié');

  // Pop screen 2 time to go back home
  await goBack();
  await goBack();
}

Future addDerivation() async {
  await tapKey(keyAddDerivation);
  await waitFor('Portefeuille 5');
}

Future firstOpenChest() async {
  await tapKey(keyOpenWalletsHomme);
  sleep(300);
  final isCached = await isIconPresent(Icons.check_box);
  if (!isCached) await tapKey(keyCachePassword, duration: 0);
  await enterText(keyPinForm, 'AAAAA', 0);
  await waitFor('100.0 $currencyName');
}
