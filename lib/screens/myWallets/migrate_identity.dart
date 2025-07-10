// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart'
    show MigrateWalletChecks, MigrateWalletValidationError, Durt, TransactionStatus, TransactionState, DurtKeyPair;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:pointycastle/api.dart' show InvalidCipherTextException;

import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/balance.dart';
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
  const MigrateIdentityScreen({super.key});

  @override
  ConsumerState<MigrateIdentityScreen> createState() => _MigrateIdentityScreenState();
}

class _MigrateIdentityScreenState extends ConsumerState<MigrateIdentityScreen> {
  // ✅ Controllers définis dans la classe State (persistent)
  late TextEditingController newMnemonicSentence;
  late TextEditingController newWalletAddress;

  // ✅ Variables d'état persistent entre les rebuilds
  var migrationChecks = const MigrateWalletChecks.defaultValues();
  var mnemonicIsValid = false;
  int? matchDerivationNbr;
  String matchInfo = '';
  DurtKeyPair? toKeypair;

  @override
  void initState() {
    super.initState();
    // Initialisation des controllers
    newMnemonicSentence = TextEditingController();
    newWalletAddress = TextEditingController();
  }

  @override
  void dispose() {
    // Libération des ressources
    newMnemonicSentence.dispose();
    newWalletAddress.dispose();
    super.dispose();
  }

  /// Effectue la migration d'identité avec gestion d'erreur
  Stream<TransactionStatus> _performMigration({
    required String fromAddress,
    required String pinCode,
    required DurtKeyPair toKeypair,
  }) async* {
    try {
      // Étape 1: Importer le nouveau wallet temporairement
      yield TransactionStatus(hash: '', state: TransactionState.pending);

      // Étape 2: Récupérer les keypairs
      final fromKeypair = await _container
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: fromAddress, pinCode: pinCode);

      // Étape 4: Lancer la transaction de migration
      yield* _container
          .read(duniterServiceProvider)
          .migrateIdentity(fromKeypair: fromKeypair, toKeypair: toKeypair, withBalance: true);
    } on InvalidCipherTextException catch (e) {
      log.e('Invalid cipher text: $e');
      yield TransactionStatus(hash: '', state: TransactionState.error, errorMessage: 'incorrectPinCode'.tr());
    } catch (e) {
      log.e('Migration error: $e');
      yield TransactionStatus(
        hash: '',
        state: TransactionState.error,
        errorMessage: 'migrationError'.tr(args: [e.toString()]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final generatedWalletsProvider = old_provider.Provider.of<GenerateWalletsProvider>(context, listen: false);

    final fromAddress = walletOptions.address.text;

    bool isSmall = !isTall;

    Future scanDerivations() async {
      if (!isAddress(newWalletAddress.text) ||
          !_container.read(walletServiceProvider).isMnemonicValid(newMnemonicSentence.text) ||
          !migrationChecks.canMigrate) {
        setState(() {
          mnemonicIsValid = false;
          matchInfo = '';
        });
        walletOptions.reload();
        return;
      }
      log.d('Scan derivations to find a match');

      //Scan root wallet
      final keypair = await _container
          .read(walletServiceProvider)
          .getKeyPairFromMnemonic(newMnemonicSentence.text, keyPairType: Durt.defaultKeyPairType);

      if (keypair.address == newWalletAddress.text) {
        setState(() {
          toKeypair = keypair;
          matchDerivationNbr = null;
          mnemonicIsValid = true;
        });
        walletOptions.reload();
        return;
      }

      //Scan derivations
      for (int derivationNbr in [for (var i = 0; i < generatedWalletsProvider.numberScan; i += 1) i]) {
        final keypair = await _container
            .read(walletServiceProvider)
            .getKeyPairFromMnemonic(
              newMnemonicSentence.text,
              derivation: derivationNbr,
              keyPairType: Durt.defaultKeyPairType,
            );

        if (keypair.address == newWalletAddress.text) {
          setState(() {
            toKeypair = keypair;
            matchDerivationNbr = derivationNbr;
            mnemonicIsValid = true;
            matchInfo = "youCanMigrateThisIdentity".tr();
          });
          break;
        } else {
          setState(() {
            mnemonicIsValid = false;
          });
        }
      }

      if (!mnemonicIsValid) {
        setState(() {
          matchInfo = "addressNotBelongToMnemonic".tr();
        });
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
                                // Use the Balance widget instead of accessing cache directly
                                Balance(
                                  address: fromAddress,
                                  size: isSmall ? 14 : 15,
                                  color: context.colorScheme.onSurface,
                                ),
                                Text(
                                  ' ?',
                                  style: scaledTextStyle(
                                    fontSize: isSmall ? 14 : 15,
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
                                  SizedBox(
                                    width: 280,
                                    child: Text(
                                      'enterYourNewMnemonic'.tr(),
                                      style: scaledTextStyle(
                                        fontSize: isSmall ? 13 : 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextField(
                              controller: newMnemonicSentence,
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
                                    'enterYourNewAddress'.tr(args: [Durt.i.network.symbol]),
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
                              controller: newWalletAddress,
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
                                  final checks = await _container
                                      .read(storageServiceProvider)
                                      .getMigrateWalletChecks(fromAddress: fromAddress, toAddress: newAddress);
                                  setState(() {
                                    migrationChecks = checks;
                                  });
                                  await scanDerivations();
                                } else {
                                  setState(() {
                                    migrationChecks = const MigrateWalletChecks.defaultValues();
                                    matchInfo = '';
                                  });
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
                              style: scaledTextStyle(fontSize: isSmall ? 12 : 13, color: Colors.grey[600]),
                            ),
                          if (matchInfo.isNotEmpty) ...[
                            if (validationStatus.isNotEmpty) ScaledSizedBox(height: isSmall ? 4 : 8),
                            Text(
                              matchInfo,
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(fontSize: isSmall ? 12 : 13, color: Colors.grey[600]),
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
                      onPressed: migrationChecks.canMigrate && mnemonicIsValid && toKeypair != null
                          ? () async {
                              try {
                                // Demander le code PIN d'abord
                                if (!await myWalletProvider.askPinCode()) return;

                                // ✅ Créer le stream UNE SEULE FOIS
                                final transactionStream = _performMigration(
                                  fromAddress: fromAddress,
                                  pinCode: myWalletProvider.pinCode,
                                  toKeypair: toKeypair!,
                                );

                                // ✅ Pusher l'écran de transaction avec le stream créé
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionInProgressScreen(transactionStatus: transactionStream),
                                  ),
                                );
                              } catch (e) {
                                log.e('Error during migration setup: $e');
                                // Gestion d'erreur si nécessaire
                              }
                            }
                          : null,
                      child: Text(
                        'migrateIdentity'.tr(),
                        style: scaledTextStyle(fontSize: isSmall ? 15 : 16, fontWeight: FontWeight.w600),
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
