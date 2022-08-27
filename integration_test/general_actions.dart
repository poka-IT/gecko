import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'tests_utility.dart';

// GENERAL ACTIONS

Future changeNode(WidgetTester tester) async {
  final ipAddress = dotenv.env['ip_address'] ?? '127.0.0.1';
  log.d('ip address: $ipAddress');

  await goKey(tester, keyDrawerMenu);
  await goKey(tester, keyParameters);
  await goKey(tester, keySelectDuniterNodeDropDown, duration: 5);
  await goKey(tester, keySelectDuniterNode('Personnalisé'), selectLast: true);
  await enterText(tester, keyCustomDuniterEndpoint, 'ws://$ipAddress:9944');
  await goKey(tester, keyConnectToEndpoint);
  await isIconPresent(tester, Icons.add_card_sharp,
      timeout: const Duration(seconds: 8));
  await goBack(tester);
}

Future deleteAllWallets(WidgetTester tester) async {
  if (await isPresent(tester, 'Rechercher')) {
    await goKey(tester, keyDrawerMenu);
    await goKey(tester, keyParameters);
    await goKey(tester, keyDeleteAllWallets);
    await goKey(tester, keyConfirm);
    await tester.pumpAndSettle();
  }
}

Future restoreChest(WidgetTester tester) async {
  // Copy test mnemonic in clipboard
  Clipboard.setData(const ClipboardData(text: testMnemonic));

  // Open screen import chest
  await goKey(tester, keyRestoreChest);

  // Wait frame stop before continue
  await tester.pumpAndSettle();

  // Tap on button to paste mnemonic
  await goKey(tester, keyPastMnemonic);

  // Tap on next button 4 times to skip 3 screen
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);

  // Check if cached password checkbox is checked
  final isCached = await isIconPresent(tester, Icons.check_box);

  // If not, tap on to cache password
  if (!isCached) await goKey(tester, keyCachePassword, duration: 0);

  // Enter password
  await enterText(tester, keyPinForm, 'AAAAA', 0);

  // Check if string "Accéder à mon coffre" is present in screen
  await waitFor(tester, 'Accéder à mon coffre');

  // Go to wallets home
  await goKey(tester, keyGoWalletsHome, duration: 0);

  // Check if string "ĞD" is present in screen
  await waitFor(tester, 'ĞD');

  // Tap on add a new derivation button
  await addDerivation(tester);

  // Tap on Wallet 5
  await goKey(tester, keyOpenWallet(test5.address));

  // Copy address of Wallet 5
  await goKey(tester, keyCopyAddress);

  // Check if string "Cette adresse a été copié" is present in screen
  await waitFor(tester, 'Cette adresse a été copié');

  // Pop screen 2 time to go back home screen
  await goBack(tester);
  await goBack(tester);

  // Check if string "y'a pas de lézard" is present in screen
  await waitFor(tester, "y'a pas de lézard");
}

Future addDerivation(WidgetTester tester) async {
  await goKey(tester, keyAddDerivation);
  await waitFor(tester, 'Portefeuille 5');
}
