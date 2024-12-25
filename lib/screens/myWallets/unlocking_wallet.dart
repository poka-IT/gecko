import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:gecko/globals.dart';

class UnlockingWallet extends StatefulWidget {
  const UnlockingWallet({required this.wallet}) : super(key: keyUnlockWallet);
  final WalletData wallet;

  @override
  State<UnlockingWallet> createState() => _UnlockingWalletState();
}

class _UnlockingWalletState extends State<UnlockingWallet> {
  late int currentChestNumber;
  late ChestData currentChest;
  bool canUnlock = true;
  late final TextEditingController enterPin;
  late final FocusNode pinFocus;

  Color pinColor = const Color(0xffF9F9F1);

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode');
    enterPin = TextEditingController();
    currentChestNumber = configBox.get('currentChest');
    currentChest = chestBox.get(currentChestNumber)!;
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    final pinLenght = walletOptions.getPinLenght(widget.wallet.number);

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        myWalletProvider.isPinValid = false;
        myWalletProvider.isPinLoading = true;
      },
      child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  key: keyPopButton,
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: scaleSize(28),
                  ),
                  onPressed: () {
                    myWalletProvider.isPinValid = false;
                    myWalletProvider.isPinLoading = true;
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    ScaledSizedBox(height: isTall ? 40 : 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        currentChest.imageFile == null
                            ? Image.asset(
                                'assets/chests/${currentChest.imageName}',
                                width: scaleSize(95),
                              )
                            : Image.file(
                                currentChest.imageFile!,
                                width: scaleSize(127),
                              ),
                        ScaledSizedBox(width: 18),
                        Flexible(
                          child: Text(
                            currentChest.name!,
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ScaledSizedBox(height: isTall ? 40 : 25),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'toUnlockEnterPassword'.tr(),
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ScaledSizedBox(height: isTall ? 24 : 16),
                          if (!myWalletProvider.isPinValid && !myWalletProvider.isPinLoading)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                "thisIsNotAGoodCode".tr(),
                                style: scaledTextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          pinForm(context, pinLenght),
                          ScaledSizedBox(height: 16),
                          if (canUnlock)
                            Consumer<WalletOptionsProvider>(builder: (context, sub, _) {
                              return InkWell(
                                key: keyCachePassword,
                                onTap: () {
                                  walletOptions.changePinCacheChoice();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      configBox.get('isCacheChecked') ? Icons.check_box : Icons.check_box_outline_blank,
                                      color: orangeC,
                                      size: scaleSize(20),
                                    ),
                                    ScaledSizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'rememberPassword'.tr(),
                                        style: scaledTextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          )),
    );
  }

  Widget pinForm(context, pinLenght) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    final defaultWallet = myWalletProvider.getDefaultWallet();

    return Form(
      child: Padding(
          padding: EdgeInsets.symmetric(vertical: scaleSize(3), horizontal: scaleSize(isTall ? 30 : 20)),
          child: PinCodeTextField(
            key: keyPinForm,
            textCapitalization: TextCapitalization.characters,
            focusNode: pinFocus,
            autoFocus: true,
            appContext: context,
            pastedTextStyle: scaledTextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
            length: pinLenght,
            obscureText: true,
            obscuringCharacter: '●',
            animationType: AnimationType.fade,
            animationDuration: const Duration(milliseconds: 150),
            useHapticFeedback: true,
            validator: (v) {
              if (v!.length < pinLenght) {
                return "yourPasswordLengthIsX".tr(args: [pinLenght.toString()]);
              } else {
                return null;
              }
            },
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: scaleSize(50),
              fieldWidth: scaleSize(50),
              activeFillColor: Colors.white,
              selectedFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              activeColor: pinColor,
              selectedColor: orangeC,
              inactiveColor: Colors.grey[300],
              borderWidth: 1.5,
            ),
            enableActiveFill: true,
            showCursor: !kDebugMode,
            cursorColor: orangeC,
            cursorHeight: 25,
            textStyle: scaledTextStyle(
              fontSize: 24,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.transparent,
            controller: enterPin,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onCompleted: (pin) async {
              myWalletProvider.isPinLoading = true;
              myWalletProvider.pinCode = pin.toUpperCase();
              final isValid = await sub.checkPassword(defaultWallet.address, pin.toUpperCase());
              if (!isValid) {
                await Future.delayed(const Duration(milliseconds: 20));
                pinColor = Colors.red[600]!;
                myWalletProvider.isPinLoading = false;
                myWalletProvider.isPinValid = false;
                myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
                enterPin.text = '';
                pinFocus.requestFocus();
              } else {
                myWalletProvider.isPinValid = true;
                myWalletProvider.isPinLoading = false;
                pinColor = Colors.green[400]!;
                myWalletProvider.debounceResetPinCode();
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
