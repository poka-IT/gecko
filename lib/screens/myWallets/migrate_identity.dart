// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
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
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:provider/provider.dart';

class MigrateIdentityScreen extends StatelessWidget {
  const MigrateIdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final generatedWalletsProvider = Provider.of<GenerateWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    final fromAddress = walletOptions.address.text;
    final newMnemonicSentence = TextEditingController();
    final newWalletAddress = TextEditingController();

    var statusData = const MigrateWalletChecks.defaultValues();
    var mnemonicIsValid = false;
    int? matchDerivationNbr;
    String matchInfo = '';

    Future scanDerivations() async {
      if (!await isAddress(newWalletAddress.text) || !Durt.i.walletService.isMnemonicValid(newMnemonicSentence.text) || !statusData.canValidate) {
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
      for (int derivationNbr in [for (var i = 0; i < generatedWalletsProvider.numberScan; i += 1) i]) {
        final addressData = await sub.sdk.api.keyring.addressFromMnemonic(
          sub.currencyParameters['ss58']!,
          cryptoType: CryptoType.sr25519,
          mnemonic: newMnemonicSentence.text,
          derivePath: '//$derivationNbr',
        );

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
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('migrateIdentity'.tr()),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaledSizedBox(height: isSmallScreen ? 16 : 24),
                      // En-tête avec icône et texte explicatif
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: scaleSize(isSmallScreen ? 50 : 70),
                              height: scaleSize(isSmallScreen ? 50 : 70),
                              decoration: BoxDecoration(
                                color: context.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                size: scaleSize(isSmallScreen ? 25 : 35),
                                color: context.colorScheme.primary,
                              ),
                            ),
                            ScaledSizedBox(height: isSmallScreen ? 16 : 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                TextMarkDown(
                                  'areYouSureMigrateIdentity'.tr(args: [duniterIndexer.walletNameIndexer[fromAddress] ?? '???']),
                                  textAlign: WrapAlignment.center,
                                  style: scaledTextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    color: context.colorScheme.onSurface,
                                    height: 1.5,
                                  ),
                                ),
                                BalanceDisplay(
                                  value: walletOptions.balanceCache[fromAddress] ?? 0,
                                  size: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.colorScheme.onSurface,
                                ),
                                Text(' ?', style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 15, color: context.colorScheme.onSurface)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ScaledSizedBox(height: isSmallScreen ? 24 : 40),

                      // Champ de phrase de restauration
                      Text(
                        'migrateToThisWallet'.tr(),
                        style: scaledTextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      ScaledSizedBox(height: isSmallScreen ? 12 : 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: scaleSize(16),
                                right: scaleSize(16),
                                top: scaleSize(isSmallScreen ? 8 : 12),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/onBoarding/phrase_de_restauration_flou.png',
                                    width: scaleSize(isSmallScreen ? 16 : 20),
                                  ),
                                  ScaledSizedBox(width: isSmallScreen ? 8 : 12),
                                  Text(
                                    'enterYourNewMnemonic'.tr(),
                                    style: scaledTextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextField(
                              controller: newMnemonicSentence,
                              minLines: isSmallScreen ? 2 : 3,
                              maxLines: isSmallScreen ? 2 : 3,
                              style: scaledTextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                color: context.colorScheme.onSurface,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(scaleSize(isSmallScreen ? 12 : 16)),
                                border: InputBorder.none,
                                hintText: 'word1 word2 word3 word4 ...',
                                hintStyle: scaledTextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              onChanged: (newMnemonic) async {
                                await scanDerivations();
                              },
                            ),
                          ],
                        ),
                      ),
                      ScaledSizedBox(height: isSmallScreen ? 16 : 24),

                      // Champ d'adresse
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: scaleSize(16),
                                right: scaleSize(16),
                                top: scaleSize(isSmallScreen ? 8 : 12),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/walletOptions/key.png',
                                    width: scaleSize(isSmallScreen ? 16 : 20),
                                  ),
                                  ScaledSizedBox(width: isSmallScreen ? 8 : 12),
                                  Text(
                                    'enterYourNewAddress'.tr(args: [currencyName]),
                                    style: scaledTextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextField(
                              controller: newWalletAddress,
                              style: scaledTextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                color: context.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(scaleSize(isSmallScreen ? 12 : 16)),
                                border: InputBorder.none,
                                hintText: 'D....',
                                hintStyle: scaledTextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              onChanged: (newAddress) async {
                                if (await isAddress(newAddress)) {
                                  statusData = await sub.getBalanceAndIdtyStatus(
                                    fromAddress,
                                    newAddress,
                                  );
                                  await scanDerivations();
                                } else {
                                  statusData = const MigrateWalletChecks.defaultValues();
                                  matchInfo = '';
                                  walletOptions.reload();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Messages de statut et bouton de validation
            Container(
              padding: EdgeInsets.all(scaleSize(isSmallScreen ? 16 : 24)),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<WalletOptionsProvider>(
                    builder: (context, _, __) {
                      return Column(
                        children: [
                          if (statusData.validationStatus.isNotEmpty)
                            Text(
                              statusData.validationStatus,
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (matchInfo.isNotEmpty) ...[
                            if (statusData.validationStatus.isNotEmpty) ScaledSizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              matchInfo,
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          ScaledSizedBox(height: isSmallScreen ? 12 : 16),
                        ],
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: scaleSize(isSmallScreen ? 44 : 50),
                    child: ElevatedButton(
                      key: keyConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: statusData.canValidate && mnemonicIsValid
                          ? () async {
                              if (!await myWalletProvider.askPinCode()) return;

                              await sub.importAccount(
                                mnemonic: newMnemonicSentence.text,
                                derivePath: matchDerivationNbr == -1 ? '' : "//$matchDerivationNbr",
                                password: 'password',
                              );

                              final transactionId = await sub.migrateIdentity(
                                fromAddress: fromAddress,
                                destAddress: newWalletAddress.text,
                                fromPassword: myWalletProvider.pinCode,
                                destPassword: 'password',
                                withBalance: true,
                                fromBalance: statusData.fromBalance,
                              );

                              sub.deleteAccounts([newWalletAddress.text]);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionInProgress(
                                    transactionId: transactionId,
                                    transType: 'identityMigration',
                                    fromAddress: getShortPubkey(fromAddress),
                                    toAddress: getShortPubkey(newWalletAddress.text),
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        'migrateIdentity'.tr(),
                        style: scaledTextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
