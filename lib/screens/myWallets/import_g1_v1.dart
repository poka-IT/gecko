// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:provider/provider.dart';

class ImportG1v1 extends StatelessWidget {
  const ImportG1v1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    Timer? debounce;
    const int debouneTime = 600;
    WalletData selectedWallet = myWalletProvider.getDefaultWallet();
    bool canValidate = false;
    String validationStatus = '';

    return PopScope(
      onPopInvoked: (_) {
        resetScreen(context);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: GeckoAppBar('importOldAccount'.tr()),
        body: SafeArea(
          child: Consumer<SubstrateSdk>(builder: (context, sub, _) {
            return FutureBuilder(
                future: sub.getBalanceAndIdtyStatus(
                    sub.g1V1NewAddress, selectedWallet.address),
                builder: (BuildContext context, AsyncSnapshot<List> status) {
                  if (status.data == null) {
                    return Column(children: [
                      ScaledSizedBox(height: 80),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaledSizedBox(
                              height: 35,
                              width: 35,
                              child: const CircularProgressIndicator(
                                color: orangeC,
                                strokeWidth: 4,
                              ),
                            ),
                          ]),
                    ]);
                  }

                  final Map balance = status.data?[0] ?? {};
                  final IdtyStatus idtyStatus = status.data?[1];
                  final IdtyStatus myIdtyStatus = status.data?[2];
                  final bool hasConsumer = status.data?[3] ?? false;
                  final bool isSmith = status.data?[4] ?? false;

                  if (balance['transferableBalance'] != 0 && !hasConsumer) {
                    canValidate = true;
                    validationStatus = '';
                  } else {
                    canValidate = false;
                    validationStatus = hasConsumer
                        ? 'youMustWaitBeforeCashoutThisAccount'.tr()
                        : 'thisAccountIsEmpty'.tr();
                  }

                  if (idtyStatus != IdtyStatus.none &&
                      myIdtyStatus != IdtyStatus.none) {
                    canValidate = false;
                    validationStatus =
                        'youCannotMigrateIdentityToExistingIdentity'.tr();
                  }

                  if (isSmith) {
                    canValidate = false;
                    validationStatus = 'smithCantMigrateIdentity'.tr();
                  }

                  if (sub.g1V1NewAddress == '') {
                    validationStatus = '';
                  }

                  final bool isUdUnit = configBox.get('isUdUnit') ?? false;
                  final unit = isUdUnit ? 'ud'.tr(args: ['']) : currencyName;

                  return Column(children: <Widget>[
                    ScaledSizedBox(height: 10),
                    TextFormField(
                      key: keyCesiumId,
                      autofocus: true,
                      autocorrect: false,
                      onChanged: (text) {
                        if (debounce?.isActive ?? false) {
                          debounce!.cancel();
                        }
                        debounce = Timer(
                            const Duration(milliseconds: debouneTime), () {
                          if (sub.csSalt.text != '' &&
                              sub.csPassword.text != '') {
                            sub.reload();
                            sub.csToV2Address(
                                sub.csSalt.text, sub.csPassword.text);
                          }
                        });
                      },
                      keyboardType: TextInputType.text,
                      controller: sub.csSalt,
                      obscureText: !sub.isCesiumIDVisible,
                      style: scaledTextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'enterCesiumId'.tr(),
                        suffixIcon: IconButton(
                          key: keyCesiumIdVisible,
                          icon: Icon(
                            sub.isCesiumIDVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                            size: scaleSize(22),
                          ),
                          onPressed: () {
                            sub.cesiumIDisVisible();
                          },
                        ),
                      ),
                    ),
                    ScaledSizedBox(height: 7),
                    TextFormField(
                      key: keyCesiumPassword,
                      autofocus: true,
                      autocorrect: false,
                      onChanged: (text) {
                        if (debounce?.isActive ?? false) {
                          debounce!.cancel();
                        }
                        debounce = Timer(
                            const Duration(milliseconds: debouneTime), () {
                          sub.g1V1NewAddress = '';
                          if (sub.csSalt.text != '' &&
                              sub.csPassword.text != '') {
                            sub.reload();
                            sub.csToV2Address(
                                sub.csSalt.text, sub.csPassword.text);
                          }
                        });
                      },
                      keyboardType: TextInputType.text,
                      controller: sub.csPassword,
                      obscureText: !sub.isCesiumIDVisible,
                      style: scaledTextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'enterCesiumPassword'.tr(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            sub.isCesiumIDVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                            size: scaleSize(22),
                          ),
                          onPressed: () {
                            sub.cesiumIDisVisible();
                          },
                        ),
                      ),
                    ),
                    ScaledSizedBox(height: 20),
                    Visibility(
                      visible: sub.g1V1OldPubkey != '',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                key: keyCopyPubkey,
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: sub.g1V1OldPubkey));
                                  snackCopyKey(context);
                                },
                                child: Text(
                                  'v1: ${getShortPubkey(sub.g1V1OldPubkey)}',
                                  style: scaledTextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Monospace'),
                                ),
                              ),
                              ScaledSizedBox(height: 5),
                              GestureDetector(
                                key: keyCopyAddress,
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: sub.g1V1OldPubkey));
                                  snackCopyKey(context);
                                },
                                child: Text(
                                  'v2: ${getShortPubkey(sub.g1V1NewAddress)}',
                                  style: scaledTextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Monospace'),
                                ),
                              ),
                            ],
                          ),
                          ScaledSizedBox(width: 30),
                          Column(
                            children: [
                              Text(
                                '${balance['transferableBalance']} $unit',
                                style: scaledTextStyle(fontSize: 16),
                              ),
                              IdentityStatus(
                                  address: sub.g1V1NewAddress,
                                  isOwner: false,
                                  color: Colors.black),
                              ScaledSizedBox(width: 10),
                              Certifications(
                                  address: sub.g1V1NewAddress, size: 14)
                            ],
                          ),
                        ],
                      ),
                    ),
                    ScaledSizedBox(height: 20),
                    Text(
                      'migrateToThisWallet'.tr(),
                      style: scaledTextStyle(fontSize: 17),
                    ),
                    ScaledSizedBox(height: 5),
                    DropdownButtonHideUnderline(
                      key: keySelectWallet,
                      child: DropdownButton(
                        value: selectedWallet,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: myWalletProvider.listWallets.map((wallet) {
                          return DropdownMenuItem(
                            key: keySelectThisWallet(wallet.address),
                            value: wallet,
                            child: Text(
                              wallet.name!,
                              style: scaledTextStyle(fontSize: 17),
                            ),
                          );
                        }).toList(),
                        onChanged: (WalletData? newSelectedWallet) {
                          selectedWallet = newSelectedWallet!;
                          sub.reload();
                        },
                      ),
                    ),
                    ScaledSizedBox(height: 10),
                    ScaledSizedBox(
                      width: 320,
                      height: 50,
                      child: ElevatedButton(
                        key: keyConfirm,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          elevation: 4,
                          backgroundColor: orangeC,
                        ),
                        onPressed: canValidate
                            ? () async {
                                WalletData? defaultWallet =
                                    myWalletProvider.getDefaultWallet();

                                String? pin;
                                if (myWalletProvider.pinCode == '') {
                                  pin = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (homeContext) {
                                        return UnlockingWallet(
                                            wallet: defaultWallet);
                                      },
                                    ),
                                  );
                                }

                                sub.migrateCsToV2(sub.csSalt.text,
                                    sub.csPassword.text, selectedWallet.address,
                                    destPassword:
                                        pin ?? myWalletProvider.pinCode,
                                    balance: balance,
                                    idtyStatus: idtyStatus);
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return TransactionInProgress(
                                        transType: 'identityMigration',
                                        fromAddress:
                                            getShortPubkey(sub.g1V1NewAddress),
                                        toAddress: getShortPubkey(
                                            selectedWallet.address));
                                  }),
                                );
                                resetScreen(context);
                              }
                            : null,
                        child: Text(
                          'migrateAccount'.tr(),
                          style: scaledTextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    ScaledSizedBox(height: 10),
                    Text(
                      validationStatus,
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(
                          fontSize: 14, color: Colors.grey[600]),
                    )
                  ]);
                });
          }),
        ),
      ),
    );
  }

  void resetScreen(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    sub.csSalt.text = '';
    sub.csPassword.text = '';
    sub.g1V1NewAddress = '';
    sub.g1V1OldPubkey = '';
  }
}
