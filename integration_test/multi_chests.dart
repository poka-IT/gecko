import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import 'general_actions.dart';
import 'tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  testWidgets('Onboarding and multi chest', (testerLoc) async {
    tester = testerLoc;
    await bkFastStart(false);
    await onboardingNewChest();
  }, timeout: testTimeout());
}
