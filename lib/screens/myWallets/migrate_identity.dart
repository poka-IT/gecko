// ignore_for_file: use_build_context_synchronously

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

class MigrateIdentityScreen extends StatefulWidget {
  MigrateIdentityScreen({super.key});

  final newMnemonicSentence = TextEditingController();
  final newWalletAddress = TextEditingController();

  @override
  State<MigrateIdentityScreen> createState() => _MigrateIdentityScreenState();
}

class _MigrateIdentityScreenState extends State<MigrateIdentityScreen> {
  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final generatedWalletsProvider = Provider.of<GenerateWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    final fromAddress = walletOptions.address.text;

    var statusData = const MigrateWalletChecks.defaultValues();
    var mnemonicIsValid = false;
    int? matchDerivationNbr;
    String matchInfo = '';

    bool isSmall = !isTall;

    Future scanDerivations() async {
      if (!await isAddress(widget.newWalletAddress.text) || !await sub.isMnemonicValid(widget.newMnemonicSentence.text) || !statusData.canValidate) {
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
        mnemonic: widget.newMnemonicSentence.text,
      );

      if (addressData.address == widget.newWalletAddress.text) {
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
          mnemonic: widget.newMnemonicSentence.text,
          derivePath: '//$derivationNbr',
        );

        if (addressData.address == widget.newWalletAddress.text) {
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
                      ScaledSizedBox(height: isSmall ? 16 : 24),
                      // En-tête avec icône et texte explicatif
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: scaleSize(isSmall ? 50 : 70),
                              height: scaleSize(isSmall ? 50 : 70),
                              decoration: BoxDecoration(
                                color: context.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                size: scaleSize(isSmall ? 25 : 35),
                                color: context.colorScheme.primary,
                              ),
                            ),
                            ScaledSizedBox(height: isSmall ? 16 : 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                TextMarkDown(
                                  'areYouSureMigrateIdentity'.tr(args: [duniterIndexer.walletNameIndexer[fromAddress] ?? '???']),
                                  textAlign: WrapAlignment.center,
                                  style: scaledTextStyle(
                                    fontSize: isSmall ? 14 : 15,
                                    color: context.colorScheme.onSurface,
                                    height: 1.5,
                                  ),
                                ),
                                BalanceDisplay(
                                  value: walletOptions.balanceCache[fromAddress] ?? 0,
                                  size: isSmall ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.colorScheme.onSurface,
                                ),
                                Text(' ?', style: scaledTextStyle(fontSize: isSmall ? 14 : 15, color: context.colorScheme.onSurface)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ScaledSizedBox(height: isSmall ? 24 : 40),

                      // Champ de phrase de restauration
                      Text(
                        'migrateToThisWallet'.tr(),
                        style: scaledTextStyle(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      ScaledSizedBox(height: isSmall ? 12 : 16),
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
                                top: scaleSize(isSmall ? 8 : 12),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/onBoarding/phrase_de_restauration_flou.png',
                                    width: scaleSize(isSmall ? 16 : 20),
                                  ),
                                  ScaledSizedBox(width: isSmall ? 8 : 12),
                                  Text(
                                    'enterYourNewMnemonic'.tr(),
                                    style: scaledTextStyle(
                                      fontSize: isSmall ? 13 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextField(
                              controller: widget.newMnemonicSentence,
                              minLines: isSmall ? 2 : 3,
                              maxLines: isSmall ? 2 : 3,
                              style: scaledTextStyle(
                                fontSize: isSmall ? 14 : 15,
                                color: context.colorScheme.onSurface,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(scaleSize(isSmall ? 12 : 16)),
                                border: InputBorder.none,
                                hintText: 'word1 word2 word3 word4 ...',
                                hintStyle: scaledTextStyle(
                                  fontSize: isSmall ? 14 : 15,
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
                      ScaledSizedBox(height: isSmall ? 16 : 24),

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
                                top: scaleSize(isSmall ? 8 : 12),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/walletOptions/key.png',
                                    width: scaleSize(isSmall ? 16 : 20),
                                  ),
                                  ScaledSizedBox(width: isSmall ? 8 : 12),
                                  Text(
                                    'enterYourNewAddress'.tr(args: [currencyName]),
                                    style: scaledTextStyle(
                                      fontSize: isSmall ? 13 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextField(
                              controller: widget.newWalletAddress,
                              style: scaledTextStyle(
                                fontSize: isSmall ? 14 : 15,
                                color: context.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(scaleSize(isSmall ? 12 : 16)),
                                border: InputBorder.none,
                                hintText: 'G1....',
                                hintStyle: scaledTextStyle(
                                  fontSize: isSmall ? 14 : 15,
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Messages de statut et bouton de validation
            Container(
              padding: EdgeInsets.all(scaleSize(isSmall ? 16 : 24)),
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
                                fontSize: isSmall ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (matchInfo.isNotEmpty) ...[
                            if (statusData.validationStatus.isNotEmpty) ScaledSizedBox(height: isSmall ? 4 : 8),
                            Text(
                              matchInfo,
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(
                                fontSize: isSmall ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          ScaledSizedBox(height: isSmall ? 12 : 16),
                        ],
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: scaleSize(isSmall ? 44 : 50),
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
                                mnemonic: widget.newMnemonicSentence.text,
                                derivePath: matchDerivationNbr == -1 ? '' : "//$matchDerivationNbr",
                                password: 'password',
                              );

                              final transactionId = await sub.migrateIdentity(
                                fromAddress: fromAddress,
                                destAddress: widget.newWalletAddress.text,
                                fromPassword: myWalletProvider.pinCode,
                                destPassword: 'password',
                                withBalance: true,
                                fromBalance: statusData.fromBalance,
                              );

                              sub.deleteAccounts([widget.newWalletAddress.text]);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionInProgress(
                                    transactionId: transactionId,
                                    transType: 'identityMigration',
                                    fromAddress: getShortPubkey(fromAddress),
                                    toAddress: getShortPubkey(widget.newWalletAddress.text),
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        'migrateIdentity'.tr(),
                        style: scaledTextStyle(
                          fontSize: isSmall ? 15 : 16,
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
