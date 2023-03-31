import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import '../utility/general_actions.dart';
import '../utility/tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load();

  testWidgets('Identity revocation', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await bkFastStart();

    // Open chest
    await firstOpenChest();
    await spawnBlock(until: 13);
    await sleep();

    // Create test5 identity
    await bkPay(
        fromAddress: test1.address, destAddress: test5.address, amount: 30);
    sub.reload();
    await bkCertify(fromAddress: test1.address, destAddress: test5.address);
    sub.reload();
    await sleep();

    // Certify test5 to become member
    await tapKey(keyOpenWallet(test5.address));
    await bkConfirmIdentity(fromAddress: test5.address, name: test5.name);
    await bkCertify(fromAddress: test2.address, destAddress: test5.address);
    await bkCertify(fromAddress: test3.address, destAddress: test5.address);
    await waitFor('memberValidated'.tr(), exactMatch: true);

    // Revoke test5
    await tapKey(keyManageMembership, duration: 5000);
    await tapKey(keyRevokeIdty);
    await tapKey(keyConfirm);
    spawnBlock(duration: 2000);
    await waitFor('extrinsicValidated'.tr().substring(3),
        timeout: const Duration(seconds: 4));
    await tapKey(keyCloseTransactionScreen, duration: 0);
    await waitFor('noIdentity'.tr(), exactMatch: true);
    await sleep();

    // Check test1 cannot be revoked
    await goBack();
    await tapKey(keyAddDerivation);
    await tapKey(keyOpenWallet(test1.address), duration: 500);
    await tapKey(keyManageMembership, duration: 3000);
    await waitFor('youCannotRevokeThisIdentity'.tr().substring(0, 15));
  }, timeout: testTimeout());
}
