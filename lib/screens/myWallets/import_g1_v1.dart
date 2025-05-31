// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:durt2/durt2.dart' show IdtyStatus, WalletData;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/migrate_wallet_checks.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:provider/provider.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

class ImportG1v1 extends StatelessWidget {
  const ImportG1v1({super.key});
  static const int debouneTime = 600;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    Timer? debounce;
    WalletData selectedWallet = myWalletProvider.getDefaultWallet();

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        resetScreen();
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('importOldAccount'.tr()),
        body: SafeArea(
          child: Consumer<SubstrateSdk>(builder: (context, sub, _) {
            return FutureBuilder(
                future: sub.getBalanceAndIdtyStatus(sub.g1V1NewAddress, selectedWallet.address),
                builder: (BuildContext context, AsyncSnapshot<MigrateWalletChecks> status) {
                  if (status.data == null) {
                    return Column(children: [
                      ScaledSizedBox(height: 80),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ScaledSizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            color: context.colorScheme.primary,
                            strokeWidth: 4,
                          ),
                        ),
                      ]),
                    ]);
                  }

                  final statusData = status.data!;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(scaleSize(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Section des identifiants Cesium
                        Card(
                          color: context.colorScheme.surfaceContainer,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                    debounce = Timer(const Duration(milliseconds: debouneTime), () {
                                      if (sub.csSalt.text != '' && sub.csPassword.text != '') {
                                        sub.reload();
                                        sub.csToV2Address(sub.csSalt.text, sub.csPassword.text);
                                      }
                                    });
                                  },
                                  onFieldSubmitted: (text) {
                                    if (sub.csSalt.text != '' && sub.csPassword.text != '') {
                                      if (debounce?.isActive ?? false) {
                                        debounce!.cancel();
                                      }
                                      sub.reload();
                                      sub.csToV2Address(sub.csSalt.text, sub.csPassword.text);
                                    }
                                  },
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  controller: sub.csSalt,
                                  obscureText: !sub.isCesiumIDVisible,
                                  style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    hintText: 'enterCesiumId'.tr(),
                                    hintStyle: scaledTextStyle(fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    suffixIcon: IconButton(
                                      key: keyCesiumIdVisible,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      icon: Icon(
                                        sub.isCesiumIDVisible ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.black,
                                        size: scaleSize(18),
                                      ),
                                      onPressed: () {
                                        sub.cesiumIDisVisible();
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
                                    debounce = Timer(const Duration(milliseconds: debouneTime), () {
                                      sub.g1V1NewAddress = '';
                                      if (sub.csSalt.text != '' && sub.csPassword.text != '') {
                                        sub.reload();
                                        sub.csToV2Address(sub.csSalt.text, sub.csPassword.text);
                                      }
                                    });
                                  },
                                  onFieldSubmitted: (text) {
                                    if (sub.csSalt.text != '' && sub.csPassword.text != '') {
                                      if (debounce?.isActive ?? false) {
                                        debounce!.cancel();
                                      }
                                      sub.g1V1NewAddress = '';
                                      sub.reload();
                                      sub.csToV2Address(sub.csSalt.text, sub.csPassword.text);
                                    }
                                  },
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  controller: sub.csPassword,
                                  obscureText: !sub.isCesiumIDVisible,
                                  style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    hintText: 'enterCesiumPassword'.tr(),
                                    hintStyle: scaledTextStyle(fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      icon: Icon(
                                        sub.isCesiumIDVisible ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.black,
                                        size: scaleSize(18),
                                      ),
                                      onPressed: () {
                                        sub.cesiumIDisVisible();
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
                          visible: sub.g1V1OldPubkey != '' && sub.csSalt.text != '' && sub.csPassword.text != '',
                          child: Card(
                            elevation: 2,
                            color: context.colorScheme.surfaceContainer,
                            margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                                Clipboard.setData(ClipboardData(text: sub.g1V1OldPubkey));
                                                snackCopyKey(context);
                                              },
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'v1: ',
                                                    style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                                                  ),
                                                  Text(
                                                    getShortPubkey(sub.g1V1OldPubkey),
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
                                                Clipboard.setData(ClipboardData(text: sub.g1V1NewAddress));
                                                snackCopyKey(context);
                                              },
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'v2: ',
                                                    style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                                                  ),
                                                  Text(
                                                    getShortPubkey(sub.g1V1NewAddress),
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
                                            value: statusData.fromBalance['transferableBalance'],
                                            size: 14,
                                            fontWeight: FontWeight.w600,
                                            color: context.colorScheme.onSecondaryContainer,
                                          ),
                                          ScaledSizedBox(height: 4),
                                          Row(
                                            children: [
                                              IdentityStatus(
                                                address: sub.g1V1NewAddress,
                                                color: Colors.black,
                                              ),
                                              ScaledSizedBox(width: 4),
                                              Certifications(
                                                address: sub.g1V1NewAddress,
                                                size: 12,
                                              ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                      value: selectedWallet,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                      items: myWalletProvider.listWallets.map((wallet) {
                                        return DropdownMenuItem(
                                          key: keySelectThisWallet(wallet.address),
                                          value: wallet,
                                          child: Text(
                                            wallet.name!,
                                            style: scaledTextStyle(fontSize: 13),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (WalletData? newSelectedWallet) {
                                        selectedWallet = newSelectedWallet!;
                                        sub.reload();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bouton de validation et message de statut
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
                                ),
                                onPressed: statusData.canValidate
                                    ? () async {
                                        final addressToMigrate = sub.g1V1NewAddress;
                                        final hasIdentity = statusData.fromIdtyStatus != IdtyStatus.none;
                                        final message = hasIdentity
                                            ? 'migrationConfirmWithIdentity'.tr(args: [currencyName, getShortPubkey(selectedWallet.address)])
                                            : 'migrationConfirmBalanceOnly'.tr(args: [currencyName, getShortPubkey(selectedWallet.address)]);

                                        // Afficher le popup de confirmation
                                        bool? confirmed = await showConfirmationDialog(
                                          context: context,
                                          title: 'migrationConfirmTitle'.tr(),
                                          message: message,
                                          type: ConfirmationDialogType.info,
                                        );

                                        if (confirmed != true) return;

                                        WalletData? defaultWallet = myWalletProvider.getDefaultWallet();

                                        String? pin;
                                        if (myWalletProvider.pinCode == '') {
                                          pin = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (homeContext) {
                                                return UnlockingWallet(wallet: defaultWallet);
                                              },
                                            ),
                                          );
                                        }

                                        final transactionId = await sub.migrateCsToV2(
                                          sub.csSalt.text,
                                          sub.csPassword.text,
                                          selectedWallet.address,
                                          destPassword: pin ?? myWalletProvider.pinCode,
                                          fromBalance: statusData.fromBalance,
                                          fromIdtyStatus: statusData.fromIdtyStatus,
                                          toIdtyStatus: statusData.toIdtyStatus,
                                        );
                                        Navigator.pop(context);
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) {
                                            return TransactionInProgress(
                                                transactionId: transactionId,
                                                transType: hasIdentity ? 'identityMigration' : 'accountMigration',
                                                fromAddress: getShortPubkey(addressToMigrate),
                                                toAddress: getShortPubkey(selectedWallet.address));
                                          }),
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
                              statusData.validationStatus,
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                });
          }),
        ),
      ),
    );
  }

  void resetScreen() {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

    sub.csSalt.text = '';
    sub.csPassword.text = '';
    sub.g1V1NewAddress = '';
    sub.g1V1OldPubkey = '';
  }
}
