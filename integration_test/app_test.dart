import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
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

      // Change Duniter endpoint to local
      await changeNode(tester);

      // Delete all existing chests
      await deleteAllWallets(tester);

      // Restore a chest
      await restoreChest(tester);

      // Execute a transaction to test2
      await payTest2(tester);
    });
  });
}

Future changeNode(WidgetTester tester) async {
  final ipAddress = dotenv.env['ip_address'] ?? '127.0.0.1';
  log.d('ip address: $ipAddress');

  await goKey(tester, keyDrawerMenu);
  await goKey(tester, keyParameters);
  await goKey(tester, keySelectDuniterNodeDropDown, duration: 5);
  await goKey(tester, keySelectDuniterNode('Personnalisé'), selectLast: true);
  await enterText(tester, keyCustomDuniterEndpoint, 'ws://$ipAddress:9944');
  // await sleep(tester, 10000);
  await goKey(tester, keyConnectToEndpoint);
  await isIconPresent(tester, Icons.add_card_sharp,
      timeout: const Duration(seconds: 8));
  await goBack(tester);

  // await waitFor(tester, 'Vous êtes bien connecté');
}

// Customs actions
Future deleteAllWallets(WidgetTester tester) async {
  if (await isPresent(tester, 'Rechercher')) {
    await goKey(tester, keyDrawerMenu);
    await goKey(tester, keyParameters);
    await goKey(tester, keyDeleteAllWallets);
    await goKey(tester, keyConfirm);
    await tester.pumpAndSettle();
  }
}

Future restoreChest(WidgetTester tester) async {
  await goKey(tester, keyRestoreChest);
  Clipboard.setData(const ClipboardData(
      text:
          'pipe paddle ketchup filter life ice feel embody glide quantum ride usage'));
  await tester.pumpAndSettle();
  await goKey(tester, keyPastMnemonic);
  await tester.pumpAndSettle();
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  await goKey(tester, keyGoNext);
  final isCached = await isIconPresent(tester, Icons.check_box);
  if (!isCached) await goKey(tester, keyCachePassword);
  await enterText(tester, keyPinForm, 'AAAAA');
  await waitFor(tester, 'Accéder à mon coffre');
  await goKey(tester, keyGoWalletsHome);
  await waitFor(tester, 'ĞD');
  await goBack(tester);
  await waitFor(tester, "y'a pas de lézard");
}

Future payTest2(WidgetTester tester) async {
  await waitFor(tester, 'Rechercher');
  await goKey(tester, keyOpenSearch);
  await enterText(tester, keySearchField,
      '5E4i8vcNjnrDp21Sbnp32WHm2gz8YP3GGFwmdpfg5bHd8Whb');
  await goKey(tester, keyConfirmSearch);
  await waitFor(tester, 'Hd8Whb');
  await goKey(tester,
      keySearchResult('5E4i8vcNjnrDp21Sbnp32WHm2gz8YP3GGFwmdpfg5bHd8Whb'));
  await waitFor(tester, 'Hd8Whb');
  await waitFor(tester, 'ĞD');
  await goKey(tester, keyPay);
  await enterText(tester, keyAmountField, '2.14');
  await goKey(tester, keyConfirmPayment);
  await sleep(tester);
  await spawnBlock(tester, keyCloseTransactionScreen);

  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 1));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'Hd8Whb');
}
