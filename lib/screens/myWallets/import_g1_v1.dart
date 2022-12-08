// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:provider/provider.dart';

class ImportG1v1 extends StatelessWidget {
  const ImportG1v1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    Timer? debounce;
    const int debouneTime = 300;
    WalletData selectedWallet = myWalletProvider.getDefaultWallet();
    bool canValidate = false;
    String validationStatus = '';

    return WillPopScope(
      onWillPop: () {
        resetScreen(context);
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  resetScreen(context);

                  Navigator.of(context).pop();
                }),
            title: SizedBox(
              height: 22,
              child: Text('importOldAccount'.tr()),
            )),
        body: SafeArea(
          child: Consumer<SubstrateSdk>(builder: (context, sub, _) {
            return FutureBuilder(
                future: sub.getBalanceAndIdtyStatus(
                    sub.g1V1NewAddress, selectedWallet.address),
                builder: (BuildContext context, AsyncSnapshot<List> status) {
                  // log.d(_certs.data);

                  if (status.data == null) {
                    return Column(children: [
                      const SizedBox(height: 80),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 35,
                              width: 35,
                              child: CircularProgressIndicator(
                                color: orangeC,
                                strokeWidth: 4,
                              ),
                            ),
                          ]),
                    ]);
                  }

                  final Map balance = status.data?[0] ?? {};
                  final String idtyStatus = status.data?[1];
                  final String myIdtyStatus = status.data?[2];
                  final bool hasConsumer = status.data?[3] ?? false;
                  final bool isSmith = status.data?[4] ?? false;

                  // log.d('hasconsumer: $hasConsumer');

                  if (balance['transferableBalance'] != 0 && !hasConsumer) {
                    canValidate = true;
                    validationStatus = '';
                  } else {
                    canValidate = false;
                    validationStatus = hasConsumer
                        ? 'youMustWaitBeforeCashoutThisAccount'.tr()
                        : 'thisAccountIsEmpty'.tr();
                  }

                  if (idtyStatus != 'noid' && myIdtyStatus != 'noid') {
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
                    const SizedBox(height: 20),
                    TextFormField(
                      key: keyCesiumId,
                      autofocus: true,
                      onChanged: (text) {
                        if (debounce?.isActive ?? false) {
                          debounce!.cancel();
                        }
                        debounce = Timer(
                            const Duration(milliseconds: debouneTime), () {
                          sub.reload();
                          sub.csToV2Address(
                              sub.csSalt.text, sub.csPassword.text);
                        });
                      },
                      keyboardType: TextInputType.text,
                      controller: sub.csSalt,
                      obscureText: !sub
                          .isCesiumIDVisible, //This will obscure text dynamically
                      decoration: InputDecoration(
                        hintText: 'enterCesiumId'.tr(),
                        suffixIcon: IconButton(
                          key: keyCesiumIdVisible,
                          icon: Icon(
                            sub.isCesiumIDVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            sub.cesiumIDisVisible();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: keyCesiumPassword,
                      autofocus: true,
                      onChanged: (text) {
                        if (debounce?.isActive ?? false) {
                          debounce!.cancel();
                        }
                        debounce = Timer(
                            const Duration(milliseconds: debouneTime), () {
                          sub.g1V1NewAddress = '';
                          sub.reload();
                          sub.csToV2Address(
                              sub.csSalt.text, sub.csPassword.text);
                        });
                      },
                      keyboardType: TextInputType.text,
                      controller: sub.csPassword,
                      obscureText: !sub
                          .isCesiumIDVisible, //This will obscure text dynamically
                      decoration: InputDecoration(
                        hintText: 'enterCesiumPassword'.tr(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            sub.isCesiumIDVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            sub.cesiumIDisVisible();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      key: keyCopyAddress,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: sub.g1V1OldPubkey));
                        snackCopyKey(context);
                      },
                      child: Text(
                        sub.g1V1OldPubkey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${balance['transferableBalance']} $unit',
                      style: const TextStyle(fontSize: 17),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IdentityStatus(
                            address: sub.g1V1NewAddress,
                            isOwner: false,
                            color: Colors.black),
                        const SizedBox(width: 10),
                        Certifications(address: sub.g1V1NewAddress, size: 14)
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text('selectDestWallet'.tr()),
                    const SizedBox(height: 5),
                    DropdownButtonHideUnderline(
                      key: keySelectWallet,
                      child: DropdownButton(
                        // alignment: AlignmentDirectional.topStart,
                        value: selectedWallet,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: myWalletProvider.listWallets.map((wallet) {
                          return DropdownMenuItem(
                            key: keySelectThisWallet(wallet.address),
                            value: wallet,
                            child: Text(
                              wallet.name!,
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        }).toList(),
                        onChanged: (WalletData? newSelectedWallet) {
                          selectedWallet = newSelectedWallet!;
                          sub.reload();
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 380 * ratio,
                      height: 60 * ratio,
                      child: ElevatedButton(
                        key: keyConfirm,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, elevation: 4,
                          backgroundColor: orangeC, // foreground
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
                                Navigator.push(
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
                          style: TextStyle(
                              fontSize: 23 * ratio,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      validationStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
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
  }
}
