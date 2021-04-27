// Imports the Flutter Driver API.
import 'dart:async';

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
      await driver.tap(find.byValueKey('goStep1'));
      await driver.tap(find.byValueKey('goStep2'));
      await driver.tap(find.byValueKey('goStep3'));
      await driver.tap(find.byValueKey('goStep4'));
      await driver.tap(find.byValueKey('goStep5'));
      await driver.tap(find.byValueKey('goStep6'));

      expect(
          await driver.getText(find.byValueKey(
            'step6',
          )),
          "J’ai généré votre phrase de restauration !\nTâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.");
    });

    test('OnBoarding - Generate sentance and confirme it', (
        {timeout: const Duration(seconds: 5)}) async {
      await driver.tap(find.byValueKey('goStep7'));

      print('THE SECOND WORD IS:');

      while (await driver.getText(find.byValueKey(
            'word1',
          )) ==
          '...') {
        print('Waiting for Mnemonic generation...');
        await Future.delayed(const Duration(seconds: 1));
      }

      List words = [for (var i = 1; i <= 13; i += 1) i];

      for (var j = 1; j < 13; j++) {
        words[j] = await driver.getText(find.byValueKey(
          'word$j',
        ));
      }

      // print word 1, 2 and 12
      // print(words[1] + words[2] + words[12]);

      expect(
          await driver.getText(find.byValueKey(
            'step7',
          )),
          "C'est le moment de noter votre phrase !");

      await driver.tap(find.byValueKey('goStep8'));

      final String goodWord = words[int.parse(
        await driver.getText(
          find.byValueKey(
            'askedWord',
          ),
        ),
      )];

      await driver.enterText(goodWord);

      await driver.tap(find.byValueKey('goStep9'));
    });
    test('OnBoarding - Generate secret code and confirm it', (
        {timeout: const Duration(seconds: 5)}) async {
      expect(
          await driver.getText(find.byValueKey(
            'step9',
          )),
          "Super !\n\nJe vais maintenant créer votre code secret. \n\nVotre code secret chiffre votre trousseau de clefs, ce qui le rend inutilisable par d’autres, par exemple si vous perdez votre téléphone ou si on vous le vole.");

      await driver.tap(find.byValueKey('goStep10'));
      await driver.tap(find.byValueKey('goStep11'));

      while (await driver.getText(find.byValueKey(
            'generatedPin',
          )) ==
          '') {
        print('Waiting for pin code generation...');
        await Future.delayed(const Duration(seconds: 1));
      }

      final pinCode = await driver.getText(
        find.byValueKey(
          'generatedPin',
        ),
      );

      await driver.tap(find.byValueKey('goStep12'));
      await Future.delayed(const Duration(seconds: 1));

      await driver.enterText(pinCode);

      expect(
          await driver.getText(find.byValueKey(
            'step13',
          )),
          "Top !\n\nVotre trousseau de clef et votre portefeuille ont été créés avec un immense succès.\n\nFélicitations !");
    });

    test('OnBoarding - Create a derivation and display it', (
        {timeout: const Duration(seconds: 5)}) async {
      await driver.tap(find.byValueKey('goWalletHome'));

      expect(
          await driver.getText(find.byValueKey(
            'myWallets',
          )),
          "Mes portefeuilles");
    });
  });
}
