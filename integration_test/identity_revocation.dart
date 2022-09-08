import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import 'general_actions.dart';
import 'tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  testWidgets('Identity revocation', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await bkFastStart();

    // Open chest
    await firstOpenChest();

    // Revoke test3
    await spawnBlock();
    await tapKey(keyOpenWallet(test3.address));
    await tapKey(keyManageMembership);
    await tapKey(keyRevokeIdty);
    await tapKey(keyConfirm);
    spawnBlock(duration: 2000);
    await waitFor('validé !', timeout: const Duration(seconds: 4));
    await tapKey(keyCloseTransactionScreen, duration: 0);
    await waitFor('Membre validé !', reverse: true);
  }, timeout: testTimeout());
}
