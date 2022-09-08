import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import '../utility/general_actions.dart';
import '../utility/tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  testWidgets('Migrate Cesium identity and balance', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await bkFastStart();

    // Open chest
    await firstOpenChest();

    // Go to test1 options and check if balance growup with UDs creations
    await tapKey(keyAddDerivation);
    await waitFor('Portefeuille 6');

    await scrollUntil(keyImportG1v1);
    await tapKey(keyImportG1v1);
    await enterText(keyCesiumId, 'test');
    await enterText(keyCesiumPassword, 'test');
    await waitFor(cesiumTest1.shortAddress());
    await waitFor('100.0 $currencyName');
    await waitFor('3', exactMatch: true);

    isObscureText();
    await tapKey(keyCesiumIdVisible);
    await tester.pumpAndSettle();
    isObscureText(false);
    await tapKey(keyCesiumIdVisible);
    await tester.pumpAndSettle();
    isObscureText();

    await tapKey(keySelectWallet);
    await tapKey(keySelectThisWallet(test6.address), selectLast: true);
    await waitForButtonEnabled(keyConfirm);
    await tapKey(keyConfirm);
    spawnBlock(duration: 2000);
    await waitFor('validé !');
    await tapKey(keyCloseTransactionScreen, duration: 0);

    await tapKey(keyOpenWallet(test6.address), duration: 300);
    await waitFor('3', exactMatch: true);
    await waitFor('Membre validé !');

    await waitFor('99.98 $currencyName');
  }, timeout: testTimeout());
}

isObscureText([bool isObscure = true]) {
  final passwordTextFormField = find.descendant(
    of: find.byKey(keyCesiumId),
    matching: find.byType(EditableText),
  );
  final input = tester.widget<EditableText>(passwordTextFormField);
  expect(input.obscureText, isObscure ? isTrue : isFalse);
}
