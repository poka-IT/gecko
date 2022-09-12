// ignore_for_file: file_names
// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    WalletOptionsProvider walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    CommonElements common = CommonElements();
    final int pinLenght = generateWalletProvider.pin.text.length;

    return Scaffold(
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
        ),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Stack(children: [
            Column(children: <Widget>[
              SizedBox(height: isTall ? 40 : 20),
              common.buildProgressBar(9),
              SizedBox(height: isTall ? 40 : 20),
              common.buildText("geckoWillCheckPassword".tr()),
              SizedBox(height: isTall ? 80 : 20),
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
              Consumer<SubstrateSdk>(builder: (context, sub, _) {
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
        ));
  }

  Widget pinForm(context, WalletOptionsProvider walletOptions, pinLenght,
      int walletNbr, int derivation) {
    // var _walletPin = '';
// ignore: close_sinks
    StreamController<ErrorAnimationType> errorController =
        StreamController<ErrorAnimationType>();
    TextEditingController enterPin = TextEditingController();
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    GenerateWalletsProvider generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);

    final int currentChest = myWalletProvider.getCurrentChest();

    return Form(
      key: formKey,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30),
          child: PinCodeTextField(
            key: keyPinForm,
            autoFocus: true,
            appContext: context,
            pastedTextStyle: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
            length: pinLenght,
            obscureText: true,
            obscuringCharacter: '*',
            animationType: AnimationType.fade,
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
              fieldHeight: 60,
              fieldWidth: 50,
              activeFillColor: hasError ? Colors.blueAccent : Colors.black,
            ),
            showCursor: kDebugMode ? false : true,
            cursorColor: Colors.black,
            animationDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(fontSize: 20, height: 1.6),
            backgroundColor: const Color(0xffF9F9F1),
            enableActiveFill: false,
            errorAnimationController: errorController,
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
                      version: dataVersion,
                      chest: configBox.get('currentChest'),
                      address: address,
                      number: 0,
                      name: 'currentWallet'.tr(),
                      derivation: 2,
                      imageDefaultPath: '0.png');
                  await walletBox.add(myWallet);
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
                errorController.add(ErrorAnimationType
                    .shake); // Triggering error shake animation
                hasError = true;
                pinColor = Colors.red[600];
                walletOptions.reload();
              }
            },
            onChanged: (value) {
              if (pinColor != const Color(0xFFA4B600)) {
                pinColor = const Color(0xFFA4B600);
              }
            },
          )),
    );
  }
}
