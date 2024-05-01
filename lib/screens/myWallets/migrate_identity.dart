// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/migrate_wallet_checks.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:provider/provider.dart';

class MigrateIdentityScreen extends StatelessWidget {
  const MigrateIdentityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final generatedWalletsProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    final fromAddress = walletOptions.address.text;
    final newMnemonicSentence = TextEditingController();
    final newWalletAddress = TextEditingController();

    final mdStyle = MarkdownStyleSheet(
      p: scaledTextStyle(fontSize: 16, color: Colors.black, letterSpacing: 0.3),
      textAlign: WrapAlignment.center,
    );
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    final unit = isUdUnit ? 'ud'.tr(args: ['']) : currencyName;

    var statusData = const MigrateWalletChecks.defaultValues();
    var mnemonicIsValid = false;
    int? matchDerivationNbr;
    String matchInfo = '';

    Future scanDerivations() async {
      if (!await isAddress(newWalletAddress.text) ||
          !await sub.isMnemonicValid(newMnemonicSentence.text) ||
          !statusData.canValidate) {
        mnemonicIsValid = false;
        matchInfo = '';
        walletOptions.reload();
        return;
      }
      log.d('Scan derivations to find a match');

      //Scan root wallet
      final addressData = await sub.sdk.api.keyring.addressFromMnemonic(
        sub.currencyParameters['ss58']!,
        cryptoType: CryptoType.sr25519,
        mnemonic: newMnemonicSentence.text,
      );

      if (addressData.address == newWalletAddress.text) {
        matchDerivationNbr = -1;
        mnemonicIsValid = true;
        walletOptions.reload();
        return;
      }

      //Scan derivations
      for (int derivationNbr in [
        for (var i = 0; i < generatedWalletsProvider.numberScan; i += 1) i
      ]) {
        final addressData = await sub.sdk.api.keyring.addressFromMnemonic(
            sub.currencyParameters['ss58']!,
            cryptoType: CryptoType.sr25519,
            mnemonic: newMnemonicSentence.text,
            derivePath: '//$derivationNbr');

        if (addressData.address == newWalletAddress.text) {
          matchDerivationNbr = derivationNbr;
          mnemonicIsValid = true;
          matchInfo = "youCanMigrateThisIdentity".tr();
          break;
        } else {
          mnemonicIsValid = false;
        }
      }

      if (!mnemonicIsValid) {
        matchInfo = "addressNotBelongToMnemonic".tr();
      }
      walletOptions.reload();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('migrateIdentity'.tr()),
      body: SafeArea(
        child: Column(children: <Widget>[
          const Row(children: []),
          ScaledSizedBox(height: 18),
          ScaledSizedBox(
            width: 320,
            child: MarkdownBody(
                data: 'areYouSureMigrateIdentity'.tr(args: [
                  duniterIndexer.walletNameIndexer[fromAddress] ?? '???',
                  '${walletOptions.balanceCache[fromAddress]} $unit'
                ]),
                styleSheet: mdStyle),
          ),
          ScaledSizedBox(height: 55),
          Text('migrateToThisWallet'.tr(),
              style: scaledTextStyle(fontSize: 16)),
          ScaledSizedBox(height: 5),
          ScaledSizedBox(
            width: 320,
            child: TextField(
              controller: newMnemonicSentence,
              autofocus: true,
              minLines: 2,
              maxLines: 2,
              style: scaledTextStyle(fontSize: 14),
              decoration: InputDecoration(
                icon: Image.asset(
                  'assets/onBoarding/phrase_de_restauration_flou.png',
                  width: scaleSize(30),
                ),
                hintText: 'enterYourNewMnemonic'.tr(),
                hintStyle: scaledTextStyle(fontSize: 14),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: orangeC),
                ),
              ),
              onChanged: (newMnemonic) async {
                await scanDerivations();
              },
            ),
          ),
          ScaledSizedBox(height: 5),
          ScaledSizedBox(
            width: 320,
            child: TextField(
              controller: newWalletAddress,
              style: scaledTextStyle(fontSize: 14),
              decoration: InputDecoration(
                icon: Image.asset(
                  'assets/walletOptions/key.png',
                  height: scaleSize(30),
                ),
                hintText: 'enterYourNewAddress'.tr(args: [currencyName]),
                hintStyle: scaledTextStyle(fontSize: 14),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: orangeC),
                ),
              ),
              onChanged: (newAddress) async {
                if (await isAddress(newAddress)) {
                  statusData = await sub.getBalanceAndIdtyStatus(
                      fromAddress, newAddress);
                  await scanDerivations();
                } else {
                  statusData = const MigrateWalletChecks.defaultValues();
                  matchInfo = '';
                  walletOptions.reload();
                }
              },
            ),
          ),
          const Spacer(flex: 2),
          Consumer<WalletOptionsProvider>(builder: (context, _, __) {
            return ScaledSizedBox(
              width: 320,
              height: 55,
              child: ElevatedButton(
                key: keyConfirm,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  elevation: 4,
                  backgroundColor: orangeC,
                ),
                onPressed: statusData.canValidate && mnemonicIsValid
                    ? () async {
                        if (!await myWalletProvider.askPinCode()) return;

                        await sub.importAccount(
                            mnemonic: newMnemonicSentence.text,
                            derivePath: matchDerivationNbr == -1
                                ? ''
                                : "//$matchDerivationNbr",
                            password: 'password');

                        final transactionId = await sub.migrateIdentity(
                            fromAddress: fromAddress,
                            destAddress: newWalletAddress.text,
                            fromPassword: myWalletProvider.pinCode,
                            destPassword: 'password',
                            withBalance: true,
                            fromBalance: statusData.fromBalance);

                        sub.deleteAccounts([newWalletAddress.text]);
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return TransactionInProgress(
                                transactionId: transactionId,
                                transType: 'identityMigration',
                                fromAddress: getShortPubkey(fromAddress),
                                toAddress:
                                    getShortPubkey(newWalletAddress.text));
                          }),
                        );
                      }
                    : null,
                child: Text(
                  'migrateIdentity'.tr(),
                  style: scaledTextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            );
          }),
          Consumer<WalletOptionsProvider>(builder: (context, _, __) {
            return ScaledSizedBox(
              width: 320,
              child: Column(
                children: [
                  ScaledSizedBox(height: 10),
                  Text(
                    statusData.validationStatus,
                    textAlign: TextAlign.center,
                    style:
                        scaledTextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  ScaledSizedBox(height: 5),
                  Text(
                    matchInfo,
                    textAlign: TextAlign.center,
                    style:
                        scaledTextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
        ]),
      ),
    );
  }
}
