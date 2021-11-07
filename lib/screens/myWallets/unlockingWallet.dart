import 'dart:async';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletData.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:flutter/material.dart';
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
  bool hasError = false;
  var pinColor = Color(0xffF9F9F1);
  var walletPin = '';
  String resultPay;

  Future<NewWallet> get badWallet => null;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);

    // log.d("defaultWallet: " + defaultWallet.toString());
    final int _pinLenght = _walletOptions.getPinLenght(wallet.number);
    errorController = StreamController<ErrorAnimationType>();

    return Scaffold(
        // backgroundColor: Colors.brown[600],
        body: SafeArea(
      child: Column(children: <Widget>[
        SizedBox(height: 20),
        Expanded(
          child: Column(children: <Widget>[
            SizedBox(height: 150),
            Text(
              'Veuillez tapper votre code secret pour dévérouiller votre portefeuille.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 50),
            pinForm(context, _pinLenght, wallet.number, wallet.derivation),
          ]),
        ),
        GestureDetector(
            onTap: () {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
            },
            child: Icon(Icons.home))
      ]),
    ));
  }

  Widget pinForm(context, _pinLenght, int _walletNbr, int _derivation) {
    // var _walletPin = '';
// ignore: close_sinks
    StreamController<ErrorAnimationType> errorController =
        StreamController<ErrorAnimationType>();
    TextEditingController _enterPin = TextEditingController();
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);

    return Form(
      key: formKey,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30),
          child: PinCodeTextField(
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
              fieldHeight: 60,
              fieldWidth: 50,
              activeFillColor: hasError ? Colors.blueAccent : Colors.black,
            ),
            cursorColor: Colors.black,
            animationDuration: Duration(milliseconds: 300),
            textStyle: TextStyle(fontSize: 20, height: 1.6),
            backgroundColor: Color(0xffF9F9F1),
            enableActiveFill: false,
            errorAnimationController: errorController,
            controller: _enterPin,
            keyboardType: TextInputType.text,
            boxShadows: [
              BoxShadow(
                offset: Offset(0, 1),
                color: Colors.black12,
                blurRadius: 10,
              )
            ],
            onCompleted: (_pin) async {
              log.d("Completed");
              _myWalletProvider.pinCode = _pin;
              final resultWallet = await _walletOptions.readLocalWallet(
                  context, this.wallet, _pin.toUpperCase(), _pinLenght);
              // _myWalletProvider.pinCode = _pin.toUpperCase();
              _myWalletProvider.pinLenght = _pinLenght;

              if (resultWallet == 'bad') {
                errorController.add(ErrorAnimationType
                    .shake); // Triggering error shake animation
                hasError = true;
                pinColor = Colors.red[600];
                _walletOptions.reloadBuild();
              } else {
                pinColor = Colors.green[400];
                // await Future.delayed(Duration(milliseconds: 50));
                if (action == "mywallets") {
                  Navigator.pushNamed(formKey.currentContext, '/mywallets');
                } else if (action == "pay") {
                  print("Go payments");
                  resultPay =
                      await _historyProvider.pay(context, _pin.toUpperCase());
                  await _paymentsResult(context);
                }
              }
            },
            onChanged: (value) {
              if (pinColor != Color(0xFFA4B600)) {
                pinColor = Color(0xFFA4B600);
              }
            },
          )),
    );
  }

  Future<bool> _paymentsResult(context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(resultPay == "Success"
              ? 'Paiement effecuté avec succès !'
              : "Une erreur s'est produite lors du paiement"),
          content: SingleChildScrollView(child: Text('')),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
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
