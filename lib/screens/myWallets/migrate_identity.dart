// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show MigrateWalletChecks, MigrateWalletValidationError, Durt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';

import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart' as old_provider;

// Helper pour accéder aux services Riverpod depuis ce fichier
final _container = ProviderContainer();

String mapValidationErrors(Set<MigrateWalletValidationError> errors) {
  if (errors.isEmpty) {
    return '';
  }
  // Taking the first error to display. Can be modified to show all.
  return switch (errors.first) {
    MigrateWalletValidationError.isSmith => 'smithCantMigrateIdentity'.tr(),
    MigrateWalletValidationError.hasConsumers => 'youMustWaitBeforeCashoutThisAccount'.tr(),
    MigrateWalletValidationError.sourceAccountIsEmpty => 'thisAccountIsEmpty'.tr(),
    MigrateWalletValidationError.cannotMigrateIdentityToIdentity => 'youCannotMigrateIdentityToExistingIdentity'.tr(),
  };
}

class MigrateIdentityScreen extends ConsumerStatefulWidget {
  MigrateIdentityScreen({super.key});

  final newMnemonicSentence = TextEditingController();
  final newWalletAddress = TextEditingController();

  @override
  ConsumerState<MigrateIdentityScreen> createState() => _MigrateIdentityScreenState();
}

class _MigrateIdentityScreenState extends ConsumerState<MigrateIdentityScreen> {
  @override
  Widget build(BuildContext context) {
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final generatedWalletsProvider = old_provider.Provider.of<GenerateWalletsProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    final fromAddress = walletOptions.address.text;

    var migrationChecks = const MigrateWalletChecks.defaultValues();
    var mnemonicIsValid = false;
    int? matchDerivationNbr;
    String matchInfo = '';

    bool isSmall = !isTall;

    Future scanDerivations() async {
      if (!isAddress(widget.newWalletAddress.text) ||
          !_container.read(walletServiceProvider).isMnemonicValid(widget.newMnemonicSentence.text) ||
          !migrationChecks.canMigrate) {
        mnemonicIsValid = false;
        matchInfo = '';
        walletOptions.reload();
        return;
      }
      log.d('Scan derivations to find a match');

      //Scan root wallet
      final keypair = await _container
          .read(walletServiceProvider)
          .getKeyPairFromMnemonic(widget.newMnemonicSentence.text, derivation: 0, keyPairType: Durt.defaultKeyPairType);

      if (keypair.address == widget.newWalletAddress.text) {
        matchDerivationNbr = -1;
        mnemonicIsValid = true;
        walletOptions.reload();
        return;
      }

      //Scan derivations
      for (int derivationNbr in [for (var i = 0; i < generatedWalletsProvider.numberScan; i += 1) i]) {
        final keypair = await _container
            .read(walletServiceProvider)
            .getKeyPairFromMnemonic(
              widget.newMnemonicSentence.text,
              derivation: derivationNbr,
              keyPairType: Durt.defaultKeyPairType,
            );

        if (keypair.address == widget.newWalletAddress.text) {
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
                                  'areYouSureMigrateIdentity'.tr(
                                    args: [ref.read(squidServiceProvider).walletNameIndexer[fromAddress] ?? '???'],
                                  ),
                                  textAlign: WrapAlignment.center,
                                  style: scaledTextStyle(
                                    fontSize: isSmall ? 14 : 15,
                                    color: context.colorScheme.onSurface,
                                    height: 1.5,
                                  ),
                                ),
                                BalanceDisplay(
                                  value: walletOptions.balanceCache[fromAddress] ?? BigInt.zero,
                                  size: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.colorScheme.onSurface,
                                ),
                                Text(
                                  ' ?',
                                  style: scaledTextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
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
                                  Image.asset('assets/walletOptions/key.png', width: scaleSize(isSmall ? 16 : 20)),
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
                              style: scaledTextStyle(fontSize: isSmall ? 14 : 15, color: context.colorScheme.onSurface),
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
                                if (isAddress(newAddress)) {
                                  migrationChecks = await _container
                                      .read(storageServiceProvider)
                                      .getMigrateWalletChecks(fromAddress: fromAddress, toAddress: newAddress);
                                  await scanDerivations();
                                } else {
                                  migrationChecks = const MigrateWalletChecks.defaultValues();
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  old_provider.Consumer<WalletOptionsProvider>(
                    builder: (context, _, _) {
                      final validationStatus = mapValidationErrors(migrationChecks.errors);
                      return Column(
                        children: [
                          if (validationStatus.isNotEmpty)
                            Text(
                              validationStatus,
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey[600]),
                            ),
                          if (matchInfo.isNotEmpty) ...[
                            if (validationStatus.isNotEmpty) ScaledSizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              matchInfo,
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey[600]),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: migrationChecks.canMigrate && mnemonicIsValid
                          ? () async {
                              if (!await myWalletProvider.askPinCode()) return;

                              await _container
                                  .read(walletServiceProvider)
                                  .importAccount(
                                    mnemonic: widget.newMnemonicSentence.text,
                                    derivation: matchDerivationNbr == -1 ? null : matchDerivationNbr,
                                    pinCode: '1472',
                                  );

                              final fromKeypair = await _container
                                  .read(walletServiceProvider)
                                  .getKeyPairFromAddress(address: fromAddress, pinCode: myWalletProvider.pinCode);
                              final toKeypair = await _container
                                  .read(walletServiceProvider)
                                  .getKeyPairFromAddress(address: widget.newWalletAddress.text, pinCode: '1472');
                              final transactionStatus = _container
                                  .read(duniterServiceProvider)
                                  .migrateIdentity(fromKeypair: fromKeypair, toKeypair: toKeypair, withBalance: true);

                              await _container.read(walletServiceProvider).deleteWallet(widget.newWalletAddress.text);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionInProgressScreen(
                                    transactionStatus: transactionStatus,
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
                        style: scaledTextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.w600),
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
