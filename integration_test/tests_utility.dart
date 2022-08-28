import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;
import 'package:gecko/main.dart' as app;

final bool isHumanReading =
    dotenv.env['isHumanReading'] == 'true' ? true : false;
Timeout testTimeout([int seconds = 120]) =>
    Timeout(Duration(seconds: isHumanReading ? 600 : seconds));
final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
late WidgetTester tester;

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

Future sleep([int time = 1000]) async {
  await Future.delayed(Duration(milliseconds: time));
}

Future humanRead([int time = 1, bool force = false]) async {
  if (isHumanReading || force) io.sleep(Duration(seconds: time));
}

Future goKey(Key buttonKey,
    {Finder? customFinder, int duration = 100, bool selectLast = false}) async {
  if (duration != 0) {
    await tester.pumpAndSettle(Duration(milliseconds: duration));
  }
  final Finder finder = customFinder ?? find.byKey(buttonKey);
  log.d('INTEGRATION TEST: Tap on ${finder.description}}');
  await tester.tap(selectLast ? finder.last : finder);
  humanRead();
}

Future goBack() async {
  final NavigatorState navigator = tester.state(find.byType(Navigator));
  log.d('INTEGRATION TEST: Go back');
  navigator.pop();
  await tester.pump();
  humanRead();
}

Future enterText(Key fieldKey, String textIn, [int duration = 200]) async {
  if (duration != 0) {
    await tester.pumpAndSettle(Duration(milliseconds: duration));
  }
  log.d('INTEGRATION TEST: Enter text: $textIn');
  await tester.enterText(find.byKey(fieldKey), textIn);
  humanRead();
}

Future<void> waitFor(String text,
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
  humanRead();
}

// Test if text is visible on screen, return a boolean
Future<bool> isPresent(String text,
    {Duration timeout = const Duration(seconds: 1)}) async {
  try {
    await waitFor(text, timeout: timeout);
    humanRead();
    return true;
  } catch (exception) {
    humanRead();
    return false;
  }
}

// Test if widget exist on screen, return a boolean
Future<bool> isIconPresent(IconData icon,
    {Duration timeout = const Duration(seconds: 1)}) async {
  await tester.pumpAndSettle();
  final finder = find.byIcon(icon);
  log.d('tatatatatatata: ${finder.evaluate()}');
  humanRead();
  return finder.evaluate().isEmpty ? false : true;
}

Future spawnBlock({int number = 1, int duration = 200, int? until}) async {
  if (duration != 0) {
    await sleep(duration);
  }
  if (until != null) {
    number = until - sub.blocNumber;
  }
  await sub.spawnBlock(number);
  await sleep(200);
}

Future bkPay(
    {required String fromAddress,
    required String destAddress,
    required double amount}) async {
  sub.pay(
      fromAddress: fromAddress,
      destAddress: destAddress,
      amount: amount,
      password: 'AAAAA');
  await spawnBlock();
  await sleep(500);
}

Future bkCertify(
    {required String fromAddress, required String destAddress}) async {
  sub.certify(fromAddress, destAddress, 'AAAAA');
  await spawnBlock();
  await sleep(500);
}

Future bkConfirmIdentity(
    {required String fromAddress, required String name}) async {
  sub.confirmIdentity(fromAddress, name, 'AAAAA');
  await spawnBlock();
  await sleep(500);
}

class TestWallet {
  String address;
  String name;

  TestWallet(this.address, this.name);

  endAddress() => address.substring(address.length - 6);
  shortAddress() => getShortPubkey(address);
}

Future bkSetNode([String? endpoint]) async {
  if (endpoint == null) {
    final ipAddress = dotenv.env['ip_address'] ?? '127.0.0.1';
    endpoint = 'ws://$ipAddress:9944';
  }
  configBox.put('customEndpoint', endpoint);
  sub.connectNode(homeContext);
}

Future bkRestoreChest([String mnemonic = testMnemonic]) async {
  final myWalletProvider =
      Provider.of<MyWalletsProvider>(homeContext, listen: false);
  final generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(homeContext, listen: false);

  await generateWalletProvider.storeHDWChest(homeContext);

  for (int number = 0; number <= 4; number++) {
    await _addImportAccount(
        mnemonic: mnemonic,
        chest: 0,
        number: number,
        name: 'test${number + 1}',
        derivation: (number + 1) * 2);
  }
  myWalletProvider.rebuildWidget();
}

Future<WalletData> _addImportAccount(
    {required String mnemonic,
    required int chest,
    required int number,
    required String name,
    required int derivation}) async {
  final address = await sub.importAccount(
      mnemonic: mnemonic, derivePath: '//$derivation', password: 'AAAAA');
  final myWallet = WalletData(
      version: dataVersion,
      chest: chest,
      address: address,
      number: number,
      name: name,
      derivation: derivation,
      imageDefaultPath: '${number % 4}.png');
  await walletBox.add(myWallet);

  return myWallet;
}

Future bkDeleteAllWallets() async {
  final myWalletProvider =
      Provider.of<MyWalletsProvider>(homeContext, listen: false);
  if (myWalletProvider.listWallets.isNotEmpty) {
    await myWalletProvider.deleteAllWallet(homeContext);
    myWalletProvider.rebuildWidget();
  }
}

Future fastStart() async {
  app.main();
  await waitFor('Test starting...', reverse: true);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await sleep(2000);

  // Connect to local endpoint
  await bkSetNode();
  await sleep();

  // Delete all existing chests is exists
  await bkDeleteAllWallets();

  // Restore the test chest
  await bkRestoreChest();
  await waitFor("y'a pas de lézard");
}
