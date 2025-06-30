import 'dart:async';
import 'dart:io';
import 'package:durt2/durt2.dart' show Durt, SafeBox, WalletData;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
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
  late int currentSafeNumber;
  late SafeBox currentSafe;
  bool canUnlock = true;
  late final TextEditingController enterPin;
  late final FocusNode pinFocus;

  Color pinColor = const Color(0xffF9F9F1);

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode');
    enterPin = TextEditingController();
    currentSafeNumber = Durt.i.wallets.defaultSafeBoxNumber;
    currentSafe = Durt.i.wallets.safeBox.get(currentSafeNumber)!;
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    final pinLenght = walletOptions.getPinLenght();

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        myWalletProvider.isPinValid = false;
        myWalletProvider.isPinLoading = true;
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 8, top: isTall ? 14 : 0),
                  child: IconButton(
                    key: keyPopButton,
                    icon: Icon(Icons.arrow_back, color: Colors.black, size: scaleSize(28)),
                    onPressed: () {
                      myWalletProvider.isPinValid = false;
                      myWalletProvider.isPinLoading = true;
                      Navigator.pop(context);
                    },
                  ),
                ),
                ScaledSizedBox(height: isTall ? 12 : 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    currentSafe.imagePath == null
                        ? Image.asset('assets/chests/${currentSafe.number}.png', width: scaleSize(isTall ? 95 : 75))
                        : Image.file(File(currentSafe.imagePath!), width: scaleSize(isTall ? 127 : 95)),
                    ScaledSizedBox(width: 18),
                    Flexible(
                      child: Text(
                        currentSafe.name,
                        textAlign: TextAlign.center,
                        style: scaledTextStyle(
                          fontSize: isTall ? 24 : 20,
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                ScaledSizedBox(height: isTall ? 30 : 15),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(isTall ? 24 : 16),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
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
                          fontSize: isTall ? 16 : 14,
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ScaledSizedBox(height: isTall ? 24 : 12),
                      if (!myWalletProvider.isPinValid && !myWalletProvider.isPinLoading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            "thisIsNotAGoodCode".tr(),
                            style: scaledTextStyle(color: Colors.red[700], fontWeight: FontWeight.w500, fontSize: 15),
                          ),
                        ),
                      pinForm(context, pinLenght),
                      ScaledSizedBox(height: isTall ? 16 : 8),
                      if (canUnlock)
                        Consumer<WalletOptionsProvider>(
                          builder: (context, sub, _) {
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
                                    color: context.colorScheme.primary,
                                    size: scaleSize(20),
                                  ),
                                  ScaledSizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'rememberPassword'.tr(),
                                      style: scaledTextStyle(
                                        fontSize: 12,
                                        color: homeContext.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget pinForm(BuildContext context, int pinLenght) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    return Form(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(3), horizontal: scaleSize(isTall ? 30 : 20)),
        child: PinCodeTextField(
          key: keyPinForm,
          textCapitalization: TextCapitalization.characters,
          focusNode: pinFocus,
          autoFocus: true,
          appContext: context,
          pastedTextStyle: scaledTextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
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
            activeFillColor: context.colorScheme.surfaceContainer,
            selectedFillColor: context.colorScheme.surfaceContainer,
            inactiveFillColor: context.colorScheme.surfaceContainer,
            activeColor: pinColor,
            selectedColor: context.colorScheme.primary,
            inactiveColor: Colors.grey[300],
            borderWidth: 1.5,
          ),
          enableActiveFill: true,
          showCursor: !kDebugMode,
          cursorColor: context.colorScheme.primary,
          cursorHeight: 25,
          textStyle: scaledTextStyle(fontSize: 24, height: 1.6, fontWeight: FontWeight.w600),
          backgroundColor: Colors.transparent,
          controller: enterPin,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onCompleted: (pin) async {
            myWalletProvider.isPinLoading = true;
            myWalletProvider.pinCode = pin.toUpperCase();
            final isValid = await Durt.i.wallets.checkCode(pin: pin.toUpperCase());
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
              // ignore: use_build_context_synchronously
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
        ),
      ),
    );
  }
}
