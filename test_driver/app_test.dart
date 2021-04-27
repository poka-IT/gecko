// Imports the Flutter Driver API.
import 'dart:async';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
// import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Gecko App', () {
    // First, define the Finders and use them to locate widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys in step 1.
    final manageWalletsFinder = find.byValueKey('manageWallets');
    // final buttonFinder = find.byValueKey('increment');

    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await driver.waitUntilFirstFrameRasterized();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    // Function to tap the widget by key
    Future tapOn(String key) async {
      await driver.tap(find.byValueKey(key));
    }

    Future<String> getText(String text) async {
      return await driver.getText(find.byValueKey(
        text,
      ));
    }

    test('OnBoarding - Open wallets management', (
        {timeout: const Duration(seconds: 2)}) async {
      // await driver.runUnsynchronized(() async { // Needed if we want to manage async drivers
      await driver.tap(manageWalletsFinder);

      // Get the SerializableFinder for text widget with key 'textOnboarding'
      SerializableFinder textOnboarding = find.byValueKey(
        'textOnboarding',
      );

      print(
          '####################################################################');

      // Verify onboarding is starting, with text
      expect(await driver.getText(textOnboarding),
          "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.");
    });

    test('OnBoarding - Go to create restore sentance', (
        {timeout: const Duration(seconds: 5)}) async {
      await tapOn('goStep1');
      await tapOn('goStep2');
      await tapOn('goStep3');
      await tapOn('goStep4');
      await tapOn('goStep5');
      await tapOn('goStep6');

      expect(
          await driver.getText(find.byValueKey(
            'step6',
          )),
          "J’ai généré votre phrase de restauration !\nTâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.");
    });

    test('OnBoarding - Generate sentance and confirme it', (
        {timeout: const Duration(seconds: 5)}) async {
      await tapOn('goStep7');

      while (await getText('word1') == '...') {
        print('Waiting for Mnemonic generation...');
        await Future.delayed(const Duration(milliseconds: 100));
      }

      Future selectWord() async {
        List words = [for (var i = 1; i <= 13; i += 1) i];

        for (var j = 1; j < 13; j++) {
          words[j] = await getText('word$j');
        }
        expect(
            await getText('step7'), "C'est le moment de noter votre phrase !");

        await tapOn('goStep8');
        await Future.delayed(const Duration(milliseconds: 50));

        String goodWord = words[int.parse(
          await getText('askedWord'),
        )];

        // Enter the expected word
        await driver.enterText(goodWord);

        // Check if word is valid
        await driver.waitFor(find.text("C'est le bon mot !"));

        // Continue onboarding workflow
        await tapOn('goStep9');
      }

      await selectWord();

      //Go back 2 times to mnemonic generation screen
      await goBack();
      await goBack();
      await Future.delayed(const Duration(milliseconds: 100));

      // Generate 3 times mnemonic
      await tapOn('generateMnemonic');
      await tapOn('generateMnemonic');
      await tapOn('generateMnemonic');
      await Future.delayed(const Duration(milliseconds: 500));

      await selectWord();
    });
    test('OnBoarding - Generate secret code and confirm it', (
        {timeout: const Duration(seconds: 5)}) async {
      expect(await getText('step9'),
          "Super !\n\nJe vais maintenant créer votre code secret. \n\nVotre code secret chiffre votre trousseau de clefs, ce qui le rend inutilisable par d’autres, par exemple si vous perdez votre téléphone ou si on vous le vole.");

      await tapOn('goStep10');
      await tapOn('goStep11');

      while (await getText('generatedPin') == '') {
        print('Waiting for pin code generation...');
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final pinCode = await getText('generatedPin');

      await tapOn('goStep12');
      await Future.delayed(const Duration(milliseconds: 300));

      // //Enter bad secret code
      // await driver.enterText('abcde');
      // await tapOn('formKey');
      // await Future.delayed(const Duration(milliseconds: 4000));
      // await tapOn('formKey2');

      //Enter good secret code
      await driver.enterText(pinCode);

      expect(await getText('step13'),
          "Top !\n\nVotre trousseau de clef et votre portefeuille ont été créés avec un immense succès.\n\nFélicitations !");
    });

    test('My wallets - Create a derivation and display it', (
        {timeout: const Duration(seconds: 5)}) async {
      await tapOn('goWalletHome');

      expect(await getText('myWallets'), "Mes portefeuilles");
      await Future.delayed(const Duration(milliseconds: 300));

      // Add a second derivation
      await tapOn('addDerivation');
      await Future.delayed(const Duration(milliseconds: 50));

      await driver.enterText('Derivation 2');

      await tapOn('validDerivation');
      await Future.delayed(const Duration(milliseconds: 300));

      await driver.tap(find.text('Derivation 2'));

      // Wait 3 seconds at the end
      await Future.delayed(const Duration(seconds: 3));
    });
  });
}

// Function to go back to previous screen
Future goBack() async {
  await Process.run(
    'adb',
    <String>['shell', 'input', 'keyevent', 'KEYCODE_BACK'],
    runInShell: true,
  );
}
