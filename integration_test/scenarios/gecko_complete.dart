import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import '../utility/general_actions.dart';
import '../utility/tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  testWidgets('Gecko complete', (testerLoc) async {
    // Share WidgetTester to test provider
    tester = testerLoc;

    // Start app and wait finish starting
    await startWait();

    // Change Duniter endpoint to local
    await changeNode();

    // Delete all existing chests is exists
    await deleteAllWallets();

    // Restore the test chest
    await restoreChest();

    // Execute a transaction to test5
    await payTest2();

    // Certify test5 account with 3 accounts to become member
    await certifyTest5();
  }, timeout: testTimeout());
}

Future payTest2() async {
  spawnBlock(until: 13);
  await waitFor('searchWallet'.tr());
  await tapKey(keyOpenSearch);
  final addressToSearch = await clipPaste();
  final endAddress = addressToSearch.substring(addressToSearch.length - 6);
  expect(addressToSearch, test5.address);
  await enterText(keySearchField, addressToSearch);
  await tapKey(keyConfirmSearch);
  await waitFor(endAddress);
  await tapKey(keySearchResult(addressToSearch));
  await waitFor(endAddress);
  await waitFor('0.0', exactMatch: true);
  await tapKey(keyPay);
  await enterText(keyAmountField, '12.14');
  await tapKey(keyConfirmPayment);
  spawnBlock(duration: 500);

  await waitFor('extrinsicValidated'.tr(), timeout: const Duration(seconds: 1));
  await tapKey(keyCloseTransactionScreen, duration: 0);
  await waitFor('12.14');
  spawnBlock(duration: 500);
  await waitFor('9.14');
  humanRead(2);
}

Future certifyTest5() async {
  // Create identity with Test1 account
  await tapKey(keyCertify);
  await tapKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('extrinsicValidated'.tr(), timeout: const Duration(seconds: 1));
  await tapKey(keyCloseTransactionScreen);
  await waitFor('identityCreated'.tr());

  // Confirm Identity Test5
  await tapKey(keyAppBarChest, duration: 300);
  await tapKey(keyOpenWallet(test5.address));
  await tapKey(keyCopyAddress);
  humanRead(3);
  await tapKey(keyConfirmIdentity);
  await enterText(keyEnterIdentityUsername, test5.name);
  await tapKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('extrinsicValidated'.tr(), timeout: const Duration(seconds: 1));
  await tapKey(keyCloseTransactionScreen);
  await waitFor('identityConfirmed'.tr());
  humanRead(2);
  // Set wallet 2 as default wallet
  await goBack();
  await tapKey(keyOpenWallet(test2.address));
  await tapKey(keySetDefaultWallet);
  await waitFor('thisWalletIsDefault'.tr());

  // Search Wallet 5 again
  await tapKey(keyAppBarSearch);
  final addressToSearch = await clipPaste();
  final endAddress = addressToSearch.substring(addressToSearch.length - 6);
  expect(addressToSearch, test5.address);
  await enterText(keySearchField, addressToSearch);
  await tapKey(keyConfirmSearch);
  await waitFor(endAddress);
  await tapKey(keySearchResult(addressToSearch));
  await waitFor(endAddress);
  await waitFor('1');

  // Certify with test2 account
  await tapKey(keyCertify);
  await tapKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('extrinsicValidated'.tr(), timeout: const Duration(seconds: 1));
  await tapKey(keyCloseTransactionScreen);
  await waitFor('2');

  // Change default wallet to test3
  await tapKey(keyPay);
  await tapKey(keyChangeChest);
  await tapKey(keySelectThisWallet(test3.address));
  await tapKey(keyConfirm);
  await sleep();

  // Certify with test3 account
  await tapKey(keyCertify);
  await tapKey(keyConfirm);
  spawnBlock(duration: 500);
  await waitFor('extrinsicValidated'.tr(), timeout: const Duration(seconds: 1));
  await tapKey(keyCloseTransactionScreen);
  await waitFor('mustWaitXBeforeCertify'.substring(0, 12));

  // Check if test5 is member
  await tapKey(keyAppBarChest, duration: 300);
  await tapKey(keyOpenWallet(test5.address));
  await waitFor('memberValidated'.tr());

  // spawn 20 blocs and check if ud is creating
  await spawnBlock(until: 20);
  await waitFor('109.13');
  await spawnBlock(until: 30);
  await waitFor('209.13');

  // Check UD reval
  await spawnBlock(until: 60);
  await waitFor('509.57');
  humanRead(5);
}
