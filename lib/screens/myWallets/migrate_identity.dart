// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart'
    show
        MigrateWalletChecks,
        MigrateWalletValidationError,
        Durt,
        TransactionStatus,
        TransactionState,
        DurtKeyPair,
        WalletService,
        DuniterService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/services/mnemonic_service.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:pointycastle/api.dart' show InvalidCipherTextException;
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

String mapValidationErrors(Set<MigrateWalletValidationError> errors) {
  if (errors.isEmpty) {
    return '';
  }
  // Taking the first error to display. Can be modified to show all.
  return switch (errors.first) {
    MigrateWalletValidationError.sourceAccountIsEmpty => 'thisAccountIsEmpty'.tr(),
    MigrateWalletValidationError.cannotMigrateIdentityToIdentity => 'youCannotMigrateIdentityToExistingIdentity'.tr(),
  };
}

class MigrateIdentityScreen extends ConsumerStatefulWidget {
  const MigrateIdentityScreen({super.key, required this.address});

  final String address;

  @override
  ConsumerState<MigrateIdentityScreen> createState() => _MigrateIdentityScreenState();
}

class _MigrateIdentityScreenState extends ConsumerState<MigrateIdentityScreen> {
  late TextEditingController newMnemonicSentence;
  late TextEditingController newWalletAddress;

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

  /// Effectue la migration d'identité avec gestion d'erreur.
  /// Les services sont passés en paramètres car le stream peut être consommé après la disposal du widget.
  static Stream<TransactionStatus> _performMigration({
    required String fromAddress,
    required String pinCode,
    required DurtKeyPair toKeypair,
    required WalletService walletService,
    required DuniterService duniterService,
  }) async* {
    try {
      yield TransactionStatus(hash: '', state: TransactionState.pending);

      final fromKeypair = await walletService.getKeyPairFromAddress(address: fromAddress, pinCode: pinCode);

      yield* duniterService.migrateIdentity(fromKeypair: fromKeypair, toKeypair: toKeypair, withBalance: true);
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
    final fromAddress = widget.address;

    bool isSmall = !isTall;

    Future scanDerivations() async {
      if (!ref.read(utilsProvider).isAddressValid(newWalletAddress.text) || !migrationChecks.canMigrate) {
        setState(() {
          mnemonicIsValid = false;
          matchInfo = '';
        });

        return;
      }

      // Validate mnemonic with multilingual support
      final mnemonicResult = await MnemonicService.validateAndProcessMnemonic(newMnemonicSentence.text);
      if (mnemonicResult == null) {
        setState(() {
          mnemonicIsValid = false;
          matchInfo = '';
        });
        return;
      }

      final englishMnemonic = mnemonicResult.englishMnemonic;
      log.d('Scan derivations to find a match');

      //Scan root wallet
      final keypair = await ref
          .read(walletServiceProvider)
          .getKeyPairFromMnemonic(englishMnemonic, keyPairType: Durt.defaultKeyPairType);

      if (keypair.address == newWalletAddress.text) {
        setState(() {
          toKeypair = keypair;
          matchDerivationNbr = null;
          mnemonicIsValid = true;
        });

        return;
      }

      //Scan derivations
      for (int derivationNbr in [for (var i = 0; i < 30; i += 1) i]) {
        // Use default scan number
        final keypair = await ref
            .read(walletServiceProvider)
            .getKeyPairFromMnemonic(englishMnemonic, derivation: derivationNbr, keyPairType: Durt.defaultKeyPairType);

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
                          color: context.colorScheme.surfaceContainer,
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
                          color: context.colorScheme.surfaceContainer,
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
                                if (ref.read(utilsProvider).isAddressValid(newAddress)) {
                                  final checks = await ref
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
                color: context.colorScheme.surfaceContainer,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      if (mapValidationErrors(migrationChecks.errors).isNotEmpty)
                        Text(
                          mapValidationErrors(migrationChecks.errors),
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(fontSize: isSmall ? 12 : 13, color: Colors.grey[600]),
                        ),
                      if (matchInfo.isNotEmpty) ...[
                        if (mapValidationErrors(migrationChecks.errors).isNotEmpty)
                          ScaledSizedBox(height: isSmall ? 4 : 8),
                        Text(
                          matchInfo,
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(fontSize: isSmall ? 12 : 13, color: Colors.grey[600]),
                        ),
                      ],
                      ScaledSizedBox(height: isSmall ? 12 : 16),
                    ],
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
                                if (!await PinCodeService.askPinCode()) return;

                                // Capture services before navigation (ref won't be valid after pop)
                                final walletService = ref.read(walletServiceProvider);
                                final duniterService = ref.read(duniterServiceProvider);

                                final transactionStream = _performMigration(
                                  fromAddress: fromAddress,
                                  pinCode: PinCodeService.pinCode,
                                  toKeypair: toKeypair!,
                                  walletService: walletService,
                                  duniterService: duniterService,
                                );

                                // Convert to broadcast stream to allow multiple listeners
                                final broadcastStream = transactionStream.asBroadcastStream();

                                // Listen to transaction stream to invalidate providers on success
                                // Use mounted check to avoid using ref after widget disposal
                                broadcastStream.listen((status) {
                                  if ((status.state == TransactionState.finalized ||
                                          status.state == TransactionState.inBlock) &&
                                      mounted) {
                                    // Invalidate identity-related providers to refresh cache
                                    ref.invalidate(persistentIdtyStatusStreamProvider(widget.address));
                                    ref.invalidate(smartIdtyStatusStreamProvider(widget.address));
                                    // Also invalidate any other identity-related providers
                                    ref.invalidate(idtyStatusStreamProvider(widget.address));
                                  }
                                });

                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionInProgressScreen(
                                      transactionStatus: broadcastStream,
                                      transType: 'identityMigration',
                                      fromAddress: fromAddress,
                                      toAddress: toKeypair!.address,
                                    ),
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
