import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

// TEST WALLETS CONSTS
const testMnemonic =
    'pipe paddle ketchup filter life ice feel embody glide quantum ride usage';
final test1 =
    TestWallet('5FeggKqw2AbnGZF9Y9WPM2QTgzENS3Hit94Ewgmzdg5a3LNa', 'test1');
final test2 =
    TestWallet('5E4i8vcNjnrDp21Sbnp32WHm2gz8YP3GGFwmdpfg5bHd8Whb', 'test2');
final test3 =
    TestWallet('5FhTLzXLNBPmtXtDBFECmD7fvKmTtTQDtvBTfVr97tachA1p', 'test3');
final test4 =
    TestWallet('5DXJ4CusmCg8S1yF6JGVn4fxgk5oFx42WctXqHZ17mykgje5', 'test4');
final test5 =
    TestWallet('5Dq3giahrBfykJogPetZJ2jjSmhw49Fa7i6qKkseUvRJ2T3R', 'test5');
// final test6 =
//     TestWallet('5FeggKqw2AbnGZF9Y9WPM2QTgzENS3Hit94Ewgmzdg5a3LNa', 'test6');
// final test7 =
//     TestWallet('5FeggKqw2AbnGZF9Y9WPM2QTgzENS3Hit94Ewgmzdg5a3LNa', 'test7');
// final test8 =
//     TestWallet('5FeggKqw2AbnGZF9Y9WPM2QTgzENS3Hit94Ewgmzdg5a3LNa', 'test8');

// CUSTOM FUNCTIONS

Future sleep(WidgetTester tester, [int time = 1000]) async {
  await Future.delayed(Duration(milliseconds: time));
}

Future goKey(WidgetTester tester, Key buttonKey,
    {Finder? customFinder, int duration = 100, bool selectLast = false}) async {
  if (duration != 0) {
    await tester.pumpAndSettle(Duration(milliseconds: duration));
  }
  final Finder finder = customFinder ?? find.byKey(buttonKey);
  log.d('INTEGRATION TEST: Tap on ${finder.description}}');
  await tester.tap(selectLast ? finder.last : finder);
  // await tester.pumpAndSettle(Duration(milliseconds: duration));
}

Future goBack(WidgetTester tester) async {
  final NavigatorState navigator = tester.state(find.byType(Navigator));
  log.d('INTEGRATION TEST: Go back');
  navigator.pop();
  await tester.pump();
}

Future enterText(WidgetTester tester, Key fieldKey, String textIn,
    [int duration = 200]) async {
  if (duration != 0) {
    await tester.pumpAndSettle(Duration(milliseconds: duration));
  }
  log.d('INTEGRATION TEST: Enter text: $textIn');
  await tester.enterText(find.byKey(fieldKey), textIn);
}

Future<void> waitFor(WidgetTester tester, String text,
    {Duration timeout = const Duration(seconds: 5),
    bool reverse = false,
    bool exactMatch = false}) async {
  final end = DateTime.now().add(timeout);

  Finder finder = exactMatch ? find.text(text) : find.textContaining(text);
  log.d('INTEGRATION TEST: Wait for: $text');

  do {
    if (DateTime.now().isAfter(end)) {
      throw Exception('Timed out waiting for text $text');
    }

    await tester.pumpAndSettle();
    await Future.delayed(const Duration(milliseconds: 100));
  } while (reverse ? finder.evaluate().isNotEmpty : finder.evaluate().isEmpty);
}

// Test if text is visible on screen, return a boolean
Future<bool> isPresent(WidgetTester tester, String text,
    {Duration timeout = const Duration(seconds: 1)}) async {
  try {
    await waitFor(tester, text, timeout: timeout);
    return true;
  } catch (exception) {
    return false;
  }
}

// Test if widget exist on screen, return a boolean
Future<bool> isIconPresent(WidgetTester tester, IconData icon,
    {Duration timeout = const Duration(seconds: 1)}) async {
  await tester.pumpAndSettle();
  final finder = find.byIcon(icon);
  log.d('tatatatatatata: ${finder.evaluate()}');
  return finder.evaluate().isEmpty ? false : true;
}

Future spawnBlock(WidgetTester tester,
    {int number = 1, int duration = 200, int? until}) async {
  if (duration != 0) {
    await sleep(tester, duration);
  }
  if (until != null) {
    number = until - sub.blocNumber;
  }
  await sub.spawnBlock(number);
  await sleep(tester, 200);
}

Future pay(WidgetTester tester,
    {required String fromAddress,
    required String destAddress,
    required double amount}) async {
  sub.pay(
      fromAddress: fromAddress,
      destAddress: destAddress,
      amount: amount,
      password: 'AAAAA');
  await spawnBlock(tester);
  await sleep(tester, 500);
}

Future certify(WidgetTester tester,
    {required String fromAddress, required String destAddress}) async {
  sub.certify(fromAddress, destAddress, 'AAAAA');
  await spawnBlock(tester);
  await sleep(tester, 500);
}

Future confirmIdentity(WidgetTester tester,
    {required String fromAddress, required String name}) async {
  sub.confirmIdentity(fromAddress, name, 'AAAAA');
  await spawnBlock(tester);
  await sleep(tester, 500);
}

class TestWallet {
  String address;
  String name;

  TestWallet(this.address, this.name);

  endAddress() => address.substring(address.length - 6);
  shortAddress() => getShortPubkey(address);
}
