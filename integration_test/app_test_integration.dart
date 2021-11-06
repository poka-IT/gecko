import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:gecko/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  int globalTimeout = 2;
  group(
    'Gecko end-to-end tests',
    () {
      // First, define the Finders and use them to locate widgets from the
      // test suite. Note: the Strings provided to the `byValueKey` method must
      // be the same as the Strings we used for the Keys in step 1.
      // final manageWalletsFinder = find.byKey(Key('manageWallets'));
      // final buttonFinder = find.byValueKey('increment');

      // FlutterDriver driver;
      WidgetTester tester;
      String pinCode;

      // *** Global functions *** //

      // Easy get text
      Future<String> getText(String text) async {
        Text resultText = tester.firstWidget(find.byKey(Key(text)));
        // Text pinCodeText = generatedPinFinder.evaluate().single.widget as Text;

        return resultText.data;
      }

      // Function to tap the widget by key
      Future tapOn(String key) async {
        await tester.tap(find.byKey(Key(key)));
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
      Future<bool> isPresent(String text,
          {Duration timeout = const Duration(seconds: 1)}) async {
        try {
          expect(text, findsOneWidget);
          return true;
        } catch (exception) {
          return false;
        }
      }

      // Create a derivation
      Future createDerivation(String _name) async {
        await tapOn('addDerivation');
        await sleep(100);

        await tester.enterText(find.byKey(Key('DerivationNameKey')), _name);

        await tapOn('validDerivation');
        await sleep(300);
      }

      // Delete a derivation
      Future deleteWallet(bool _confirm) async {
        await tapOn('deleteWallet');
        await sleep(100);
        _confirm
            ? await tapOn('confirmDeleting')
            : await tapOn('cancelDeleting');
        await sleep(300);
      }

      // Delete all wallets
      Future deleteAllWallets() async {
        await tester.tap(find.byKey(Key('drawerMenu')));
        await sleep(300);
        await tester.tap(find.byKey(Key('parameters')));
        await sleep(300);
        await tester.tap(find.byKey(Key('deleteAllWallets')));
        await sleep(300);
        await tester.tap(find.byKey(Key('confirmDeletingAllWallets')));
        await sleep(300);
      }

      // Fast creation of new Keychain
      Future<String> createNewKeychain(String name) async {
        await tapOn('drawerMenu');
        await sleep(300);
        await tapOn('parameters');
        await sleep(300);
        await tapOn('generateKeychain');
        expect(find.text(''), findsOneWidget);

        pinCode = await getText('generatedPin');

        await tapOn('storeKeychain');
        await sleep(100);
        await tester.enterText(find.byKey(Key('askedWord')), 'triche');
        await tapOn('walletName');
        await tester.enterText(find.byKey(Key('walletName')), 'name');
        await tapOn('confirmStorage');
        await sleep(300);
        return pinCode;
      }

      // *** Begin of tests *** //

      testWidgets('OnBoarding - Open wallets management', (
        WidgetTester tester, {
        timeout: Timeout.none,
      }) async {
        app.main();
        await tester.pumpAndSettle();

        // expect("y'a pas de lézard !", findsOneWidget);
        await tester.tap(find.byKey(Key('manageWallets')));

        print(
            '####################################################################');

        // If a wallet exist, go to delete theme all
        await tester.pumpAndSettle();
        if (!await isPresent(
            "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.")) {
          await tester.pumpAndSettle();
          // await tester.pageBack();
          await goBack();

          await sleep(500);
          await deleteAllWallets();

          await sleep(300);
          await tester.tap(find.byKey(Key('manageWallets')));
        }

        await tester.pumpAndSettle();

        // Verify onboarding is starting, with text
        expect(
            "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.",
            findsOneWidget);
      });

      // test('OnBoarding - Go to create restore sentance', (
      //     {timeout: Timeout.none}) async {
      //   await tapOn('goStep1');
      //   await tapOn('goStep2');
      //   await tapOn('goStep3');
      //   await tapOn('goStep4');
      //   await tapOn('goStep5');
      //   await tapOn('goStep6');

      //   expect(
      //       "J’ai généré votre phrase de restauration !\nTâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.",
      //       findsOneWidget);
      // });

      // test('OnBoarding - Generate sentance and confirme it', (
      //     {timeout: Timeout.none}) async {
      //   await tapOn('goStep7');

      //   await tester.pumpAndSettle();

      //   Future selectWord() async {
      //     List words = [for (var i = 1; i <= 13; i += 1) i];

      //     for (var j = 1; j < 13; j++) {
      //       words[j] = await getText('word$j');
      //     }
      //     expect(await getText('step7'),
      //         "C'est le moment de noter votre phrase !");

      //     await tapOn('goStep8');
      //     await sleep(200);

      //     String goodWord = words[int.parse(
      //       await getText('askedWord'),
      //     )];

      //     // Enter the expected word
      //     await tester.enterText(find.byKey(Key('inputWord')), goodWord);

      //     // Check if word is valid
      //     expect(find.text("C'est le bon mot !"), findsOneWidget);

      //     // Continue onboarding workflow
      //     await tapOn('goStep9');
      //   }

      //   await selectWord();

      //   //Go back 2 times to mnemonic generation screen
      //   await goBack();
      //   await goBack();
      //   await sleep(100);

      //   // Generate 3 times mnemonic
      //   await tapOn('generateMnemonic');
      //   await tapOn('generateMnemonic');
      //   await tapOn('generateMnemonic');
      //   await sleep(500);

      //   await selectWord();
      // });
      // test('OnBoarding - Generate secret code and confirm it', (
      //     {timeout: Timeout.none}) async {
      //   expect(await getText('step9'),
      //       "Super !\n\nJe vais maintenant créer votre code secret. \n\nVotre code secret chiffre votre trousseau de clefs, ce qui le rend inutilisable par d’autres, par exemple si vous perdez votre téléphone ou si on vous le vole.");

      //   await tapOn('goStep10');
      //   await tapOn('goStep11');

      //   while (await getText('generatedPin') == '') {
      //     print('Waiting for pin code generation...');
      //     await sleep(100);
      //   }

      //   // Change secret code 4 times
      //   for (int i = 0; i < 4; i++) await tapOn('changeSecretCode');

      //   await sleep(500);
      //   pinCode = await getText('generatedPin');

      //   await tapOn('goStep12');
      //   await sleep(300);

      //   // //Enter bad secret code
      //   // await tester.enterText('abcde');
      //   // await tapOn('formKey');
      //   // await sleep(1500);
      //   // await tapOn('formKey2');

      //   //Enter good secret code
      //   await tester.enterText(find.byKey(Key('formKey2')), pinCode);

      //   expect(await getText('step13'),
      //       "Top !\n\nVotre trousseau de clef et votre portefeuille ont été créés avec un immense succès.\n\nFélicitations !");
      // });

      // test('My wallets - Rename first derivation', (
      //     {timeout: const Duration(seconds: 2)}) async {
      //   await tapOn('goWalletHome');

      //   expect(await getText('myWallets'), "Mes portefeuilles");
      //   await sleep(300);

      //   // Go to first derivation and rename it
      //   await tester.tap(find.text('Mon portefeuille courant'));
      //   await sleep(300);
      //   await tapOn('renameWallet');
      //   await sleep(100);
      //   await tapOn('walletName');
      //   await sleep(100);
      //   await tester.enterText(
      //       find.byKey(Key('walletName')), 'Renommage wallet 1');
      //   await sleep(300);
      //   await tapOn('renameWallet');
      //   await sleep(400);
      //   expect('Renommage wallet 1', findsOneWidget);
      //   await goBack();
      // });

      // test('My wallets - Create a derivations, open thems, tap all buttons', (
      //     {timeout: const Duration(seconds: 2)}) async {
      //   expect('Renommage wallet 1', findsOneWidget);

      //   // Add a second derivation
      //   await createDerivation('Derivation 2');

      //   // Go to second derivation options
      //   await tester.tap(find.text('Derivation 2'));
      //   await sleep(100);

      //   // Test options
      //   await tapOn('displayBalance');
      //   await tapOn('displayHistory');
      //   await sleep(300);
      //   await goBack();
      //   await tapOn('displayBalance');
      //   await sleep(100);
      //   await tapOn('displayBalance');
      //   await sleep(100);
      //   await tapOn('displayBalance');
      //   await tapOn('setDefaultWallet');
      //   await sleep(50);
      //   await tapOn('copyPubkey');
      //   expect('Cette clé publique a été copié dans votre presse-papier.',
      //       findsOneWidget);
      //   await goBack();

      //   // Add a third derivation
      //   await createDerivation('Derivation 3');

      //   // Add a fourth derivation
      //   await createDerivation('Derivation 4');
      //   await sleep(50);

      //   // Go to third derivation options
      //   await tester.tap(find.text('Derivation 3'));
      //   await sleep(100);
      //   await tapOn('displayBalance');

      //   // Delete third derivation
      //   await deleteWallet(true);
      // });

      // test('My wallets - Extra tests', (
      //     {timeout: const Duration(seconds: 2)}) async {
      //   // Add derivation 5,6 and 7
      //   expect('Derivation 4', findsOneWidget);
      //   await createDerivation('Derivation 5');
      //   await createDerivation('Derivation 6');
      //   await createDerivation('Derivation 7');

      //   // Go home and come back to my wallets view
      //   await goBack();
      //   await sleep(100);
      //   await tapOn('manageWallets');
      //   await sleep(200);
      //   //Enter secret code
      //   await tester.enterText(find.byKey(Key('formKey')), pinCode);
      //   await sleep(200);

      //   // Go to derivation 6 and delete it
      //   await tester.tap(find.text('Derivation 6'));
      //   await sleep(100);
      //   await deleteWallet(true);

      //   // Go to 2nd derivation and check if it's de default
      //   await tester.tap(find.text('Derivation 2'));
      //   expect('Ce portefeuille est celui par defaut', findsOneWidget);
      //   await tapOn('setDefaultWallet');
      //   await sleep(100);
      //   expect('Ce portefeuille est celui par defaut', findsOneWidget);
      //   await sleep(300);

      //   // Display history, copy pubkey, go back and rename wallet name
      //   await tapOn('displayHistory');
      //   await sleep(400);
      //   await tapOn('copyPubkey');
      //   expect('Cette clé publique a été copié dans votre presse-papier.',
      //       findsOneWidget);
      //   await sleep(800);
      //   await goBack();
      //   await sleep(300);
      //   await tapOn('renameWallet');
      //   await sleep(100);
      //   await tapOn('walletName');
      //   await sleep(100);
      //   await tester.enterText(
      //       find.byKey(Key('walletName')), 'Renommage wallet 2');
      //   await sleep(300);
      //   await tapOn('renameWallet');
      //   await sleep(400);
      //   await goBack();
      //   expect('Renommage wallet 2', findsOneWidget);
      //   await createDerivation('Derivation 8');
      //   await createDerivation('Derivation 9');
      //   await createDerivation('Derivation 10');
      //   await createDerivation('Derivation 11');
      //   await createDerivation('Derivation 12');
      //   await createDerivation('Derivation 13');
      //   await createDerivation('Derivation 14');
      //   await createDerivation('Derivation 15');
      //   await createDerivation('Derivation 16');
      //   await createDerivation('Derivation 17');
      //   await createDerivation('Derivation 18');
      //   await createDerivation('Derivation 19');
      //   await createDerivation('Derivation 20');
      //   await sleep(400);

      //   // Scroll the wallet screen until Derivation 20 and open it
      //   await tester.scrollUntilVisible(find.byKey(Key('listWallets')), -300.0);

      //   expect('Derivation 20', findsOneWidget);
      //   await sleep(400);
      //   await tester.tap(find.text('Derivation 20'));
      //   await tapOn('copyPubkey');
      // });

      // test('Search - Search Pi profile, navigate in history transactions', (
      //     {timeout: const Duration(seconds: 2)}) async {
      //   expect('Derivation 20', findsOneWidget);
      //   await goBack();
      //   await goBack();
      //   await sleep(200);
      //   await tapOn('searchIcon');
      //   await sleep(400);
      //   await tester.enterText(find.byKey(Key('searchInput')),
      //       'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU');
      //   await sleep(100);
      //   await tapOn('copyPubkey');
      //   await sleep(500);
      //   await tapOn('switchPayHistory');
      //   await sleep(1200);
      //   // await tester.scrollIntoView(find.byValueKey('listTransactions'));
      //   await tester.scrollUntilVisible(
      //     find.byKey(Key('listTransactions')),
      //     -600.0,
      //   );
      //   await sleep(100);
      //   await tapOn('transaction33');
      //   expect('Commentaire:', findsOneWidget);

      //   // Want to paste pubkey copied, but doesn't work actualy with flutter driver: https://github.com/flutter/flutter/issues/47448
      //   // final ClipboardData pubkeyCopied =
      //   //     await Clipboard.getData(Clipboard.kTextPlain);
      //   // await tester.enterText(pubkeyCopied.text);

      //   await sleep(300);
      // }, timeout: Timeout(Duration(minutes: globalTimeout)));

      // test('Wallet generation - Fast wallets generations', (
      //     {timeout: const Duration(seconds: 2)}) async {
      //   expect('Commentaire:', findsOneWidget);
      //   await goBack();
      //   await goBack();
      //   await deleteAllWallets();
      //   await sleep(100);
      //   final String pincode = await createNewKeychain('Fast wallet');
      //   await sleep(100);
      //   await tapOn('manageWallets');
      //   await sleep(200);
      //   await tester.enterText(find.byKey(Key('formKey')), pinCode);
      //   await sleep(100);
      //   await createDerivation('Derivation 2');
      //   await sleep(100);
      //   await tester.tap(find.text('Fast wallet'));
      //   expect('Fast wallet', findsOneWidget);
      //   // Wait 3 seconds at the end
      //   await sleep(3000);
      // });
    },
  );
}
