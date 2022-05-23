// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/11_congratulations.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepFourteen extends StatelessWidget {
  OnboardingStepFourteen({
    Key? validationKey,
  }) : super(key: validationKey);

  final formKey = GlobalKey<FormState>();
  Color? pinColor = const Color(0xFFA4B600);
  bool hasError = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    CommonElements common = CommonElements();
    final int _pinLenght = _generateWalletProvider.pin.text.length;

    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text(
              'Mon code secret',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: isTall ? 40 : 20),
            common.buildProgressBar(9),
            SizedBox(height: isTall ? 40 : 20),
            common.buildText(<TextSpan>[
              TextSpan(
                  text:
                      "Gecko va vérifier avec vous si vous avez bien mémorisé votre code secret.\n\nTapez votre code secret dans le champ ci-dessous pour vérifier que vous l’avez bien noté.",
                  style: TextStyle(fontSize: 16 * ratio))
            ]),
            SizedBox(height: isTall ? 80 : 20),
            pinForm(context, _walletOptions, _pinLenght, 1, 2)
          ]),
        ));
  }

  Widget pinForm(context, WalletOptionsProvider _walletOptions, _pinLenght,
      int _walletNbr, int _derivation) {
    // var _walletPin = '';
// ignore: close_sinks
    StreamController<ErrorAnimationType> errorController =
        StreamController<ErrorAnimationType>();
    TextEditingController _enterPin = TextEditingController();
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    final int? _currentChest = _myWalletProvider.getCurrentChest();

    return Form(
      key: formKey,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30),
          child: PinCodeTextField(
            key: const Key('formKey2'),
            autoFocus: true,
            appContext: context,
            pastedTextStyle: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
            length: _pinLenght,
            obscureText: true,
            obscuringCharacter: '*',
            animationType: AnimationType.fade,
            validator: (v) {
              if (v!.length < _pinLenght) {
                return "Votre code PIN fait $_pinLenght caractères";
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
            cursorColor: Colors.black,
            animationDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(fontSize: 20, height: 1.6),
            backgroundColor: const Color(0xffF9F9F1),
            enableActiveFill: false,
            errorAnimationController: errorController,
            controller: _enterPin,
            keyboardType: TextInputType.text,
            boxShadows: const [
              BoxShadow(
                offset: Offset(0, 1),
                color: Colors.black12,
                blurRadius: 10,
              )
            ],
            onCompleted: (_pin) async {
              _myWalletProvider.pinCode = _pin.toUpperCase();
              _myWalletProvider.pinLenght = _pinLenght;
              log.d(_pin + ' || ' + _generateWalletProvider.pin.text);
              if (_pin.toUpperCase() == _generateWalletProvider.pin.text) {
                pinColor = Colors.green[500];
                final address = await _sub.importAccount(
                    fromMnemonic: true,
                    mnemonic: _generateWalletProvider.generatedMnemonic!,
                    derivePath: '//2',
                    password: _generateWalletProvider.pin.text);
                await _generateWalletProvider.storeHDWChest(
                    address, 'Mon portefeuille courant', context);
                _myWalletProvider.readAllWallets(_currentChest);
                // scheduleMicrotask(() {
                // _walletOptions.reloadBuild();
                _myWalletProvider.rebuildWidget();
                // });
                _generateWalletProvider.generatedMnemonic = '';
                Navigator.push(
                  context,
                  FaderTransition(
                      page: const OnboardingStepFiveteen(), isFast: false),
                );
              } else {
                errorController.add(ErrorAnimationType
                    .shake); // Triggering error shake animation
                hasError = true;
                pinColor = Colors.red[600];
                _walletOptions.reloadBuild();
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
