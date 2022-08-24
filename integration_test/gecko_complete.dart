import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gecko/main.dart' as app;
import 'tests_utility.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gecko complete', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Change Duniter endpoint to local
    await changeNode(tester);

    // Delete all existing chests
    await deleteAllWallets(tester);

    // Restore a chest
    await restoreChest(tester);

    // Execute a transaction to test2
    await payTest2(tester);

    // Certify test5 account with 3 account to become member
    await certifyTest5(tester);
  });
}

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

// Customs actions
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
  Clipboard.setData(const ClipboardData(
      text:
          'pipe paddle ketchup filter life ice feel embody glide quantum ride usage'));

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
  await goKey(tester,
      keyOpenWallet('5Dq3giahrBfykJogPetZJ2jjSmhw49Fa7i6qKkseUvRJ2T3R'));

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

Future payTest2(WidgetTester tester) async {
  await waitFor(tester, 'Rechercher');
  await goKey(tester, keyOpenSearch);
  final addressToSearch = (await Clipboard.getData('text/plain'))!.text;
  final endAddress = addressToSearch!.substring(addressToSearch.length - 6);
  expect(addressToSearch, '5Dq3giahrBfykJogPetZJ2jjSmhw49Fa7i6qKkseUvRJ2T3R');
  await enterText(tester, keySearchField, addressToSearch);
  await goKey(tester, keyConfirmSearch);
  await waitFor(tester, endAddress);
  await goKey(tester, keySearchResult(addressToSearch));
  await waitFor(tester, endAddress);
  await waitFor(tester, '0.0 ĞD');
  await goKey(tester, keyPay);
  await enterText(tester, keyAmountField, '12.14');
  await goKey(tester, keyConfirmPayment);
  // await sleep(tester);
  await spawnBlock(tester, keyCloseTransactionScreen);

  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen, duration: 0);
  await waitFor(tester, '12.14');
  await spawnBlock(tester, keyViewActivity);
  await waitFor(tester, '9.14');
}

Future addDerivation(WidgetTester tester) async {
  await goKey(tester, keyAddDerivation);
  await waitFor(tester, 'Portefeuille 5');
}

Future certifyTest5(WidgetTester tester) async {
  // Create identity with Test1 account
  // await spawnBlock(tester, keyViewActivity, 5);
  // await sleep(tester);
  await goKey(tester, keyCertify);
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, keyViewActivity, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'Identité créée');

  // Confirm Identity Test5
  await goKey(tester, keyAppBarChest, duration: 300);
  await goKey(tester,
      keyOpenWallet('5Dq3giahrBfykJogPetZJ2jjSmhw49Fa7i6qKkseUvRJ2T3R'));
  await goKey(tester, keyCopyAddress);
  await goKey(tester, keyConfirmIdentity);
  await enterText(tester, keyEnterIdentityUsername, 'test5');
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, keyCloseTransactionScreen, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'Identité confirmée');
  await goBack(tester);
  await goKey(tester,
      keyOpenWallet('5E4i8vcNjnrDp21Sbnp32WHm2gz8YP3GGFwmdpfg5bHd8Whb'));
  await goKey(tester, keySetDefaultWallet);
  await waitFor(tester, 'Ce portefeuille est celui par defaut');

  await goKey(tester, keyAppBarSearch);
  final addressToSearch = (await Clipboard.getData('text/plain'))!.text;
  final endAddress = addressToSearch!.substring(addressToSearch.length - 6);
  expect(addressToSearch, '5Dq3giahrBfykJogPetZJ2jjSmhw49Fa7i6qKkseUvRJ2T3R');
  await enterText(tester, keySearchField, addressToSearch);
  await goKey(tester, keyConfirmSearch);
  await waitFor(tester, endAddress);
  await goKey(tester, keySearchResult(addressToSearch));
  await waitFor(tester, endAddress);
  await waitFor(tester, '1');

  // Certify with test2 account
  await goKey(tester, keyCertify);
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, keyViewActivity, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, '2');

  // Change default wallet to test3
  await goKey(tester, keyPay);
  await goKey(tester, keyChangeChest);
  await goKey(tester,
      keySelectThisWallet('5FhTLzXLNBPmtXtDBFECmD7fvKmTtTQDtvBTfVr97tachA1p'));
  await goKey(tester, keyConfirm);
  await sleep(tester);

  // Certify with test3 account
  await goKey(tester, keyCertify);
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, keyViewActivity, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'Vous devez attendre');

  // Check if test5 is member
  await goKey(tester, keyAppBarChest, duration: 300);
  await goKey(tester,
      keyOpenWallet('5Dq3giahrBfykJogPetZJ2jjSmhw49Fa7i6qKkseUvRJ2T3R'));
  await waitFor(tester, 'Membre validé !');
}
