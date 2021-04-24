// Imports the Flutter Driver API.
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

    test('OnBoarding - Generate sentance', (
        {timeout: const Duration(seconds: 5)}) async {
      await driver.tap(find.byValueKey('goStep6'));

      expect(
          await driver.getText(find.byValueKey(
            'step7',
          )),
          "Munissez-vous d'un papier et d’un crayon\nafin de pouvoir noter votre phrase de restauration.");
    });
  });
}
