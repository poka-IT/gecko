// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

void paymentPopup(BuildContext context, String toAddress, String? username) {
  final walletViewProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
  final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

  double fees = 0;
  const double shapeSize = 20;
  var defaultWallet = myWalletProvider.getDefaultWallet();
  bool canValidate = false;
  final amountFocus = FocusNode();

  walletViewProvider.payAmount.text = '';

  Future executeTransfert() async {
    if (!await myWalletProvider.askPinCode()) return;

    // Payment workflow !
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final acc = sub.getCurrentWallet();

    sub.pay(fromAddress: acc.address!, destAddress: toAddress, amount: double.parse(walletViewProvider.payAmount.text), password: myWalletProvider.pinCode);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return ActivityScreen(address: acc.address!);
      }),
    );
  }

  bool canValidatePayment() {
    final payAmount = walletViewProvider.payAmount.text;
    if (payAmount.isEmpty) {
      return false;
    }
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final defaultWalletBalance = walletOptions.balanceCache[defaultWallet.address] ?? 0;

    const existentialDeposit = 2;
    final double payAmountValue = double.parse(payAmount);
    final double toAddressBalance = walletOptions.balanceCache[toAddress] ?? 0;

    // Prevent sending more than the balance with existential deposit
    if (payAmountValue / balanceRatio > defaultWalletBalance - existentialDeposit) {
      return false;
    }

    // Prevent sending to self
    if (toAddress == defaultWallet.address) {
      return false;
    }

    // Prevent sending to an empty wallet with less than 2 (existential deposit)
    if (toAddressBalance == 0 && payAmountValue < existentialDeposit / balanceRatio) {
      return false;
    }

    return true;
  }

  myWalletProvider.readAllWallets().then((value) => myWalletProvider.listWallets.sort((a, b) => (a.derivation ?? -1).compareTo(b.derivation ?? -1)));

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

        return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          canValidate = canValidatePayment();
          final bool isUdUnit = configBox.get('isUdUnit') ?? false;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: scaleSize(400),
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
                padding: EdgeInsets.only(top: scaleSize(14), bottom: 0, left: scaleSize(16), right: scaleSize(16)),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      'executeATransfer'.tr(),
                      style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      key: keyPopButton,
                      iconSize: scaleSize(32),
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ]),
                  ScaledSizedBox(height: 5),
                  Text(
                    'from'.tr(args: ['']),
                    style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                  ScaledSizedBox(height: 5),
                  Consumer<SubstrateSdk>(builder: (context, sub, _) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent.shade200, width: 2),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(0),
                      child: DropdownButton(
                          dropdownColor: const Color(0xffffeed1),
                          elevation: 12,
                          key: keyDropdownWallets,
                          value: defaultWallet,
                          menuMaxHeight: scaleSize(270),
                          onTap: () {
                            FocusScope.of(context).requestFocus(amountFocus);
                          },
                          selectedItemBuilder: (_) {
                            return myWalletProvider.listWallets.map((WalletData wallet) {
                              return Container(
                                width: scaleSize(isTall ? 315 : 310),
                                padding: EdgeInsets.all(scaleSize(7)),
                                child: Visibility(
                                  visible: wallet.address == defaultWallet.address,
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    NameByAddress(
                                      wallet: wallet,
                                      fontStyle: FontStyle.normal,
                                      size: 18,
                                    ),
                                    const Spacer(),
                                    // const Text('data')
                                    Balance(address: wallet.address, size: 18),
                                  ]),
                                ),
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
                          items: myWalletProvider.listWallets.map((WalletData wallet) {
                            return DropdownMenuItem(
                              value: wallet,
                              key: keySelectThisWallet(wallet.address),
                              child: Container(
                                color: const Color(0xffffeed1),
                                width: scaleSize(isTall ? 315 : 310),
                                padding: const EdgeInsets.all(10),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  NameByAddress(
                                    wallet: wallet,
                                    fontStyle: FontStyle.normal,
                                    size: 18,
                                  ),
                                  const Spacer(),
                                  Balance(address: wallet.address, size: 18),
                                ]),
                              ),
                            );
                          }).toList()),
                    );
                  }),
                  ScaledSizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'to'.tr(args: ['']),
                        style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                      ),
                      ScaledSizedBox(width: 10),
                      Text(
                        username ?? getShortPubkey(toAddress),
                        style: scaledTextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ScaledSizedBox(height: 7),
                  Row(
                    children: [
                      Text(
                        'amount'.tr(),
                        style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => infoFeesPopup(context),
                        child: Row(
                          children: [
                            Icon(Icons.info_outlined, color: orangeC, size: scaleSize(21)),
                            ScaledSizedBox(width: 5),
                            Text(
                              'fees'.tr(args: [fees.toString(), currencyName]),
                              style: scaledTextStyle(
                                color: orangeC,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ScaledSizedBox(width: 10),
                    ],
                  ),
                  ScaledSizedBox(height: 10),
                  Focus(
                    onFocusChange: (focused) {
                      setState(() {
                        FocusScope.of(context).requestFocus(amountFocus);
                      });
                    },
                    child: TextField(
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () async => canValidate ? await executeTransfert() : null,
                      key: keyAmountField,
                      controller: walletViewProvider.payAmount,
                      autofocus: true,
                      focusNode: amountFocus,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      autocorrect: false,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) async {
                        fees = await sub.txFees(
                            defaultWallet.address, toAddress, double.parse(walletViewProvider.payAmount.text == '' ? '0' : walletViewProvider.payAmount.text));
                        setState(() {});
                      },
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.deny(',', replacementString: '.'),
                        FilteringTextInputFormatter.allow(RegExp(r'(^\d+\.?\d{0,2})')),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        suffix: Text(isUdUnit ? 'ud'.tr(args: ['']) : currencyName),
                        filled: true,
                        fillColor: Colors.transparent,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[500]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.all(scaleSize(9)),
                      ),
                      style: scaledTextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ScaledSizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      key: keyConfirmPayment,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        elevation: 4,
                        backgroundColor: orangeC,
                      ),
                      onPressed: canValidate
                          ? () async {
                              Navigator.pop(context);
                              await executeTransfert();
                            }
                          : null,
                      child: Text(
                        'executeTheTransfer'.tr(),
                        style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const Spacer(),
                ]),
              ),
            ),
          );
        });
      });
}
//).then((value) => walletViewProvider.payAmount.text = ''

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
            ScaledSizedBox(height: 20),
            Text(
              'feesExplanation'.tr(),
              textAlign: TextAlign.center,
              style: scaledTextStyle(fontSize: 19, fontWeight: FontWeight.w500),
            ),
            ScaledSizedBox(height: 30),
            Text(
              'feesExplanationDetails'.tr(),
              textAlign: TextAlign.center,
              style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w300),
            ),
            ScaledSizedBox(height: 5),
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
                  style: scaledTextStyle(
                    fontSize: 17,
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
                    style: scaledTextStyle(
                      fontSize: 20,
                      color: const Color(0xffD80000),
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
