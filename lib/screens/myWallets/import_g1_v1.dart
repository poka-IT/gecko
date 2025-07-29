// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:durt2/durt2.dart'
    show IdtyStatus, WalletEntity, MigrateWalletChecks, TransactionStatus, TransactionState, Durt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/g1v1_migration.provider.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart' show mapValidationErrors;
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

// Helper pour accéder aux services Riverpod depuis ce fichier
final _container = ProviderContainer();

class ImportG1v1 extends StatefulWidget {
  const ImportG1v1({super.key});
  static const int debouneTime = 600;

  @override
  State<ImportG1v1> createState() => _ImportG1v1State();
}

class _ImportG1v1State extends State<ImportG1v1> {
  Timer? debounce;
  bool _keyboardDismissed = false;
  WalletEntity? _selectedWallet;

  /// Effectue la migration G1v1 vers v2 avec affichage immédiat de l'écran de transaction
  Stream<TransactionStatus> _performG1v1Migration({
    required String salt,
    required String password,
    required String toAddress,
    required String pinCode,
  }) async* {
    try {
      // Émettre immédiatement un état pending pour afficher l'écran
      yield TransactionStatus(hash: '', state: TransactionState.pending);

      final toKeypair = await _container
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: toAddress, pinCode: pinCode);

      // Continuer avec la migration normale
      yield* _container
          .read(duniterServiceProvider)
          .migrateCsToV2(salt: salt, password: password, toKeypair: toKeypair, withBalance: true);
    } catch (e) {
      log.e('G1v1 migration error: $e');
      yield TransactionStatus(
        hash: '',
        state: TransactionState.error,
        errorMessage: 'migrationError'.tr(args: [e.toString()]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    // Initialize selected wallet only once or when explicitly changed
    _selectedWallet ??= myWalletProvider.getDefaultWallet();
    var selectedWallet = _selectedWallet!;

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        resetScreen();
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('importOldAccount'.tr()),
        body: SafeArea(
          child: old_provider.Consumer<G1v1MigrationProvider>(
            builder: (context, g1v1Migration, _) {
              return FutureBuilder(
                future: _container
                    .read(storageServiceProvider)
                    .getMigrateWalletChecks(
                      fromAddress: g1v1Migration.g1V1NewAddress,
                      toAddress: selectedWallet.address,
                    ),
                builder: (BuildContext context, AsyncSnapshot<MigrateWalletChecks> migrationChecks) {
                  if (migrationChecks.data == null) {
                    return Column(
                      children: [
                        ScaledSizedBox(height: 80),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaledSizedBox(
                              height: 35,
                              width: 35,
                              child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 4),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  final balance = migrationChecks.data?.fromBalance?.transferableBalance;
                  if (!_keyboardDismissed && balance != null && balance > BigInt.zero) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FocusScope.of(context).unfocus();
                    });
                    _keyboardDismissed = true;
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(scaleSize(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Card(
                          color: context.colorScheme.primary.withValues(alpha: 0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.colorScheme.primary, width: 1),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, color: context.colorScheme.primary, size: scaleSize(24)),
                                ScaledSizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'migrate_cesium_account_info'.tr(),
                                    style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ScaledSizedBox(height: 8),
                        // Section des identifiants Cesium
                        Card(
                          color: context.colorScheme.surfaceContainer,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'cesiumCredentials'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                ScaledSizedBox(height: 8),
                                TextFormField(
                                  key: keyCesiumId,
                                  autofocus: true,
                                  autocorrect: false,
                                  onChanged: (text) {
                                    if (debounce?.isActive ?? false) {
                                      debounce!.cancel();
                                    }
                                    debounce = Timer(const Duration(milliseconds: ImportG1v1.debouneTime), () {
                                      if (g1v1Migration.csSalt.text != '' && g1v1Migration.csPassword.text != '') {
                                        setState(() {
                                          _keyboardDismissed = false;
                                        });
                                        g1v1Migration.csToV2Address();
                                      }
                                    });
                                  },
                                  onFieldSubmitted: (text) {
                                    if (g1v1Migration.csSalt.text != '' && g1v1Migration.csPassword.text != '') {
                                      if (debounce?.isActive ?? false) {
                                        debounce!.cancel();
                                      }
                                      setState(() {
                                        _keyboardDismissed = false;
                                      });
                                      g1v1Migration.csToV2Address();
                                    }
                                  },
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  controller: g1v1Migration.csSalt,
                                  obscureText: !g1v1Migration.isCesiumIDVisible,
                                  style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    hintText: 'enterCesiumId'.tr(),
                                    hintStyle: scaledTextStyle(fontSize: 13),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    suffixIcon: IconButton(
                                      key: keyCesiumIdVisible,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      icon: Icon(
                                        g1v1Migration.isCesiumIDVisible ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.black,
                                        size: scaleSize(18),
                                      ),
                                      onPressed: () {
                                        g1v1Migration.cesiumIDisVisible();
                                      },
                                    ),
                                  ),
                                ),
                                ScaledSizedBox(height: 8),
                                TextFormField(
                                  key: keyCesiumPassword,
                                  autofocus: true,
                                  autocorrect: false,
                                  onChanged: (text) {
                                    if (debounce?.isActive ?? false) {
                                      debounce!.cancel();
                                    }
                                    debounce = Timer(const Duration(milliseconds: ImportG1v1.debouneTime), () {
                                      g1v1Migration.g1V1NewAddress = '';
                                      if (g1v1Migration.csSalt.text != '' && g1v1Migration.csPassword.text != '') {
                                        setState(() {
                                          _keyboardDismissed = false;
                                        });
                                        g1v1Migration.csToV2Address();
                                      }
                                    });
                                  },
                                  onFieldSubmitted: (text) {
                                    if (g1v1Migration.csSalt.text != '' && g1v1Migration.csPassword.text != '') {
                                      if (debounce?.isActive ?? false) {
                                        debounce!.cancel();
                                      }
                                      g1v1Migration.g1V1NewAddress = '';
                                      setState(() {
                                        _keyboardDismissed = false;
                                      });
                                      g1v1Migration.csToV2Address();
                                    }
                                  },
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  controller: g1v1Migration.csPassword,
                                  obscureText: !g1v1Migration.isCesiumPasswordVisible,
                                  style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    hintText: 'enterCesiumPassword'.tr(),
                                    hintStyle: scaledTextStyle(fontSize: 13),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      icon: Icon(
                                        g1v1Migration.isCesiumPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.black,
                                        size: scaleSize(18),
                                      ),
                                      onPressed: () {
                                        g1v1Migration.cesiumPasswordisVisible();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Section des informations du compte
                        Visibility(
                          visible:
                              g1v1Migration.g1V1OldPubkey != '' &&
                              g1v1Migration.csSalt.text != '' &&
                              g1v1Migration.csPassword.text != '',
                          child: Card(
                            elevation: 2,
                            color: context.colorScheme.surfaceContainer,
                            margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: EdgeInsets.all(scaleSize(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'accountInformation'.tr(),
                                    style: scaledTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                  ScaledSizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              key: keyCopyPubkey,
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: g1v1Migration.g1V1OldPubkey));
                                                snackCopyKey(context);
                                              },
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'v1: ',
                                                    style: scaledTextStyle(
                                                      fontSize: 13,
                                                      color: context.colorScheme.onSecondaryContainer,
                                                    ),
                                                  ),
                                                  Text(
                                                    getShortPubkey(g1v1Migration.g1V1OldPubkey),
                                                    style: scaledTextStyle(
                                                      fontSize: 13,
                                                      fontFamily: 'Monospace',
                                                      color: context.colorScheme.onSecondaryContainer,
                                                    ),
                                                  ),
                                                  ScaledSizedBox(width: 6),
                                                  Icon(Icons.copy, size: scaleSize(14), color: Colors.grey),
                                                ],
                                              ),
                                            ),
                                            ScaledSizedBox(height: 4),
                                            GestureDetector(
                                              key: keyCopyAddress,
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: g1v1Migration.g1V1NewAddress));
                                                snackCopyKey(context);
                                              },
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'v2: ',
                                                    style: scaledTextStyle(
                                                      fontSize: 13,
                                                      color: context.colorScheme.onSecondaryContainer,
                                                    ),
                                                  ),
                                                  Text(
                                                    getShortPubkey(g1v1Migration.g1V1NewAddress),
                                                    style: scaledTextStyle(
                                                      fontSize: 13,
                                                      fontFamily: 'Monospace',
                                                      color: context.colorScheme.onSecondaryContainer,
                                                    ),
                                                  ),
                                                  ScaledSizedBox(width: 6),
                                                  Icon(Icons.copy, size: scaleSize(14), color: Colors.grey),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          BalanceDisplay(
                                            value:
                                                migrationChecks.data?.fromBalance?.transferableBalance ?? BigInt.zero,
                                            size: 14,
                                            fontWeight: FontWeight.w600,
                                            color: context.colorScheme.onSecondaryContainer,
                                          ),
                                          ScaledSizedBox(height: 4),
                                          Row(
                                            children: [
                                              IdentityStatus(
                                                address: g1v1Migration.g1V1NewAddress,
                                                color: Colors.black,
                                              ),
                                              ScaledSizedBox(width: 4),
                                              Certifications(address: g1v1Migration.g1V1NewAddress, size: 12),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Section de sélection du portefeuille
                        Card(
                          color: context.colorScheme.surfaceContainer,
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: scaleSize(8)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'migrateToThisWallet'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                ScaledSizedBox(height: 8),
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: scaleSize(8)),
                                  child: DropdownButtonHideUnderline(
                                    key: keySelectWallet,
                                    child: DropdownButton(
                                      isExpanded: true,
                                      value: selectedWallet.address,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                      items: myWalletProvider.listWallets.map((wallet) {
                                        return DropdownMenuItem(
                                          key: keySelectThisWallet(wallet.address),
                                          value: wallet.address,
                                          child: Text(wallet.name!, style: scaledTextStyle(fontSize: 13)),
                                        );
                                      }).toList(),
                                      onChanged: (String? newSelectedWallet) {
                                        setState(() {
                                          _selectedWallet = myWalletProvider.getWalletDataByAddress(
                                            newSelectedWallet!,
                                          )!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bouton de validation et message de status
                        Column(
                          children: [
                            ScaledSizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                key: keyConfirm,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: context.colorScheme.primary,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
                                ),
                                onPressed: migrationChecks.data!.canMigrate
                                    ? () async {
                                        final addressToMigrate = g1v1Migration.g1V1NewAddress;
                                        final hasIdentity = migrationChecks.data!.fromIdtyStatus != IdtyStatus.none;
                                        final message = hasIdentity
                                            ? 'migrationConfirmWithIdentity'.tr(
                                                args: [Durt.i.network.symbol, getShortPubkey(selectedWallet.address)],
                                              )
                                            : 'migrationConfirmBalanceOnly'.tr(
                                                args: [Durt.i.network.symbol, getShortPubkey(selectedWallet.address)],
                                              );

                                        // Afficher le popup de confirmation
                                        bool? confirmed = await showConfirmationDialog(
                                          context: context,
                                          title: 'migrationConfirmTitle'.tr(),
                                          message: message,
                                          type: ConfirmationDialogType.info,
                                        );

                                        if (confirmed != true) return;

                                        if (!await myWalletProvider.askPinCode()) return;

                                        final transactionStream = _performG1v1Migration(
                                          salt: g1v1Migration.csSalt.text,
                                          password: g1v1Migration.csPassword.text,
                                          toAddress: selectedWallet.address,
                                          pinCode: myWalletProvider.pinCode,
                                        );

                                        Navigator.pop(context);
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return TransactionInProgressScreen(
                                                transactionStatus: transactionStream,
                                                transType: hasIdentity ? 'identityMigration' : 'accountMigration',
                                                fromAddress: getShortPubkey(addressToMigrate),
                                                toAddress: getShortPubkey(selectedWallet.address),
                                              );
                                            },
                                          ),
                                        );
                                        resetScreen();
                                      }
                                    : null,
                                child: Text(
                                  'migrateAccount'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            ScaledSizedBox(height: 6),
                            Text(
                              mapValidationErrors(migrationChecks.data!.errors),
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void resetScreen() {
    final g1v1Migration = old_provider.Provider.of<G1v1MigrationProvider>(homeContext, listen: false);

    g1v1Migration.csSalt.text = '';
    g1v1Migration.csPassword.text = '';
    g1v1Migration.g1V1NewAddress = '';
    g1v1Migration.g1V1OldPubkey = '';
  }
}
