import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import '../utility/general_actions.dart';
import '../utility/tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load();

  testWidgets('Certifications state', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await bkFastStart();

    // Open chest
    await firstOpenChest();
    spawnBlock(until: 15);
    await goBack();

    // Go wallet 5 view
    await tapKey(keyOpenSearch);
    await enterText(keySearchField, test5.address);
    await tapKey(keyConfirmSearch);
    await waitFor(test5.shortAddress());
    await tapKey(keySearchResult(test5.address));
    await waitFor('certify'.tr());
    await waitFor('mustWaitXBeforeCertify'.tr().substring(0, 6), reverse: true);
    await waitFor('canRenewCertInX'.tr().substring(0, 8), reverse: true);

    // Background pay 25
    await bkPay(
        fromAddress: test1.address, destAddress: test5.address, amount: 25);
    await waitFor('25.0', exactMatch: true);
    await spawnBlock();
    await waitFor('22.0', exactMatch: true);
    await bkCertify(
        fromAddress: test1.address,
        destAddress: test5.address,
        spawnBloc: false);
    await bkConfirmIdentity(fromAddress: test5.address, name: test5.name);
    await waitFor('1', exactMatch: true);
    await bkCertify(
        fromAddress: test2.address,
        destAddress: test5.address,
        spawnBloc: false);
    // await waitFor('2', exactMatch: true);
    await bkCertify(fromAddress: test3.address, destAddress: test5.address);
    await waitFor('3', exactMatch: true);
    await bkCertify(fromAddress: test4.address, destAddress: test5.address);
    await waitFor('4', exactMatch: true);
    // await bkPay(
    //     fromAddress: test2.address, destAddress: test5.address, amount: 40);
    await waitFor('21.99', exactMatch: true);
    await spawnBlock(until: 30);
    await waitFor('121.99', exactMatch: true);
    await spawnBlock(until: 40);
    await waitFor('221.99', exactMatch: true);
  }, timeout: testTimeout());
}
