// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:provider/provider.dart';

class ImportG1v1 extends StatelessWidget {
  const ImportG1v1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    WalletOptionsProvider walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    MyWalletsProvider myWalletProvider =
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
                    sub.g1V1NewAddress, selectedWallet.address!),
                builder: (BuildContext context, AsyncSnapshot<List> status) {
                  // log.d(_certs.data);

                  final balance = status.data?[0] ?? 0;
                  final idtyStatus = status.data?[1];
                  final myIdtyStatus = status.data?[2];
                  final hasConsumer = status.data?[3] ?? false;

                  // log.d('hasconsumer: $hasConsumer');

                  if (balance != 0 && !hasConsumer) {
                    canValidate = true;
                    validationStatus = '';
                  } else {
                    canValidate = false;
                    validationStatus = hasConsumer
                        ? 'youMustWaitBeforeCashoutThisAccount'.tr(args: ['X'])
                        : 'thisAccountIsEmpty'.tr();
                  }

                  if (idtyStatus != 'noid' && myIdtyStatus != 'noid') {
                    canValidate = false;
                    validationStatus =
                        'youCannotMigrateIdentityToExistingIdentity'.tr();
                  }

                  if (sub.g1V1NewAddress == '') {
                    validationStatus = '';
                  }

                  log.d(
                      'tatatata: ${sub.g1V1NewAddress}, ${selectedWallet.address!}, $balance, $idtyStatus, $myIdtyStatus');

                  return Column(children: <Widget>[
                    const SizedBox(height: 20),
                    TextFormField(
                      autofocus: true,
                      onChanged: (text) {
                        if (debounce?.isActive ?? false) {
                          debounce!.cancel();
                        }
                        debounce = Timer(
                            const Duration(milliseconds: debouneTime), () {
                          sub.csToV2Address(
                              sub.csSalt.text, sub.csPassword.text);
                        });
                      },
                      keyboardType: TextInputType.text,
                      controller: sub.csSalt,
                      obscureText: sub
                          .isCesiumIDVisible, //This will obscure text dynamically
                      decoration: InputDecoration(
                        hintText: 'enterCesiumId'.tr(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            sub.isCesiumIDVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
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
                      autofocus: true,
                      onChanged: (text) {
                        if (debounce?.isActive ?? false) {
                          debounce!.cancel();
                        }
                        debounce = Timer(
                            const Duration(milliseconds: debouneTime), () {
                          sub.csToV2Address(
                              sub.csSalt.text, sub.csPassword.text);
                        });
                      },
                      keyboardType: TextInputType.text,
                      controller: sub.csPassword,
                      obscureText: sub
                          .isCesiumIDVisible, //This will obscure text dynamically
                      decoration: InputDecoration(
                        hintText: 'enterCesiumPassword'.tr(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            sub.isCesiumIDVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            sub.cesiumIDisVisible();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      sub.g1V1NewAddress,
                      style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Monospace'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$balance $currencyName',
                      style: const TextStyle(fontSize: 17),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        walletOptions.idtyStatus(context, sub.g1V1NewAddress,
                            isOwner: false, color: Colors.black),
                        const SizedBox(width: 10),
                        getCerts(context, sub.g1V1NewAddress, 14)
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text('selectDestWallet'.tr()),
                    const SizedBox(height: 5),
                    DropdownButtonHideUnderline(
                      child: DropdownButton(
                        // alignment: AlignmentDirectional.topStart,
                        value: selectedWallet,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: myWalletProvider.listWallets.map((wallet) {
                          return DropdownMenuItem(
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
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                          primary: orangeC, // background
                          onPrimary: Colors.white, // foreground
                        ),
                        onPressed: canValidate
                            ? () async {
                                log.d('GOOO');
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

                                sub.migrateCsToV2(
                                    sub.csSalt.text,
                                    sub.csPassword.text,
                                    selectedWallet.address!,
                                    destPassword: pin ?? myWalletProvider.pinCode,
                                    balance: balance,
                                    idtyStatus: idtyStatus);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return const TransactionInProgress();
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
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);

    sub.csSalt.text = '';
    sub.csPassword.text = '';
    sub.g1V1NewAddress = '';
  }
}
