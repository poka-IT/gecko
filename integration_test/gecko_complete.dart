import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gecko/main.dart' as app;
import 'general_actions.dart';
import 'tests_utility.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gecko complete', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Change Duniter endpoint to local
    await changeNode(tester);

    // Delete all existing chests is exists
    await deleteAllWallets(tester);

    // Restore the test chest
    await restoreChest(tester);

    // Execute a transaction to test2
    await payTest2(tester);

    // Certify test5 account with 3 accounts to become member
    await certifyTest5(tester);
  });
}

Future payTest2(WidgetTester tester) async {
  await waitFor(tester, 'Rechercher');
  await goKey(tester, keyOpenSearch);
  final addressToSearch = (await Clipboard.getData('text/plain'))!.text;
  final endAddress = addressToSearch!.substring(addressToSearch.length - 6);
  expect(addressToSearch, test5.address);
  await enterText(tester, keySearchField, addressToSearch);
  await goKey(tester, keyConfirmSearch);
  await waitFor(tester, endAddress);
  await goKey(tester, keySearchResult(addressToSearch));
  await waitFor(tester, endAddress);
  await waitFor(tester, '0.0 ĞD');
  await goKey(tester, keyPay);
  await enterText(tester, keyAmountField, '12.14');
  await goKey(tester, keyConfirmPayment);
  await spawnBlock(tester);

  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen, duration: 0);
  await waitFor(tester, '12.14');
  await spawnBlock(tester);
  await waitFor(tester, '9.14');
}

Future certifyTest5(WidgetTester tester) async {
  // Create identity with Test1 account
  await goKey(tester, keyCertify);
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'Identité créée');

  // Confirm Identity Test5
  await goKey(tester, keyAppBarChest, duration: 300);
  await goKey(tester, keyOpenWallet(test5.address));
  await goKey(tester, keyCopyAddress);
  await goKey(tester, keyConfirmIdentity);
  await enterText(tester, keyEnterIdentityUsername, test5.name);
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'Identité confirmée');

  // Set wallet 2 as default wallet
  await goBack(tester);
  await goKey(tester, keyOpenWallet(test2.address));
  await goKey(tester, keySetDefaultWallet);
  await waitFor(tester, 'Ce portefeuille est celui par defaut');

  // Search Wallet 5 again
  await goKey(tester, keyAppBarSearch);
  final addressToSearch = (await Clipboard.getData('text/plain'))!.text;
  final endAddress = addressToSearch!.substring(addressToSearch.length - 6);
  expect(addressToSearch, test5.address);
  await enterText(tester, keySearchField, addressToSearch);
  await goKey(tester, keyConfirmSearch);
  await waitFor(tester, endAddress);
  await goKey(tester, keySearchResult(addressToSearch));
  await waitFor(tester, endAddress);
  await waitFor(tester, '1');

  // Certify with test2 account
  await goKey(tester, keyCertify);
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, '2');

  // Change default wallet to test3
  await goKey(tester, keyPay);
  await goKey(tester, keyChangeChest);
  await goKey(tester, keySelectThisWallet(test3.address));
  await goKey(tester, keyConfirm);
  await sleep(tester);

  // Certify with test3 account
  await goKey(tester, keyCertify);
  await goKey(tester, keyConfirm);
  await spawnBlock(tester, duration: 500);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'Vous devez attendre');

  // Check if test5 is member
  await goKey(tester, keyAppBarChest, duration: 300);
  await goKey(tester, keyOpenWallet(test5.address));
  await waitFor(tester, 'Membre validé !');
}
