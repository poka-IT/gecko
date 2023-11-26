// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:provider/provider.dart';

class MigrateIdentityScreen extends StatelessWidget {
  const MigrateIdentityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final _homeProvider = Provider.of<HomeProvider>(context);
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final fromAddress = walletOptions.address.text;
    final defaultWallet = myWalletProvider.getDefaultWallet();
    final walletsList = myWalletProvider.listWallets.toList();
    late WalletData selectedWallet;

    if (fromAddress == defaultWallet.address) {
      selectedWallet =
          walletsList[fromAddress == walletsList[0].address ? 1 : 0];
    } else {
      selectedWallet = defaultWallet;
    }
    bool canValidate = false;
    String validationStatus = '';

    final mdStyle = MarkdownStyleSheet(
      p: const TextStyle(fontSize: 18, color: Colors.black, letterSpacing: 0.3),
      textAlign: WrapAlignment.center,
    );

    if (walletsList.length < 2) {
      return const Column(
        children: [
          SizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Vous devez avoir au moins 2 portefeuilles\npour effecter cette opération',
                style: TextStyle(fontSize: 20),
              )
            ],
          )
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text('importOldAccount'.tr()),
          )),
      body: SafeArea(
        child: Consumer<SubstrateSdk>(builder: (context, sub, _) {
          return FutureBuilder(
              future: sub.getBalanceAndIdtyStatus(
                  fromAddress, selectedWallet.address),
              builder: (BuildContext context, AsyncSnapshot<List> status) {
                if (status.data == null) {
                  return const Column(children: [
                    SizedBox(height: 80),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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

                // log.d('statusData: ${status.data}');

                final Map balance = status.data?[0] ?? {};
                final IdtyStatus idtyStatus = status.data?[1];
                final IdtyStatus myIdtyStatus = status.data?[2];
                final bool hasConsumer = status.data?[3] ?? false;
                final bool isSmith = status.data?[4] ?? false;

                // log.d('hasconsumer: $hasConsumer');

                if (isSmith) {
                  canValidate = false;
                  validationStatus = 'smithCantMigrateIdentity'.tr();
                } else if (balance['transferableBalance'] != 0 &&
                    !hasConsumer) {
                  canValidate = true;
                  validationStatus = '';
                } else if (idtyStatus != IdtyStatus.none &&
                    myIdtyStatus != IdtyStatus.none) {
                  canValidate = false;
                  validationStatus =
                      'youCannotMigrateIdentityToExistingIdentity'.tr();
                } else {
                  canValidate = false;
                  validationStatus = hasConsumer
                      ? 'youMustWaitBeforeCashoutThisAccount'.tr(args: ['X'])
                      : 'thisAccountIsEmpty'.tr();
                }

                log.d(
                    'tatatata: ${sub.g1V1NewAddress}, ${selectedWallet.address}, $balance, $idtyStatus, $myIdtyStatus');

                final walletsList = myWalletProvider.listWallets.toList();

                walletsList
                    .removeWhere((element) => element.address == fromAddress);
                // walletsList.add(WalletData(address: 'custom', name: 'custom'));

                final bool isUdUnit = configBox.get('isUdUnit') ?? false;
                final unit = isUdUnit ? 'ud'.tr(args: ['']) : currencyName;

                return Column(children: <Widget>[
                  const Row(children: []),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: 350,
                    child: MarkdownBody(
                        data: 'areYouSureMigrateIdentity'.tr(args: [
                          duniterIndexer.walletNameIndexer[fromAddress] ??
                              '???',
                          '${balance['transferableBalance']} $unit'
                        ]),
                        styleSheet: mdStyle),
                  ),
                  // Text(
                  //   'areYouSureMigrateIdentity'.tr(args: [
                  //     duniterIndexer
                  //         .walletNameIndexer[fromAddress]!,
                  //     '$balance $currencyName'
                  //   ]),
                  //   textAlign: TextAlign.center,
                  // ),
                  const SizedBox(height: 20),
                  Text(
                    sub.g1V1NewAddress,
                    style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Monospace'),
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
                      items: walletsList.map((wallet) {
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

                              sub.migrateIdentity(
                                  fromAddress: fromAddress,
                                  destAddress: selectedWallet.address,
                                  fromPassword: pin ?? myWalletProvider.pinCode,
                                  destPassword: pin ?? myWalletProvider.pinCode,
                                  withBalance: true,
                                  fromBalance: balance);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return TransactionInProgress(
                                      transType: 'identityMigration',
                                      fromAddress: getShortPubkey(fromAddress),
                                      toAddress: getShortPubkey(
                                          selectedWallet.address));
                                }),
                              );
                            }
                          : null,
                      child: Text(
                        'migrateIdentity'.tr(),
                        style: TextStyle(
                            fontSize: 23 * ratio, fontWeight: FontWeight.w600),
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
    );
  }
}
