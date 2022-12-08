// ignore_for_file: file_names
// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/11_congratulations.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OnboardingStepTen extends StatelessWidget {
  OnboardingStepTen({Key? validationKey, this.scanDerivation = false})
      : super(key: validationKey);

  final bool scanDerivation;
  final formKey = GlobalKey<FormState>();
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;
  TextEditingController enterPin = TextEditingController();
  FocusNode pinFocus = FocusNode(debugLabel: 'pinFocusNode');

  @override
  Widget build(BuildContext context) {
    final generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    final walletOptions = Provider.of<WalletOptionsProvider>(context);
    final sub = Provider.of<SubstrateSdk>(context);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    CommonElements common = CommonElements();
    final pinLenght = generateWalletProvider.pin.text.length;

    return WillPopScope(
      onWillPop: () {
        myWalletProvider.isPinValid = false;
        myWalletProvider.isPinLoading = true;
        return Future<bool>.value(true);
      },
      child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: SizedBox(
              height: 22,
              child: Text(
                'myPassword'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  myWalletProvider.isPinValid = false;
                  myWalletProvider.isPinLoading = true;
                  Navigator.of(context).pop();
                }),
          ),
          extendBodyBehindAppBar: true,
          body: SafeArea(
            child: Stack(children: [
              Column(children: <Widget>[
                SizedBox(height: isTall ? 40 : 20),
                common.buildProgressBar(9),
                SizedBox(height: isTall ? 40 : 20),
                common.buildText("geckoWillCheckPassword".tr()),
                SizedBox(height: isTall ? 60 : 10),
                Visibility(
                  visible: generateWalletProvider.scanedValidWalletNumber != -1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("derivationsScanProgress".tr(args: [
                          '${generateWalletProvider.scanedWalletNumber}',
                          '${generateWalletProvider.numberScan + 1}'
                        ])),
                        const SizedBox(width: 10),
                        const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: orangeC,
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Consumer<MyWalletsProvider>(builder: (context, mw, _) {
                  return Visibility(
                    visible: !myWalletProvider.isPinValid &&
                        !myWalletProvider.isPinLoading,
                    child: Text(
                      "Ce n'est pas le bon code".tr(),
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  );
                }),
                SizedBox(height: isTall ? 20 : 10),
                Consumer<SubstrateSdk>(builder: (context, sub, _) {
                  return sub.nodeConnected
                      ? pinForm(context, walletOptions, pinLenght, 1, 2)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                              Text(
                                'Vous devez vous connecter à internet\npour valider votre coffre',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ]);
                }),
                Consumer<WalletOptionsProvider>(
                    builder: (context, walletOptions, _) {
                  return sub.nodeConnected
                      ? InkWell(
                          key: keyCachePassword,
                          onTap: () {
                            walletOptions.changePinCacheChoice();
                          },
                          child: Row(children: [
                            const SizedBox(height: 30),
                            const Spacer(),
                            Icon(
                              configBox.get('isCacheChecked') ?? false
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: orangeC,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'rememberPassword'.tr(),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                            ),
                            const Spacer()
                          ]))
                      : const Text('');
                }),
                const SizedBox(height: 10),
              ]),
              CommonElements().offlineInfo(context),
            ]),
          )),
    );
  }

  Widget pinForm(
      context, final walletOptions, pinLenght, int walletNbr, int derivation) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    final currentChest = myWalletProvider.getCurrentChest();

    return Form(
      key: formKey,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30),
          child: PinCodeTextField(
            key: keyPinForm,
            textCapitalization: TextCapitalization.characters,
            // autoDisposeControllers: false,
            focusNode: pinFocus,
            autoFocus: true,
            appContext: context,
            pastedTextStyle: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
            length: pinLenght,
            obscureText: true,
            obscuringCharacter: '*',
            animationType: AnimationType.slide,
            animationDuration: const Duration(milliseconds: 40),
            validator: (v) {
              if (v!.length < pinLenght) {
                return "yourPasswordLengthIsX".tr(args: [pinLenght.toString()]);
              } else {
                return null;
              }
            },
            pinTheme: PinTheme(
              activeColor: pinColor,
              borderWidth: 4,
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(5),
              fieldHeight: 50 * ratio,
              fieldWidth: 50,
              activeFillColor: Colors.black,
            ),
            showCursor: kDebugMode ? false : true,
            cursorColor: Colors.black,
            textStyle: const TextStyle(fontSize: 27, height: 1.6),
            backgroundColor: const Color(0xffF9F9F1),
            enableActiveFill: false,
            controller: enterPin,
            keyboardType: TextInputType.visiblePassword,
            boxShadows: const [
              BoxShadow(
                offset: Offset(0, 1),
                color: Colors.black12,
                blurRadius: 10,
              )
            ],
            onCompleted: (pin) async {
              myWalletProvider.pinCode = pin.toUpperCase();
              myWalletProvider.pinLenght = pinLenght;
              log.d('$pin || ${generateWalletProvider.pin.text}');
              if (pin.toUpperCase() == generateWalletProvider.pin.text) {
                pinColor = Colors.green[500];
                myWalletProvider.isPinLoading = false;
                myWalletProvider.isPinValid = true;

                await generateWalletProvider.storeHDWChest(context);
                bool isAlive = false;
                if (scanDerivation) {
                  isAlive =
                      await generateWalletProvider.scanDerivations(context);
                }
                if (!isAlive) {
                  final address = await sub.importAccount(
                      mnemonic: generateWalletProvider.generatedMnemonic!,
                      derivePath: '//2',
                      password: generateWalletProvider.pin.text);
                  WalletData myWallet = WalletData(
                      chest: configBox.get('currentChest'),
                      address: address,
                      number: 0,
                      name: 'currentWallet'.tr(),
                      derivation: 2,
                      imageDefaultPath: '0.png',
                      isOwned: true);
                  await walletBox.put(myWallet.address, myWallet);
                }
                myWalletProvider.readAllWallets(currentChest);
                myWalletProvider.reload();

                generateWalletProvider.generatedMnemonic = '';
                myWalletProvider.resetPinCode();
                // sleep(const Duration(milliseconds: 500));
                Navigator.push(
                  context,
                  FaderTransition(
                      page: const OnboardingStepEleven(), isFast: false),
                );
              } else {
                hasError = true;
                myWalletProvider.isPinLoading = false;
                myWalletProvider.isPinValid = false;
                pinColor = Colors.red[600];
                enterPin.text = '';
                // myWalletProvider.reload();
                pinFocus.requestFocus();
              }
            },
            onChanged: (value) {
              if (enterPin.text != '') myWalletProvider.isPinLoading = true;
              if (pinColor != const Color(0xFFA4B600)) {
                pinColor = const Color(0xFFA4B600);
              }
              myWalletProvider.reload();
            },
          )),
    );
  }
}
