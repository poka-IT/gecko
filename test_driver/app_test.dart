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
    String pinCode;

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
        await sleep(100);
      }

      Future selectWord() async {
        List words = [for (var i = 1; i <= 13; i += 1) i];

        for (var j = 1; j < 13; j++) {
          words[j] = await getText('word$j');
        }
        expect(
            await getText('step7'), "C'est le moment de noter votre phrase !");

        await tapOn('goStep8');
        await sleep(200);

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
      await sleep(100);

      // Generate 3 times mnemonic
      await tapOn('generateMnemonic');
      await tapOn('generateMnemonic');
      await tapOn('generateMnemonic');
      await sleep(500);

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
        await sleep(100);
      }

      // Change secret code 4 times
      for (int i = 0; i < 4; i++) await tapOn('changeSecretCode');

      await sleep(500);
      pinCode = await getText('generatedPin');

      await tapOn('goStep12');
      await sleep(300);

      // //Enter bad secret code
      // await driver.enterText('abcde');
      // await tapOn('formKey');
      // await sleep(1500);
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
      await sleep(300);

      // Create a derivation
      Future createDerivation(String _name) async {
        await tapOn('addDerivation');
        await sleep(100);

        await driver.enterText(_name);

        await tapOn('validDerivation');
        await sleep(300);
      }

      // Add a second derivation
      await createDerivation('Derivation 2');

      // Go to second derivation options
      await driver.tap(find.text('Derivation 2'));
      await sleep(100);

      // Test options
      await tapOn('displayBalance');
      await tapOn('displayHistory');
      await sleep(300);
      await goBack();
      await tapOn('displayBalance');
      await sleep(100);
      await tapOn('displayBalance');
      await sleep(100);
      await tapOn('displayBalance');
      await tapOn('setDefaultWallet');
      await sleep(50);
      await tapOn('copyPubkey');
      await driver.waitFor(find
          .text('Cette clé publique a été copié dans votre presse-papier.'));
      await goBack();

      // Add a third derivation
      await createDerivation('Derivation 3');

      // Add a fourth derivation
      await createDerivation('Derivation 4');
      await sleep(50);

      // Go to third derivation options
      await driver.tap(find.text('Derivation 3'));
      await sleep(100);
      await tapOn('displayBalance');

      // Delete a derivation
      Future deleteWallet(bool _confirm) async {
        await tapOn('deleteWallet');
        await sleep(100);
        _confirm
            ? await tapOn('confirmDeleting')
            : await tapOn('cancelDeleting');
        await sleep(300);
      }

      // Delete third derivation
      await deleteWallet(true);

      // Add derivation 5,6 and 7
      await createDerivation('Derivation 5');
      await createDerivation('Derivation 6');
      await createDerivation('Derivation 7');

      // Go home and come back to my wallets view
      await goBack();
      await sleep(100);
      await tapOn('manageWallets');
      await sleep(200);
      //Enter secret code
      await driver.enterText(pinCode);
      await sleep(200);

      // Go to derivation 6 and delete it
      await driver.tap(find.text('Derivation 6'));
      await sleep(100);
      await deleteWallet(true);

      // Go to 2nd derivation and check if it's de default
      await driver.tap(find.text('Derivation 2'));
      await driver.waitFor(find.text('Ce portefeuille est celui par defaut'));
      await tapOn('setDefaultWallet');
      await sleep(100);
      await driver.waitFor(find.text('Ce portefeuille est celui par defaut'));

      // Wait 3 seconds at the end
      await sleep(3000);
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

Future sleep(int _time) async {
  await Future.delayed(Duration(milliseconds: _time));
}
