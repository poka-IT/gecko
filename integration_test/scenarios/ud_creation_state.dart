import 'package:durt2/durt2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import '../utility/general_actions.dart';
import '../utility/tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load();

  testWidgets('UDs creation state', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await bkFastStart();

    // Open chest
    await firstOpenChest();

    // Go to test1 options and check if balance growup with UDs creations
    await tapKey(keyOpenWallet(test1.address));
    await waitFor('100.0', exactMatch: true);
    await Durt.i.duniter.spawnBlock(until: 10);
    await waitFor('200.0', exactMatch: true);
    await Durt.i.duniter.spawnBlock(until: 20);
    await waitFor('300.0', exactMatch: true);
  }, timeout: testTimeout());
}
