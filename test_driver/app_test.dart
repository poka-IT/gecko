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

    test('Open wallets management - OnBoarding', () async {
      await driver.runUnsynchronized(() async {
        // First, tap the button manage wallets
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
    });
  });
}
