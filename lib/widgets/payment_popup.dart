// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/text_input_formaters.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

void paymentPopup(BuildContext context, String toAddress, String? username) {
  final walletViewProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
  final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

  double fees = 0;
  const double shapeSize = 16;
  var defaultWallet = myWalletProvider.getDefaultWallet();
  bool canValidate = false;
  final amountFocus = FocusNode();
  final commentFocus = FocusNode();

  void resetState() {
    walletViewProvider.payAmount.text = '';
    walletViewProvider.isCommentVisible = false;
    walletViewProvider.comment = '';
    walletViewProvider.payComment.text = '';
  }

  resetState();

  Future executeTransfert() async {
    Navigator.pop(context);
    if (!await myWalletProvider.askPinCode()) return;

    // Payment workflow !
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final acc = sub.getCurrentKeyPair();

    final transactionId = const Uuid().v4();

    sub.pay(
      fromAddress: acc.address!,
      destAddress: toAddress,
      amount: double.parse(walletViewProvider.payAmount.text),
      password: myWalletProvider.pinCode,
      transactionId: transactionId,
      comment: walletViewProvider.comment,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return ActivityScreen(
          address: acc.address!,
          transactionId: transactionId,
          comment: walletViewProvider.comment,
        );
      }),
    );
  }

  bool canValidatePayment() {
    // Vérification du montant saisi
    final payAmount = walletViewProvider.payAmount.text;
    if (payAmount.isEmpty) return false;

    // Récupération des soldes
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final defaultWalletBalance = walletOptions.balanceCache[defaultWallet.address] ?? 0;
    final toAddressBalance = walletOptions.balanceCache[toAddress] ?? 0;

    // Conversion du montant en unités de base
    final int payAmountValue = balanceRatio == 1 ? (double.parse(payAmount) * balanceRatio * 100).round() : (double.parse(payAmount) * balanceRatio).round();

    // TODO: récupérer la valeur réelle de l'existential deposit depuis le storage de Duniter
    const existentialDeposit = 200;

    // Vérifications de validité
    final bool isAmountValid = payAmountValue > 0;
    final bool isNotSendingToSelf = toAddress != defaultWallet.address;
    final bool hasEnoughBalance = payAmountValue <= defaultWalletBalance - existentialDeposit || defaultWalletBalance == payAmountValue;
    final bool respectsExistentialDeposit = toAddressBalance > 0 || payAmountValue >= existentialDeposit;

    return isAmountValid && isNotSendingToSelf && hasEnoughBalance && respectsExistentialDeposit;
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
      // Calcul de la hauteur à utiliser : on se base sur scaleSize(380)
      // Si l'écran est trop petit, on utilisera 90% de sa hauteur.
      final screenHeight = MediaQuery.of(context).size.height;
      final double desiredHeight = scaleSize(380);
      final double bottomSheetHeight = screenHeight < desiredHeight ? screenHeight * 0.9 : desiredHeight;

      final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          canValidate = canValidatePayment();
          final bool isUdUnit = configBox.get('isUdUnit') ?? false;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              // On fixe la hauteur maximale du bottom sheet
              height: bottomSheetHeight,
              decoration: ShapeDecoration(
                color: context.colorScheme.tertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(shapeSize),
                    topLeft: Radius.circular(shapeSize),
                  ),
                ),
              ),
              // Ce container contient un SingleChildScrollView pour autoriser le scroll
              // et un ConstrainedBox avec une contrainte minimale égale à la hauteur fixée.
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: bottomSheetHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: scaleSize(12),
                        bottom: scaleSize(16),
                        left: scaleSize(16),
                        right: scaleSize(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'executeATransfer'.tr(),
                                style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                key: keyPopButton,
                                iconSize: scaleSize(28),
                                icon: const Icon(Icons.cancel_outlined),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                          ScaledSizedBox(height: 4),
                          Text(
                            'from'.tr(args: ['']),
                            style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          ScaledSizedBox(height: 4),
                          Consumer<SubstrateSdk>(builder: (context, sub, _) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueAccent.shade200, width: 1.5),
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(0),
                              child: DropdownButton(
                                dropdownColor: context.colorScheme.tertiary,
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
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            NameByAddress(
                                              wallet: wallet,
                                              fontStyle: FontStyle.normal,
                                              size: 16,
                                            ),
                                            const Spacer(),
                                            Balance(address: wallet.address, size: 16),
                                          ],
                                        ),
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
                                      color: context.colorScheme.tertiary,
                                      width: scaleSize(isTall ? 315 : 310),
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          NameByAddress(
                                            wallet: wallet,
                                            fontStyle: FontStyle.normal,
                                            size: 16,
                                          ),
                                          const Spacer(),
                                          Balance(address: wallet.address, size: 16),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
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
                                style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                              if (fees > 0)
                                InkWell(
                                  onTap: () => infoFeesPopup(context),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outlined, color: context.colorScheme.primary, size: scaleSize(21)),
                                      ScaledSizedBox(width: 5),
                                      Text(
                                        'fees'.tr(args: [fees.toString(), currencyName]),
                                        style: scaledTextStyle(
                                          color: context.colorScheme.primary,
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
                              if (!commentFocus.hasFocus) {
                                setState(() {
                                  FocusScope.of(context).requestFocus(amountFocus);
                                });
                              }
                            },
                            child: TextField(
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () async {
                                if (walletViewProvider.isCommentVisible) {
                                  commentFocus.requestFocus();
                                } else if (canValidate) {
                                  await executeTransfert();
                                }
                              },
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
                                  defaultWallet.address,
                                  toAddress,
                                  double.parse(walletViewProvider.payAmount.text == '' ? '0' : walletViewProvider.payAmount.text),
                                );
                                setState(() {});
                              },
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.deny(',', replacementString: '.'),
                                FilteringTextInputFormatter.allow(RegExp(r'(^\d+\.?\d{0,2})')),
                              ],
                              decoration: InputDecoration(
                                hintText: '0.00',
                                suffix: Text(
                                  isUdUnit ? 'ud'.tr(args: ['']) : currencyName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[500]!, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.all(scaleSize(6)),
                              ),
                              style: scaledTextStyle(fontSize: 22, color: context.colorScheme.onSurface, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (walletViewProvider.isCommentVisible) const SizedBox(height: 8),
                          Consumer<WalletsProfilesProvider>(
                            builder: (context, provider, _) {
                              return AnimatedCrossFade(
                                duration: const Duration(milliseconds: 200),
                                crossFadeState: provider.isCommentVisible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                firstChild: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: scaleSize(4),
                                      vertical: scaleSize(2),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.add_comment_outlined,
                                    size: scaleSize(18),
                                    color: Colors.grey[600],
                                  ),
                                  label: Text(
                                    'addComment'.tr(),
                                    style: scaledTextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                  onPressed: () {
                                    provider.toggleCommentVisibility();
                                    Future.delayed(const Duration(milliseconds: 250), () {
                                      if (context.mounted) {
                                        amountFocus.unfocus();
                                        commentFocus.requestFocus();
                                      }
                                    });
                                  },
                                ),
                                secondChild: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: provider.payComment,
                                      focusNode: commentFocus,
                                      onChanged: (value) => provider.comment = value,
                                      inputFormatters: [
                                        Utf8LengthLimitingTextInputFormatter(146),
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onEditingComplete: () async {
                                        if (canValidate) await executeTransfert();
                                      },
                                      maxLines: 1,
                                      style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        hintText: 'optionalComment'.tr(),
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        filled: true,
                                        fillColor: Colors.white.withAlpha(128),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: scaleSize(8),
                                          vertical: scaleSize(4),
                                        ),
                                        counterText: '',
                                        suffixIcon: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            Icons.close,
                                            size: scaleSize(16),
                                            color: Colors.grey[600],
                                          ),
                                          onPressed: () {
                                            provider.comment = '';
                                            provider.toggleCommentVisibility();
                                            commentFocus.unfocus();
                                            amountFocus.requestFocus();
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey[400]!,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              key: keyConfirmPayment,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                elevation: 4,
                                backgroundColor: context.colorScheme.primary,
                              ),
                              onPressed: canValidate
                                  ? () async {
                                      await executeTransfert();
                                    }
                                  : null,
                              child: Text(
                                'executeTheTransfer'.tr(),
                                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> infoFeesPopup(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: context.colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outlined, color: context.colorScheme.primary, size: 40),
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
                padding: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blueAccent,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'moreInfo'.tr(),
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w300,
                    color: Colors.blueAccent,
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
                    style: scaledTextStyle(fontSize: 20, color: const Color(0xffD80000)),
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
