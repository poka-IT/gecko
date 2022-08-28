import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gecko/main.dart' as app;
import 'general_actions.dart';
import 'tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  testWidgets('Gecko complete', (testerLoc) async {
    tester = testerLoc;
    app.main();
    await waitFor('Test starting...', reverse: true);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await sleep(2000);

    // Change Duniter endpoint to local
    await changeNode();

    // Delete all existing chests is exists
    await deleteAllWallets();

    // Restore the test chest
    await restoreChest();

    // Execute a transaction to test2
    await payTest2();

    // Certify test5 account with 3 accounts to become member
    await certifyTest5();
  }, timeout: testTimeout());
}

Future payTest2() async {
  await waitFor('Rechercher');
  await goKey(keyOpenSearch);
  final addressToSearch = (await Clipboard.getData('text/plain'))!.text;
  final endAddress = addressToSearch!.substring(addressToSearch.length - 6);
  expect(addressToSearch, test5.address);
  await enterText(keySearchField, addressToSearch);
  await goKey(keyConfirmSearch);
  await waitFor(endAddress);
  await goKey(keySearchResult(addressToSearch));
  await waitFor(endAddress);
  await waitFor('0.0 ĞD');
  await goKey(keyPay);
  await enterText(keyAmountField, '12.14');
  await goKey(keyConfirmPayment);
  spawnBlock(duration: 500);

  await waitFor('validé !', timeout: const Duration(seconds: 1));
  await goKey(keyCloseTransactionScreen, duration: 0);
  await waitFor('12.14');
  spawnBlock(duration: 500);
  await waitFor('9.14');
  humanRead(2);
}

Future certifyTest5() async {
  // Create identity with Test1 account
  await goKey(keyCertify);
  await goKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('validé !', timeout: const Duration(seconds: 1));
  await goKey(keyCloseTransactionScreen);
  await waitFor('Identité créée');

  // Confirm Identity Test5
  await goKey(keyAppBarChest, duration: 300);
  await goKey(keyOpenWallet(test5.address));
  await goKey(keyCopyAddress);
  humanRead(3);
  await goKey(keyConfirmIdentity);
  await enterText(keyEnterIdentityUsername, test5.name);
  await goKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('validé !', timeout: const Duration(seconds: 1));
  await goKey(keyCloseTransactionScreen);
  await waitFor('Identité confirmée');
  humanRead(2);
  // Set wallet 2 as default wallet
  await goBack();
  await goKey(keyOpenWallet(test2.address));
  await goKey(keySetDefaultWallet);
  await waitFor('Ce portefeuille est celui par defaut');

  // Search Wallet 5 again
  await goKey(keyAppBarSearch);
  final addressToSearch = (await Clipboard.getData('text/plain'))!.text;
  final endAddress = addressToSearch!.substring(addressToSearch.length - 6);
  expect(addressToSearch, test5.address);
  await enterText(keySearchField, addressToSearch);
  await goKey(keyConfirmSearch);
  await waitFor(endAddress);
  await goKey(keySearchResult(addressToSearch));
  await waitFor(endAddress);
  await waitFor('1');

  // Certify with test2 account
  await goKey(keyCertify);
  await goKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('validé !', timeout: const Duration(seconds: 1));
  await goKey(keyCloseTransactionScreen);
  await waitFor('2');

  // Change default wallet to test3
  await goKey(keyPay);
  await goKey(keyChangeChest);
  await goKey(keySelectThisWallet(test3.address));
  await goKey(keyConfirm);
  await sleep();

  // Certify with test3 account
  await goKey(keyCertify);
  await goKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('validé !', timeout: const Duration(seconds: 1));
  await goKey(keyCloseTransactionScreen);
  await waitFor('Vous devez attendre');

  // Check if test5 is member
  await goKey(keyAppBarChest, duration: 300);
  await goKey(keyOpenWallet(test5.address));
  await waitFor('Membre validé !');

  // spawn 20 blocs and check if ud is creating
  await spawnBlock(until: 10);
  await waitFor('109.13');
  await spawnBlock(until: 20);
  await waitFor('209.13');

  // Check UD reval
  await spawnBlock(until: 50);
  await waitFor('509.35');
  humanRead(5);
}
