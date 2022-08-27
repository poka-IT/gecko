import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
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

    // Go wallet 5 view
    await goKey(tester, keyOpenSearch);
    await enterText(tester, keySearchField, test5.address);
    await goKey(tester, keyConfirmSearch);
    await waitFor(tester, test5.shortAddress());
    await goKey(tester, keySearchResult(test5.address));
    await waitFor(tester, 'Certifier');
    await waitFor(tester, 'Vous devez ', reverse: true);
    await waitFor(tester, 'Vous pourrez renouveler ', reverse: true);

    // await spawnBlock(tester, number: 10);
    // Background pay 25
    await pay(tester,
        fromAddress: test1.address, destAddress: test5.address, amount: 25);
    await waitFor(tester, '25.0 $currencyName');
    await spawnBlock(tester);
    await waitFor(tester, '22.0 $currencyName');
    await certify(tester,
        fromAddress: test1.address, destAddress: test5.address);
    await waitFor(tester, '1', exactMatch: true);
    await confirmIdentity(tester, fromAddress: test5.address, name: test5.name);
    await certify(tester,
        fromAddress: test2.address, destAddress: test5.address);

    // // Change default wallet to test3
    // await goKey(tester, keyPay);
    // await goKey(tester, keyChangeChest);
    // await goKey(tester, keySelectThisWallet(test2.address));
    // await goKey(tester, keyConfirm);
    // await sleep(tester);

    // // Certify with test3 account
    // await goKey(tester, keyCertify);
    // await goKey(tester, keyConfirm);
    // await spawnBlock(tester, duration: 500);
    // await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
    // await goKey(tester, keyCloseTransactionScreen);
    // await waitFor(tester, 'Vous devez attendre');

    await waitFor(tester, '2', exactMatch: true);
    await certify(tester,
        fromAddress: test3.address, destAddress: test5.address);
    await waitFor(tester, '3', exactMatch: true);
    await certify(tester,
        fromAddress: test4.address, destAddress: test5.address);
    await waitFor(tester, '4', exactMatch: true);
    await pay(tester,
        fromAddress: test2.address, destAddress: test5.address, amount: 40);
    await waitFor(tester, '61.99 $currencyName');
    await spawnBlock(tester, until: 25);
  });
}
