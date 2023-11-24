import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';
import '../utility/general_actions.dart';
import '../utility/tests_utility.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load();

  testWidgets('Migrate Cesium identity and balance', (testerLoc) async {
    tester = testerLoc;
    // Connect local node and import test chest in background
    await bkFastStart();

    // Open chest
    await firstOpenChest();

    // Go to test1 options and check if balance growup with UDs creations
    await tapKey(keyAddDerivation);
    await waitFor(' 6');

    await scrollUntil(keyImportG1v1);
    await tapKey(keyImportG1v1);
    await enterText(keyCesiumId, 'test');
    await enterText(keyCesiumPassword, 'test');
    await waitFor('DCovzCEnQm9GUWe6mr8u42JR1JAuoj3HbQUGdCkfTzSr');
    await waitFor('100.0');
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
    spawnBlock(duration: 1000);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    await waitFor('sending'.tr(),
        reverse: true, settle: false, timeout: const Duration(seconds: 20));
    await tapKey(keyCloseTransactionScreen, duration: 0);

    await tapKey(keyOpenWallet(test6.address), duration: 300);
    await waitFor('3', exactMatch: true);
    await waitFor('memberValidated'.tr());

    await waitFor('110.01', exactMatch: true);
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
