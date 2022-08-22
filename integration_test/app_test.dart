import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:integration_test/integration_test.dart';

import 'package:gecko/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('Ğecko basics', (tester) async {
      app.main();
      // await Future.delayed(const Duration(seconds: 5));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // await deleteAllWallets(tester);
      await restoreChest(tester);

      // Verify the Gecko is well connected.
      // await waitFor(tester, 'Vous êtes bien connecté');

      // Open my chest
      await goKey(tester, 'manageWallets', duration: 500);
      // await goKey(tester, 'chooseChest');

      // Enter secret code
      await enterText(tester, keyPinForm, 'AAAAA');

      await tester.pumpAndSettle();

      // Verify the wallet 3 is here
      await waitFor(tester, 'Porteuille 3');
    });
  });
}

// Customs actions
Future deleteAllWallets(WidgetTester tester) async {
  await goKey(tester, 'drawerMenu');
  await goKey(tester, 'parameters');
  await goKey(tester, 'deleteAllWallets');
  await goKey(tester, 'confirmPopop');
  await tester.pumpAndSettle();
}

Future restoreChest(WidgetTester tester) async {
  await goKey(tester, 'restoreChest');
  Clipboard.setData(const ClipboardData(
      text:
          'smart joy blossom stomach champion fun diary relief gossip hospital logic bike'));
  await tester.pumpAndSettle();
  await goKey(tester, 'pasteMnemonic');
  await tester.pumpAndSettle();
  await goKey(tester, 'goNext');
  await goKey(tester, 'goNext');
  await goKey(tester, 'goNext');
  await goKey(tester, 'goNext');
  await goKey(tester, 'cachePassword');
  await enterText(tester, keyPinForm, 'AAAAA');
  await waitFor(tester, 'Accéder à mon coffre');
  await goKey(tester, 'goWalletHome');
  await waitFor(tester, 'ĞD');
  await goBack(tester);
  await waitFor(tester, "y'a pas de lézard");
}

// CUSTOM METHODES
Future goKey(WidgetTester tester, String buttonKey,
    {Finder? customFinder, int duration = 100}) async {
  await tester.pumpAndSettle(Duration(milliseconds: duration));
  final Finder finder = customFinder ?? find.byKey(Key(buttonKey));
  await tester.tap(finder);
  // await tester.pumpAndSettle(Duration(milliseconds: duration));
}

Future goBack(WidgetTester tester) async {
  final NavigatorState navigator = tester.state(find.byType(Navigator));
  navigator.pop();
  await tester.pump();
}

Future enterText(
    WidgetTester tester, GlobalKey<FormState> fieldKey, String textIn,
    [int duration = 200]) async {
  await tester.pumpAndSettle(Duration(milliseconds: duration));
  await tester.enterText(find.byKey(fieldKey), textIn);
}

Future<void> waitFor(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);

  Finder finder = find.textContaining(text);

  do {
    if (DateTime.now().isAfter(end)) {
      throw Exception('Timed out waiting for text $text');
    }

    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
  } while (finder.evaluate().isEmpty);
}

extension Truncate on String {
  String truncate({required int max, String suffix = ''}) {
    return length < max
        ? this
        : '${substring(0, substring(0, max - suffix.length).lastIndexOf(" "))}$suffix';
  }
}
