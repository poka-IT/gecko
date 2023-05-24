// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

void paymentPopup(BuildContext context, String toAddress, String username) {
  final walletViewProvider =
      Provider.of<WalletsProfilesProvider>(context, listen: false);
  final myWalletProvider =
      Provider.of<MyWalletsProvider>(context, listen: false);

  double fees = 0;
  const double shapeSize = 20;
  var defaultWallet = myWalletProvider.getDefaultWallet();
  bool canValidate = false;
  final amountFocus = FocusNode();
  final dropdownKey = GlobalKey();

  Future executeTransfert() async {
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
    log.d(pin);
    if (pin != null || myWalletProvider.pinCode != '') {
      // Payment workflow !
      final sub = Provider.of<SubstrateSdk>(context, listen: false);
      final acc = sub.getCurrentWallet();
      log.d(
          "fromAddress: ${acc.address!},destAddress: $toAddress, amount: ${double.parse(walletViewProvider.payAmount.text)},  password: $pin");
      sub.pay(
          fromAddress: acc.address!,
          destAddress: toAddress,
          amount: double.parse(walletViewProvider.payAmount.text),
          password: pin ?? myWalletProvider.pinCode);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return const TransactionInProgress();
        }),
      );
    }
  }

  myWalletProvider.readAllWallets();
  log.d(myWalletProvider.listWallets);

  showModalBottomSheet<void>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(shapeSize),
          topLeft: Radius.circular(shapeSize),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
        final walletOptions =
            Provider.of<WalletOptionsProvider>(context, listen: false);

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          if (walletViewProvider.payAmount.text != '' &&
              (double.parse(walletViewProvider.payAmount.text) +
                      2 / balanceRatio) <=
                  (walletOptions.balanceCache[defaultWallet.address] ?? 0) &&
              toAddress != defaultWallet.address) {
            if ((walletOptions.balanceCache[toAddress] == 0 ||
                    walletOptions.balanceCache[toAddress] == null) &&
                double.parse(walletViewProvider.payAmount.text) <
                    5 / balanceRatio) {
              canValidate = false;
            } else {
              canValidate = true;
            }
          } else {
            canValidate = false;
          }
          final bool isUdUnit = configBox.get('isUdUnit') ?? false;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: 420,
              decoration: const ShapeDecoration(
                color: Color(0xffffeed1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(shapeSize),
                    topLeft: Radius.circular(shapeSize),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 24, bottom: 0, left: 24, right: 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'executeATransfer'.tr(),
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              iconSize: 40,
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ]),
                      const SizedBox(height: 20),
                      Text(
                        'from'.tr(),
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Consumer<SubstrateSdk>(builder: (context, sub, _) {
                        return DropdownButton(
                          dropdownColor: const Color(0xffffeed1),
                          elevation: 12,
                          key: dropdownKey,
                          value: defaultWallet,
                          // onTap: () async {
                          //   await Future.delayed(const Duration(milliseconds: 10));
                          //   amountFocus.requestFocus();
                          // },
                          selectedItemBuilder: (_) {
                            return myWalletProvider.listWallets
                                .map((WalletData wallet) {
                              return Container(
                                width: 408,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.blueAccent.shade200,
                                      width: 2),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10.0)),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Row(children: [
                                  Text(g1WalletsBox
                                          .get(wallet.address)
                                          ?.username ??
                                      wallet.name!),
                                  const Spacer(),
                                  Balance(address: wallet.address, size: 20),
                                ]),
                              );
                            }).toList();
                          },
                          onChanged: (WalletData? newSelectedWallet) async {
                            defaultWallet = newSelectedWallet!;
                            await sub.setCurrentWallet(newSelectedWallet);
                            sub.reload();
                            amountFocus.requestFocus();
                            setState(() {});
                          },
                          items: myWalletProvider.listWallets
                              .map((WalletData wallet) {
                            return DropdownMenuItem(
                              value: wallet,
                              child: Container(
                                color: const Color(0xffffeed1),
                                width: 408,
                                height: 80,
                                padding: const EdgeInsets.all(10),
                                child: Row(children: [
                                  Text(g1WalletsBox
                                          .get(wallet.address)
                                          ?.username ??
                                      wallet.name!),
                                  const Spacer(),
                                  Balance(address: wallet.address, size: 20),
                                ]),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'to'.tr(),
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                username == ''
                                    ? getShortPubkey(toAddress)
                                    : username,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'amount'.tr(),
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => infoFeesPopup(context),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outlined, color: orangeC),
                                const SizedBox(width: 5),
                                Text(
                                  'fees'.tr(
                                      args: [fees.toString(), currencyName]),
                                  style: const TextStyle(
                                    color: orangeC,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () async =>
                            canValidate ? await executeTransfert() : null,
                        key: keyAmountField,
                        controller: walletViewProvider.payAmount,
                        autofocus: true,
                        focusNode: amountFocus,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) async {
                          fees = await sub.txFees(
                              defaultWallet.address,
                              toAddress,
                              double.parse(
                                  walletViewProvider.payAmount.text == ''
                                      ? '0'
                                      : walletViewProvider.payAmount.text));
                          log.d(fees);
                          setState(() {});
                        },
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.deny(',',
                              replacementString: '.'),
                          FilteringTextInputFormatter.allow(
                              RegExp(r'(^\d+\.?\d{0,2})')),
                        ],
                        decoration: InputDecoration(
                          hintText: '0.00',
                          suffix: Text(isUdUnit
                              ? 'ud'.tr(args: [''])
                              : currencyName), // udUnitDisplay(40),
                          filled: true,
                          fillColor: Colors.transparent,
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[500]!, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        style: const TextStyle(
                          fontSize: 35,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          key: keyConfirmPayment,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, elevation: 4,
                            backgroundColor: orangeC, // foreground
                          ),
                          onPressed: canValidate
                              ? () async => await executeTransfert()
                              : null,
                          child: Text(
                            'executeTheTransfer'.tr(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ]),
              ),
            ),
          );
        });
      }).then((value) => walletViewProvider.payAmount.text = '');
}

Future<void> infoFeesPopup(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outlined, color: orangeC, size: 40),
            const SizedBox(height: 20),
            Text(
              'feesExplanation'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            Text(
              'feesExplanationDetails'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 5),
            InkWell(
              onTap: () async => await _launchUrl('https://duniter.org'),
              child: Container(
                padding: const EdgeInsets.only(
                  bottom: 2,
                ),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                  color: Colors.blueAccent,
                  width: 1,
                ))),
                child: Text(
                  'moreInfo'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.blueAccent,
                    // decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: keyInfoPopup,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'gotit'.tr(),
                    style: const TextStyle(
                      fontSize: 21,
                      color: Color(0xffD80000),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          )
        ],
      );
    },
  );
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
