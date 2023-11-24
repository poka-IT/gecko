import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:provider/provider.dart';
import 'tests_utility.dart';

// GENERAL ACTIONS

Future changeNode() async {
  const ipAddress = '10.0.2.2';
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
  if (await isPresent('searchWallet'.tr())) {
    await tapKey(keyDrawerMenu);
    await tapKey(keyParameters);

    // Check if ud unit checkbox is checked
    final isUdUnit = await isIconPresent(Icons.check_box);
    // If yes, tap on to use currency value
    if (isUdUnit) await tapKey(keyUdUnit, duration: 0);

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

  // pump a few frame
  await pump(duration: const Duration(milliseconds: 500), number: 10);

  // Check if string "Accéder à mon coffre" is present in screen
  await waitFor('accessMyChest'.tr(), settle: false);

  // Go to wallets home
  await tapKey(keyGoWalletsHome, duration: 0);

  // Skip tutorial
  await skipWalletDragTutorial();

  // Check if string "ĞD" is present in screen
  await waitFor('ĞD');

  // Tap on add a new derivation button
  await addDerivation();

  // Tap on Wallet 5
  await tapKey(keyOpenWallet(test5.address));

  // Copy address of Wallet 5
  await tapKey(keyCopyAddress);

  // Check if string "Cette adresse a été copié" is present in screen
  await waitFor('thisAddressHasBeenCopiedToClipboard'.tr());

  // Pop screen 2 time to go back home
  await goBack();
  await goBack();
}

Future onboardingNewChest() async {
  final generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(homeContext, listen: false);
  // Open screen create new wallet
  await tapKey(keyOnboardingNewChest);

  // Tap on next button 4 times to skip 3 screen
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);
  await waitFor('7', exactMatch: true);

  final word41 = getWidgetText(keyMnemonicWord('4'));

  // Change 2 times mnemonic
  await tapKey(keyGenerateMnemonic);
  await tester.pumpAndSettle();
  final word42 = getWidgetText(keyMnemonicWord('4'));
  expect(word41, isNot(word42));
  await tapKey(keyGenerateMnemonic, duration: 500);
  await tester.pumpAndSettle();
  final word43 = getWidgetText(keyMnemonicWord('4'));
  expect(word42, isNot(word43));

  // Go next screen
  await tapKey(keyGoNext);
  await tester.pumpAndSettle();

  // Enter asked word
  final askedWordNumber = int.parse(getWidgetText(keyAskedWord));
  List mnemonic = generateWalletProvider.generatedMnemonic!.split(' ');

  final askedWord = mnemonic[askedWordNumber - 1];
  await enterText(keyInputWord, askedWord);
  await waitFor('continue'.tr(), exactMatch: true);
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);
  await tapKey(keyGoNext);
  await waitFor('AAAAA', exactMatch: true);
  await tapKey(keyGoNext);

  // Check if cached password checkbox is checked
  final isCached = await isIconPresent(Icons.check_box);

  // If not, tap on to cache password
  if (!isCached) await tapKey(keyCachePassword, duration: 0);

  // Enter password
  await enterText(keyPinForm, 'AAAAA', 0);

  // Check if string "Accéder à mon coffre" is present in screen
  await waitFor('accessMyChest'.tr());

  // Go to wallets home
  await tapKey(keyGoWalletsHome, duration: 0);

  // Check if string "Mon portefeuille co" is present in screen
  await waitFor('currentWallet'.tr());
  await waitFor('0.0', exactMatch: true);
}

Future addDerivation() async {
  await tapKey(keyAddDerivation);
  await waitFor(' 5');
}

Future firstOpenChest() async {
  await tapKey(keyOpenWalletsHomme);
  sleep(300);
  final isCached = await isIconPresent(Icons.check_box);
  if (!isCached) await tapKey(keyCachePassword, duration: 0);
  await enterText(keyPinForm, 'AAAAA', 0);
  await skipWalletDragTutorial();
  await waitFor(test1.name);
}

Future skipWalletDragTutorial() async {
  await pump(duration: const Duration(milliseconds: 500), number: 4);
  await pump(duration: const Duration(seconds: 2));
  if (await isPresent('explainDraggableWallet'.tr().substring(0, 13),
      timeout: const Duration(seconds: 5), settle: false)) {
    await tapKey(keyDragAndDrop, duration: 0);
  }
}
