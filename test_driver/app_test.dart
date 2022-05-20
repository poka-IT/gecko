// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
// import 'package:flutter/services.dart';

void main() {
  int globalTimeout = 2;
  group('Gecko App', () {
    // First, define the Finders and use them to locate widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys in step 1.
    final manageWalletsFinder = find.byValueKey('manageWallets');
    // final buttonFinder = find.byValueKey('increment');

    FlutterDriver? driver;
    String? pinCode;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await driver!.waitUntilFirstFrameRasterized();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        driver!.close();
      }
    });

    // *** Global functions *** //

    // Function to tap the widget by key
    Future tapOn(String key) async {
      await driver!.tap(find.byValueKey(key));
    }

    // Easy get text
    Future<String> getText(String text) async {
      return await driver!.getText(find.byValueKey(
        text,
      ));
    }

    // Function to go back to previous screen
    Future goBack() async {
      await Process.run(
        'adb',
        <String>['shell', 'input', 'keyevent', 'KEYCODE_BACK'],
        runInShell: true,
      );
    }

    // Easy sleep
    Future sleep(int _time) async {
      await Future.delayed(Duration(milliseconds: _time));
    }

    // Test if widget exist on screen, return a boolean
    Future<bool> isPresent(SerializableFinder byValueKey,
        {Duration timeout = const Duration(seconds: 1)}) async {
      try {
        await driver!.waitFor(byValueKey, timeout: timeout);
        return true;
      } catch (exception) {
        return false;
      }
    }

    // Create a derivation
    Future createDerivation() async {
      await tapOn('addDerivation');
      await sleep(300);
    }

    // Delete a derivation
    Future deleteWallet(bool _confirm) async {
      await tapOn('deleteWallet');
      await sleep(100);
      _confirm ? await tapOn('confirmDeleting') : await tapOn('cancelDeleting');
      await sleep(300);
    }

    // Delete all wallets
    Future deleteAllWallets() async {
      await tapOn('drawerMenu');
      await sleep(300);
      await tapOn('parameters');
      await sleep(300);
      await tapOn('deleteAllWallets');
      await sleep(300);
      await tapOn('confirmDeletingAllWallets');
      await sleep(300);
    }

    // Fast creation of new Keychain
    Future<String?> createNewKeychain(String name) async {
      await tapOn('drawerMenu');
      await sleep(300);
      await tapOn('parameters');
      await sleep(300);
      await tapOn('generateKeychain');
      while (await getText('generatedPin') == '') {
        print('Waiting for pin code generation...');
        await sleep(100);
      }
      pinCode = await getText('generatedPin');
      await tapOn('storeKeychain');
      await sleep(100);
      await driver!.enterText('triche');
      await tapOn('walletName');
      await driver!.enterText(name);
      await sleep(50);
      await tapOn('confirmStorage');
      await sleep(300);
      return pinCode;
    }

    // *** Begin of tests *** //

    test('OnBoarding - Open wallets management', (
        {timeout = Timeout.none}) async {
      // await driver.runUnsynchronized(() async { // Needed if we want to manage async drivers
      await driver!.tap(manageWalletsFinder);

      // If a wallet exist, go to delete theme all
      if (!await isPresent(find.byValueKey('goStep1'))) {
        await goBack();

        await deleteAllWallets();

        await driver!.tap(manageWalletsFinder);
      }

      // Get the SerializableFinder for text widget with key 'textOnboarding'
      SerializableFinder textOnboarding = find.byValueKey(
        'textOnboarding',
      );

      await sleep(100);

      // Verify onboarding is starting, with text
      expect(await driver!.getText(textOnboarding),
          "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.");
    });

    test('OnBoarding - Go to create restore sentance', (
        {timeout = Timeout.none}) async {
      await tapOn('goStep1');
      await tapOn('goStep2');
      await tapOn('goStep3');
      await tapOn('goStep4');
      await tapOn('goStep5');
      await tapOn('goStep6');

      expect(
          await driver!.getText(find.byValueKey(
            'step6',
          )),
          "J’ai généré votre phrase de restauration !\nTâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.");
    });

    test('OnBoarding - Generate sentance and confirme it', (
        {timeout = Timeout.none}) async {
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
        await driver!.enterText(goodWord);

        // Check if word is valid
        await driver!.waitFor(find.text("C'est le bon mot !"));

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
        {timeout = Timeout.none}) async {
      expect(await getText('step9'),
          "Super !\n\nJe vais maintenant créer votre code secret. \n\nVotre code secret chiffre votre coffre de clefs, ce qui le rend inutilisable par d’autres, par exemple si vous perdez votre téléphone ou si on vous le vole.");
      await sleep(800);
      await tapOn('goStep10');
      await sleep(50);
      await tapOn('goStep11');

      while (await getText('generatedPin') == '') {
        print('Waiting for pin code generation...');
        await sleep(100);
      }

      // Change secret code 4 times
      for (int i = 0; i < 4; i++) {
        await tapOn('changeSecretCode');
      }

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
      await driver!.enterText(pinCode!);

      expect(await getText('step13'),
          "Top !\n\nVotre coffre et votre portefeuille ont été créés avec un immense succès.\n\nFélicitations !");
    });

    test('My wallets - Rename first derivation', (
        {timeout = const Duration(seconds: 2)}) async {
      await tapOn('goWalletHome');

      expect(await getText('myWallets'), "Coffre à Ğecko");
      await sleep(300);

      // Go to first derivation and rename it
      await driver!.tap(find.text('Mon portefeuille courant'));
      await sleep(300);
      await tapOn('renameWallet');
      await sleep(100);
      await tapOn('walletName');
      await sleep(100);
      await driver!.enterText('Renommage wallet 1');
      await sleep(300);
      await tapOn('renameWallet');
      await sleep(400);
      await driver!.waitFor(find.text('Renommage wallet 1'), timeout: timeout);
      // expect(await getText('walletName'), "Renommage wallet 1");
      await goBack();
    });

    test('My wallets - Create a derivations, open thems, tap all buttons', (
        {timeout = const Duration(seconds: 2)}) async {
      await driver!.waitFor(find.text('Renommage wallet 1'), timeout: timeout);
      // Add a second derivation
      await createDerivation();

      // Go to second derivation options
      await driver!.tap(find.text('Portefeuille 2'));
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
      await driver!.waitFor(find
          .text('Cette clé publique a été copié dans votre presse-papier.'));
      await goBack();

      // Add a third derivation
      await createDerivation();

      // Add a fourth derivation
      await createDerivation();
      await sleep(50);

      // Go to third derivation options
      await driver!.tap(find.text('Portefeuille 3'));
      await sleep(100);
      await tapOn('displayBalance');

      // Delete third derivation
      await deleteWallet(true);
    });

    test('My wallets - Extra tests', (
        {timeout = const Duration(seconds: 2)}) async {
      // Add derivation 5,6 and 7
      await driver!.waitFor(find.text('Portefeuille 4'), timeout: timeout);
      await createDerivation();
      await createDerivation();
      await createDerivation();

      // Go home and come back to my wallets view
      await goBack();
      await sleep(100);
      await tapOn('manageWallets');
      await sleep(200);
      //Enter secret code
      await driver!.enterText(pinCode!);
      await sleep(200);

      // Go to derivation 6 and delete it
      await driver!.tap(find.text('Portefeuille 6'));
      await sleep(100);
      await deleteWallet(true);

      // Go to 2nd derivation and check if it's de default
      await driver!.tap(find.text('Portefeuille 2'));
      await driver!.waitFor(find.text('Ce portefeuille est celui par defaut'));
      await tapOn('setDefaultWallet');
      await sleep(100);
      await driver!.waitFor(find.text('Ce portefeuille est celui par defaut'));
      await sleep(300);

      // Display history, copy pubkey, go back and rename wallet name
      await tapOn('displayHistory');
      await sleep(400);
      await tapOn('copyPubkey');
      await driver!.waitFor(find
          .text('Cette clé publique a été copié dans votre presse-papier.'));
      await sleep(800);
      await goBack();
      await sleep(300);
      await tapOn('renameWallet');
      await sleep(100);
      await tapOn('walletName');
      await sleep(100);
      await driver!.enterText('Renommage wallet 2');
      await sleep(300);
      await tapOn('renameWallet');
      await sleep(400);
      await goBack();
      await driver!.waitFor(find.text('Renommage wallet 2'));
      await driver!.scrollIntoView(find.text('+'));
      await createDerivation();
      await createDerivation();
      await driver!.scrollIntoView(find.text('+'));
      await createDerivation();
      await createDerivation();
      await driver!.scrollIntoView(find.text('+'));
      await createDerivation();
      await createDerivation();
      await driver!.scrollIntoView(find.text('+'));
      await createDerivation();
      await createDerivation();
      await driver!.scrollIntoView(find.text('+'));
      await createDerivation();
      await createDerivation();
      await driver!.scrollIntoView(find.text('+'));
      await createDerivation();
      await createDerivation();
      await driver!.scrollIntoView(find.text('+'));
      await createDerivation();
      await sleep(400);

      // Scroll the wallet screen until Derivation 20 and open it
      await driver!.scrollUntilVisible(
        find.byValueKey('listWallets'),
        find.text('Portefeuille 20'),
        dyScroll: -300.0,
      );

      await driver!.waitFor(find.text('Portefeuille 20'));
      await sleep(400);
      await driver!.tap(find.text('Portefeuille 20'));
      await tapOn('copyPubkey');
    });

    test('Search - Search Pi profile, navigate in history transactions', (
        {timeout = const Duration(seconds: 2)}) async {
      await driver!.waitFor(find.text('Portefeuille 20'), timeout: timeout);
      await goBack();
      await goBack();
      await sleep(200);
      await tapOn('searchIcon');
      await sleep(400);
      await driver!.enterText('D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU');
      await sleep(100);
      await tapOn('copyPubkey');
      await sleep(500);
      await tapOn('switchPayHistory');
      await sleep(1200);
      // await driver.scrollIntoView(find.byValueKey('listTransactions'));
      await driver!.scrollUntilVisible(
        find.byValueKey('listTransactions'),
        find.byValueKey('transaction35'),
        dyScroll: -600.0,
      );
      await sleep(100);
      await tapOn('transaction33');
      await driver!.waitFor(find.text('Commentaire:'));

      // Want to paste pubkey copied, but doesn't work actualy with flutter driver: https://github.com/flutter/flutter/issues/47448
      // final ClipboardData pubkeyCopied =
      //     await Clipboard.getData(Clipboard.kTextPlain);
      // await driver.enterText(pubkeyCopied.text);

      await sleep(300);
    }, timeout: Timeout(Duration(minutes: globalTimeout)));

    test('Wallet generation - Fast wallets generations', (
        {timeout = const Duration(seconds: 2)}) async {
      await driver!.waitFor(find.text('Commentaire:'), timeout: timeout);
      await goBack();
      await goBack();
      await deleteAllWallets();
      await sleep(100);
      final String? pincode = await (createNewKeychain('Fast wallet'));
      await sleep(200);
      await driver!.enterText(pincode!);
      await sleep(100);
      await createDerivation();
      await sleep(100);
      await driver!.tap(find.text('Fast wallet'));
      await driver!.waitFor(find.text('Fast wallet'));
      // Wait 3 seconds at the end
      await sleep(3000);
    });
  }, timeout: Timeout(Duration(minutes: globalTimeout)));
}
