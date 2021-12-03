import 'dart:async';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallets_profiles.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/wallet_options.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/cesium_wallet_options.dart';
import 'package:gecko/screens/myWallets/choose_chest.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:gecko/globals.dart';

// ignore: must_be_immutable
class UnlockingWallet extends StatelessWidget {
  UnlockingWallet(
      {Key keyUnlockWallet, @required this.wallet, @required this.action})
      : super(key: keyUnlockWallet);
  WalletData wallet;
  String action;

  // ignore: close_sinks
  StreamController<ErrorAnimationType> errorController;
  final formKey = GlobalKey<FormState>();
  var pinColor = const Color(0xffF9F9F1);
  var walletPin = '';
  String resultPay;

  Future<NewWallet> get badWallet => null;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);

    int _pinLenght;
    ChestData currentChest = chestBox.get(configBox.get('currentChest'));

    if (currentChest.isCesium) {
      _pinLenght = _walletOptions.getPinLenght(currentChest.dewif);
      wallet = WalletData(derivation: -1, chest: currentChest.key);
    } else {
      _pinLenght = _walletOptions.getPinLenght(wallet.number);
    }
    errorController = StreamController<ErrorAnimationType>();

    return Scaffold(
        // backgroundColor: Colors.brown[600],
        body: SafeArea(
      child: Column(children: <Widget>[
        Expanded(
          child: Column(children: <Widget>[
            SizedBox(height: isTall ? 100 : 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              currentChest.imageFile == null
                  ? Image.asset(
                      'assets/chests/${currentChest.imageName}',
                      width: isTall ? 130 : 100,
                    )
                  : Image.file(
                      currentChest.imageFile,
                      width: isTall ? 130 : 100,
                    ),
              const SizedBox(width: 5),
              SizedBox(
                  width: 250,
                  child: Text(
                    currentChest.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.w700),
                  )),
            ]),
            SizedBox(height: 30 * ratio),
            const SizedBox(
                width: 400,
                child: Text(
                  'Pour déverrouiller votre coffre, composez votre code secret à l’abri des lézards indiscrets :',
                  style: TextStyle(
                      fontSize: 19,
                      color: Colors.black,
                      fontWeight: FontWeight.w400),
                )),
            SizedBox(height: 40 * ratio),
            pinForm(context, _pinLenght, currentChest),
            SizedBox(height: 3 * ratio),
            InkWell(
                key: const Key('chooseChest'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return ChooseChest(action: action);
                    }),
                  );
                },
                child: SizedBox(
                  width: 400,
                  height: 70,
                  child: Center(
                    child: Text(
                      'Changer de coffre',
                      style: TextStyle(
                          fontSize: 22,
                          color: orangeC,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
          ]),
        ),
      ]),
    ));
  }

  Widget pinForm(context, _pinLenght, ChestData currentChest) {
    // var _walletPin = '';
// ignore: close_sinks
    StreamController<ErrorAnimationType> errorController =
        StreamController<ErrorAnimationType>();
    TextEditingController _enterPin = TextEditingController();
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context);

    FocusNode pinFocus = FocusNode();

    return Form(
      key: formKey,
      child: Padding(
          padding: EdgeInsets.symmetric(vertical: 5 * ratio, horizontal: 30),
          child: PinCodeTextField(
            focusNode: pinFocus,
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
              if (v.length < _pinLenght) {
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
              fieldHeight: 50 * ratio,
              fieldWidth: 50,
              activeFillColor: Colors.black,
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
              log.d("Completed");
              _myWalletProvider.pinCode = _pin;
              final String resultWallet = await _walletOptions.readLocalWallet(
                  context, wallet, _pin.toUpperCase(), _pinLenght);
              // _myWalletProvider.pinCode = _pin.toUpperCase();
              _myWalletProvider.pinLenght = _pinLenght;

              if (resultWallet == 'bad') {
                errorController.add(ErrorAnimationType
                    .shake); // Triggering error shake animation
                pinColor = Colors.red[600];
                _walletOptions.reloadBuild();
                pinFocus.requestFocus();
              } else {
                pinColor = Colors.green[400];
                // await Future.delayed(Duration(milliseconds: 50));
                if (action == "mywallets") {
                  currentChest.isCesium
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return CesiumWalletOptions(
                                cesiumWallet: currentChest);
                          }),
                        )
                      : Navigator.pushNamed(
                          formKey.currentContext, '/mywallets');
                } else if (action == "pay") {
                  resultPay =
                      await _historyProvider.pay(context, _pin.toUpperCase());
                  await _paymentsResult(context);
                }
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

  Future<bool> _paymentsResult(context) {
    if (resultPay != "Success") log.i(resultPay);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(resultPay == "Success"
              ? 'Paiement effecuté avec succès !'
              : "Une erreur s'est produite lors du paiement"),
          content: const SingleChildScrollView(child: Text('')),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
