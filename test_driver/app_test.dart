// Imports the Flutter Driver API.
import 'package:flutter_driver/flutter_driver.dart';
// import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Counter App', () {
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

    test('Open wallets management', () async {
      await driver.runUnsynchronized(() async {
        // First, tap the button.
        await driver.tap(manageWalletsFinder);

        // tester.tap(find.widgetWithText(Button, 'Update'));
        //

        SerializableFinder textOnboarding = find.byValueKey(
          'textOnboarding',
        );

        print(
            '####################################################################');

        // Then, verify the counter text is incremented by 1.
        expect(await driver.getText(textOnboarding),
            "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.");
      });
    });
  });
}
