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
      final ipAddress = dotenv.env['ip_address'] ?? '127.0.0.1';

      log.d('ip address: $ipAddress');

      // Delete all existing chests
      await deleteAllWallets(tester);

      // Restore a chest
      await restoreChest(tester);

      // Execute a transaction to ChristCosmic
      await payChrist(tester);
    });
  });
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
          'smart joy blossom stomach champion fun diary relief gossip hospital logic bike'));
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

Future payChrist(WidgetTester tester) async {
  await waitFor(tester, 'Rechercher');
  await goKey(tester, keyOpenSearch);
  await enterText(tester, keySearchField, 'ChristCosmic');
  await goKey(tester, keyConfirmSearch);
  await waitFor(tester, 'XuiQeB');
  await goKey(tester,
      keyIndexerResult('5CJKhFCpdSpumgWjSZ3TQmejJuHV6iELJrtdrfs38SXuiQeB'));
  await waitFor(tester, 'XuiQeB');
  await waitFor(tester, 'ĞD');
  await goKey(tester, keyPay);
  await enterText(tester, keyAmountField, '2.14');
  await goKey(tester, keyConfirmPayment);
  await waitFor(tester, 'validé !', timeout: const Duration(seconds: 12));
  await goKey(tester, keyCloseTransactionScreen);
  await waitFor(tester, 'XuiQeB');
}
