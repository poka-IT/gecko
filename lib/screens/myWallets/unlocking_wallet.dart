// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:flutter/material.dart';
// import 'package:gecko/screens/myWallets/choose_chest.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:gecko/globals.dart';

class UnlockingWallet extends StatelessWidget {
  UnlockingWallet({required this.wallet}) : super(key: keyUnlockWallet);
  WalletData wallet;
  late int currentChestNumber;
  late ChestData currentChest;
  bool canUnlock = true;
  TextEditingController enterPin = TextEditingController();
  FocusNode pinFocus = FocusNode(debugLabel: 'pinFocusNode');

  // ignore: close_sinks
  StreamController<ErrorAnimationType>? errorController;
  Color? pinColor = const Color(0xffF9F9F1);
  var walletPin = '';

  @override
  Widget build(BuildContext context) {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    currentChestNumber = configBox.get('currentChest');
    currentChest = chestBox.get(currentChestNumber)!;

    int pinLenght = walletOptions.getPinLenght(wallet.number);
    errorController = StreamController<ErrorAnimationType>();

    // if (enterPin.text == '') myWalletProvider.isPinLoading = true;

    return WillPopScope(
      onWillPop: () {
        myWalletProvider.isPinValid = false;
        myWalletProvider.isPinLoading = true;
        return Future<bool>.value(true);
      },
      child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(children: <Widget>[
                    Positioned(
                      top: 10, //statusBarHeight + 10,
                      left: 15,
                      child: Builder(
                        builder: (context) => IconButton(
                          key: keyPopButton,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 30,
                          ),
                          onPressed: () {
                            myWalletProvider.isPinValid = false;
                            myWalletProvider.isPinLoading = true;
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    Column(children: <Widget>[
                      SizedBox(height: isTall ? 100 : 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            currentChest.imageFile == null
                                ? Image.asset(
                                    'assets/chests/${currentChest.imageName}',
                                    width: isTall ? 130 : 100,
                                  )
                                : Image.file(
                                    currentChest.imageFile!,
                                    width: isTall ? 130 : 100,
                                  ),
                            const SizedBox(width: 5),
                            SizedBox(
                                width: 250,
                                child: Text(
                                  currentChest.name!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 25,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700),
                                )),
                          ]),
                      SizedBox(height: 30 * ratio),
                      SizedBox(
                          width: 400,
                          child: Text(
                            'toUnlockEnterPassword'.tr(),
                            style: const TextStyle(
                                fontSize: 19,
                                color: Colors.black,
                                fontWeight: FontWeight.w400),
                          )),
                      SizedBox(height: 30 * ratio),
                      if (!myWalletProvider.isPinValid &&
                          !myWalletProvider.isPinLoading)
                        Text(
                          "thisIsNotAGoodCode".tr(),
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      SizedBox(height: 10 * ratio),
                      pinForm(context, pinLenght),
                      SizedBox(height: 3 * ratio),
                      if (canUnlock)
                        Consumer<WalletOptionsProvider>(
                            builder: (context, sub, _) {
                          return InkWell(
                            key: keyCachePassword,
                            onTap: () {
                              walletOptions.changePinCacheChoice();
                            },
                            child: Row(children: [
                              const SizedBox(height: 30),
                              const Spacer(),
                              Icon(
                                configBox.get('isCacheChecked')
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
                            ]),
                          );
                        }),
                      const SizedBox(height: 10),
                      // if (canUnlock)
                      InkWell(
                          key: keyChangeChest,
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(builder: (context) {
                            //     return const ChooseChest();
                            //   }),
                            // );
                          },
                          child: SizedBox(
                            width: 400,
                            height: 50,
                            child: Center(
                              child: Text(
                                'changeChest'.tr(),
                                style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.grey, // orangeC
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          )),
                    ]),
                  ]),
                ]),
          )),
    );
  }

  Widget pinForm(context, pinLenght) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = myWalletProvider.getDefaultWallet();

    // if (defaultWallet.address == null) {
    //   canUnlock = false;
    //   return Text(
    //     'Impossible de retrouver votre\nportefeuille par défaut.\nID: ${defaultWallet.id()}',
    //     textAlign: TextAlign.center,
    //     style: const TextStyle(
    //         color: Colors.redAccent, fontWeight: FontWeight.w500),
    //   );
    // }

    return Form(
      child: Padding(
          padding: EdgeInsets.symmetric(vertical: 5 * ratio, horizontal: 30),
          child: PinCodeTextField(
            key: keyPinForm,
            textCapitalization: TextCapitalization.characters,
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
              myWalletProvider.isPinLoading = true;
              myWalletProvider.pinCode = pin.toUpperCase();
              final isValid = await sub.checkPassword(
                  defaultWallet.address, pin.toUpperCase());
              if (!isValid) {
                await Future.delayed(const Duration(milliseconds: 20));
                pinColor = Colors.red[600];
                myWalletProvider.isPinLoading = false;
                myWalletProvider.isPinValid = false;
                myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
                enterPin.text = '';
                pinFocus.requestFocus();
              } else {
                myWalletProvider.isPinValid = true;
                myWalletProvider.isPinLoading = false;
                pinColor = Colors.green[400];
                myWalletProvider.resetPinCode();
                Navigator.pop(context, pin.toUpperCase());
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
