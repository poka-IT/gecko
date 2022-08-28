import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'tests_utility.dart';

// GENERAL ACTIONS

Future changeNode() async {
  final ipAddress = dotenv.env['ip_address'] ?? '127.0.0.1';
  log.d('ip address: $ipAddress');

  await goKey(keyDrawerMenu);
  await goKey(keyParameters);
  await goKey(keySelectDuniterNodeDropDown, duration: 5);
  await goKey(keySelectDuniterNode('Personnalisé'), selectLast: true);
  await enterText(keyCustomDuniterEndpoint, 'ws://$ipAddress:9944');
  await goKey(keyConnectToEndpoint);
  await isIconPresent(Icons.add_card_sharp,
      timeout: const Duration(seconds: 8));
  await goBack();
}

Future deleteAllWallets() async {
  if (await isPresent('Rechercher')) {
    await goKey(keyDrawerMenu);
    await goKey(keyParameters);
    await goKey(keyDeleteAllWallets);
    await goKey(keyConfirm);
    await tester.pumpAndSettle();
  }
}

Future restoreChest() async {
  // Copy test mnemonic in clipboard
  Clipboard.setData(const ClipboardData(text: testMnemonic));

  // Open screen import chest
  await goKey(keyRestoreChest, duration: 0);

  // Tap on button to paste mnemonic
  await goKey(keyPastMnemonic);

  // Tap on next button 4 times to skip 3 screen
  await goKey(keyGoNext);
  await goKey(keyGoNext);
  await goKey(keyGoNext);
  await goKey(keyGoNext);

  // Check if cached password checkbox is checked
  final isCached = await isIconPresent(Icons.check_box);

  // If not, tap on to cache password
  if (!isCached) await goKey(keyCachePassword, duration: 0);

  // Enter password
  await enterText(keyPinForm, 'AAAAA', 0);

  // Check if string "Accéder à mon coffre" is present in screen
  await waitFor('Accéder à mon coffre');

  // Go to wallets home
  await goKey(keyGoWalletsHome, duration: 0);

  // Check if string "ĞD" is present in screen
  await waitFor('ĞD');

  // Tap on add a new derivation button
  await addDerivation();

  // Tap on Wallet 5
  await goKey(keyOpenWallet(test5.address));

  // Copy address of Wallet 5
  await goKey(keyCopyAddress);

  // Check if string "Cette adresse a été copié" is present in screen
  await waitFor('Cette adresse a été copié');

  // Pop screen 2 time to go back home
  await goBack();
  await goBack();
}

Future addDerivation() async {
  await goKey(keyAddDerivation);
  await waitFor('Portefeuille 5');
}

Future firstOpenChest() async {
  await goKey(keyOpenWalletsHomme);
  sleep(300);
  final isCached = await isIconPresent(Icons.check_box);
  if (!isCached) await goKey(keyCachePassword, duration: 0);
  await enterText(keyPinForm, 'AAAAA', 0);
  await waitFor('100.0 $currencyName');
}
