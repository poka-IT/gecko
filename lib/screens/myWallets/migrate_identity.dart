// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
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
      p: scaledTextStyle(fontSize: 17, color: Colors.black, letterSpacing: 0.3),
      textAlign: WrapAlignment.center,
    );

    if (walletsList.length < 2) {
      return Column(
        children: [
          ScaledSizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Vous devez avoir au moins 2 portefeuilles\npour effecter cette opération',
                style: scaledTextStyle(fontSize: 17),
              )
            ],
          )
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('migrateIdentity'.tr()),
      body: SafeArea(
        child: Consumer<SubstrateSdk>(builder: (context, sub, _) {
          return FutureBuilder(
              future: sub.getBalanceAndIdtyStatus(
                  fromAddress, selectedWallet.address),
              builder: (BuildContext context, AsyncSnapshot<List> status) {
                if (status.data == null) {
                  return Column(children: [
                    ScaledSizedBox(height: 80),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ScaledSizedBox(
                        height: scaleSize(32),
                        width: scaleSize(32),
                        child: CircularProgressIndicator(
                          color: orangeC,
                          strokeWidth: scaleSize(4),
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

                final walletsList = myWalletProvider.listWallets.toList();

                walletsList
                    .removeWhere((element) => element.address == fromAddress);

                final bool isUdUnit = configBox.get('isUdUnit') ?? false;
                final unit = isUdUnit ? 'ud'.tr(args: ['']) : currencyName;

                return Column(children: <Widget>[
                  const Row(children: []),
                  ScaledSizedBox(height: 18),
                  ScaledSizedBox(
                    width: 320,
                    child: MarkdownBody(
                        data: 'areYouSureMigrateIdentity'.tr(args: [
                          duniterIndexer.walletNameIndexer[fromAddress] ??
                              '???',
                          '${balance['transferableBalance']} $unit'
                        ]),
                        styleSheet: mdStyle),
                  ),
                  ScaledSizedBox(height: 55),
                  Text('migrateToThisWallet'.tr(),
                      style: scaledTextStyle(fontSize: 17)),
                  ScaledSizedBox(height: 5),
                  DropdownButtonHideUnderline(
                    key: keySelectWallet,
                    child: DropdownButton(
                      value: selectedWallet,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: walletsList.map((wallet) {
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
                  const Spacer(flex: 2),
                  ScaledSizedBox(
                    width: 320,
                    height: 55,
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

                              if (myWalletProvider.pinCode == '') return;
                              final transactionId = await sub.migrateIdentity(
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
                                      transactionId: transactionId,
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
                        style: scaledTextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  ScaledSizedBox(height: 10),
                  Text(
                    validationStatus,
                    textAlign: TextAlign.center,
                    style:
                        scaledTextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                ]);
              });
        }),
      ),
    );
  }
}
