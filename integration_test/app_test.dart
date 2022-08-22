import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';

import 'package:gecko/main.dart' as app;

import 'tests_utility.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ğecko basics', () {
    testWidgets('Import chests', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // await deleteAllWallets(tester);
      await restoreChest(tester);
    });
    testWidgets('Send 10 ĞD to ChristCosmic', (tester) async {
      // await goKey(tester, buttonKey);
    });
  });
}

// Customs actions
Future deleteAllWallets(WidgetTester tester) async {
  await goKey(tester, keyDrawerMenu);
  await goKey(tester, keyParameters);
  await goKey(tester, keyDeleteAllWallets);
  await goKey(tester, keyConfirm);
  await tester.pumpAndSettle();
}

Future restoreChest(WidgetTester tester) async {
  await goKey(tester, keyRestoreChest);
  Clipboard.setData(const ClipboardData(
      text:
          'smart joy blossom stomach champion fun diary relief gossip hospital logic bike'));
  await tester.pumpAndSettle();
  await goKey(tester, keyPastMnemonic);
  await tester.pumpAndSettle();
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  await goKey(tester, keyCachePassword);
  await enterText(tester, keyPinForm, 'AAAAA');
  await waitFor(tester, 'Accéder à mon coffre');
  await goKey(tester, keyGoWalletsHome);
  await waitFor(tester, 'ĞD');
  await goBack(tester);
  await waitFor(tester, "y'a pas de lézard");
}
