import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import 'general_actions.dart';
import 'tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  testWidgets('Certifications state', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await bkFastStart();

    // Open chest
    await firstOpenChest();
    await goBack();

    // Go wallet 5 view
    await tapKey(keyOpenSearch);
    await enterText(keySearchField, test5.address);
    await tapKey(keyConfirmSearch);
    await waitFor(test5.shortAddress());
    await tapKey(keySearchResult(test5.address));
    await waitFor('Certifier');
    await waitFor('Vous devez ', reverse: true);
    await waitFor('Vous pourrez renouveler ', reverse: true);

    // Background pay 25
    await bkPay(
        fromAddress: test1.address, destAddress: test5.address, amount: 25);
    await waitFor('25.0 $currencyName');
    await spawnBlock();
    await waitFor('22.0 $currencyName');
    await bkCertify(fromAddress: test1.address, destAddress: test5.address);
    await waitFor('1', exactMatch: true);
    await bkConfirmIdentity(fromAddress: test5.address, name: test5.name);
    await bkCertify(fromAddress: test2.address, destAddress: test5.address);
    await waitFor('2', exactMatch: true);
    await bkCertify(fromAddress: test3.address, destAddress: test5.address);
    await waitFor('3', exactMatch: true);
    await bkCertify(fromAddress: test4.address, destAddress: test5.address);
    await waitFor('4', exactMatch: true);
    await bkPay(
        fromAddress: test2.address, destAddress: test5.address, amount: 40);
    await waitFor('61.99 $currencyName');
    await spawnBlock(until: 10);
    await waitFor('161.99 $currencyName');
    await spawnBlock(until: 20);
    await waitFor('261.99 $currencyName');
  }, timeout: testTimeout());
}
