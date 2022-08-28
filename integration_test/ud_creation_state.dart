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

  testWidgets('Gecko complete', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await fastStart();

    // Open chest
    await firstOpenChest();

    // Go to test1 options and check if balance growup with UDs creations
    await goKey(keyOpenWallet(test1.address));
    await waitFor('100.0 $currencyName');
    await spawnBlock(until: 10);
    await waitFor('200.0 $currencyName');
    await spawnBlock(until: 20);
    await waitFor('300.0 $currencyName');
  }, timeout: testTimeout());
}
