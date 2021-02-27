import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'dart:async';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class WalletOptions extends StatelessWidget with ChangeNotifier {
  WalletOptions(
      {Key keyMyWallets,
      @required this.walletNbr,
      @required this.walletName,
      @required this.derivation})
      : super(key: keyMyWallets);
  int walletNbr;
  String walletName;
  int derivation;

  StreamController<ErrorAnimationType> errorController;
  TextEditingController _enterPin = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hasError = false;
  var pinColor = Color(0xffF9F9F1);
  var walletPin = '';

  Future<NewWallet> get badWallet => null;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    print("Build walletOptions");
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    errorController = StreamController<ErrorAnimationType>();
    // _walletOptions.isWalletUnlock = false;

    final int _pinLenght = _walletOptions.getPinLenght(this.walletNbr);

    return WillPopScope(
        onWillPop: () {
          _walletOptions.isWalletUnlock = false;
          return Future<bool>.value(true);
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
                leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      _walletOptions.isWalletUnlock = false;
                      Navigator.of(context).pop();
                    }),
                title: SizedBox(
                  height: 22,
                  child: Text(walletName),
                )),
            body: Builder(
                builder: (ctx) => SafeArea(
                        child: Column(children: <Widget>[
                      Visibility(
                          visible: _walletOptions.isWalletUnlock,
                          child: Expanded(
                              child: Column(children: <Widget>[
                            SizedBox(height: 15),
                            Text(
                              'Clé publique:',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400),
                            ),
                            SizedBox(height: 15),
                            GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: _walletOptions.pubkey.text));
                                  _walletOptions.snackCopyKey(ctx);
                                },
                                child: Text(
                                  _walletOptions.pubkey.text,
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Monospace'),
                                )),
                            Expanded(
                                child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SizedBox(
                                        height: 50,
                                        width: 300,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              elevation: 5,
                                              primary: Color(
                                                  0xffFFD68E), //Color(0xffFFD68E), // background
                                              onPrimary:
                                                  Colors.black, // foreground
                                            ),
                                            onPressed: () => _walletOptions
                                                    .renameWalletAlerte(
                                                        context,
                                                        walletName,
                                                        walletNbr,
                                                        derivation)
                                                    .then((_result) {
                                                  if (_result == true) {
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      _myWalletProvider
                                                              .listWallets =
                                                          _myWalletProvider
                                                              .getAllWalletsNames();
                                                      _myWalletProvider
                                                          .rebuildWidget();
                                                    });
                                                    Navigator.pop(
                                                        context, true);
                                                  }
                                                }),
                                            child: Text(
                                                'Renommer ce portefeuille',
                                                style: TextStyle(
                                                    fontSize: 20)))))),
                            SizedBox(height: 30),
                            SizedBox(
                                height: 50,
                                width: 300,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 6,
                                      primary: Colors
                                          .redAccent, //Color(0xffFFD68E), // background
                                      onPrimary: Colors.black, // foreground
                                    ),
                                    onPressed: () async {
                                      await _walletOptions.deleteWallet(context,
                                          walletNbr, walletName, derivation);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        _myWalletProvider.listWallets =
                                            _myWalletProvider
                                                .getAllWalletsNames();
                                        _myWalletProvider.rebuildWidget();
                                      });
                                    },
                                    child: Text('Supprimer ce portefeuille',
                                        style: TextStyle(fontSize: 20)))),
                            SizedBox(height: 50),
                            Text(
                              'Portefeuille déverrouillé',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                            SizedBox(height: 10)
                          ]))),
                      Visibility(
                          visible: !_walletOptions.isWalletUnlock,
                          child: Expanded(
                              child: Column(children: <Widget>[
                            SizedBox(height: 80),
                            Text(
                              'Veuillez tapper votre code secret pour dévérouiller votre portefeuille.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400),
                            ),
                            SizedBox(height: 50),
                            Form(
                              key: formKey,
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 30),
                                  child: PinCodeTextField(
                                    autoFocus: true,
                                    appContext: context,
                                    pastedTextStyle: TextStyle(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    length: _pinLenght,
                                    obscureText: false,
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
                                      shape: PinCodeFieldShape.box,
                                      borderRadius: BorderRadius.circular(5),
                                      fieldHeight: 60,
                                      fieldWidth: 50,
                                      activeFillColor: hasError
                                          ? Colors.orange
                                          : Colors.white,
                                    ),
                                    cursorColor: Colors.black,
                                    animationDuration:
                                        Duration(milliseconds: 300),
                                    textStyle:
                                        TextStyle(fontSize: 20, height: 1.6),
                                    backgroundColor: pinColor,
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
                                      print("Completed");
                                      final resultWallet =
                                          await _walletOptions.readLocalWallet(
                                              this.walletNbr,
                                              this.walletName,
                                              _pin.toUpperCase(),
                                              _pinLenght,
                                              this.derivation);
                                      if (resultWallet == 'bad') {
                                        errorController.add(ErrorAnimationType
                                            .shake); // Triggering error shake animation
                                        hasError = true;
                                        pinColor = Colors.red[200];
                                        notifyListeners();
                                      } else {
                                        pinColor = Colors.green[200];
                                        // setState(() {});
                                        // await Future.delayed(Duration(milliseconds: 50));
                                        this.walletPin = _pin.toUpperCase();
                                        // isWalletUnlock = true;
                                        notifyListeners();
                                      }
                                    },
                                    onChanged: (value) {
                                      if (pinColor != Color(0xffF9F9F1)) {
                                        pinColor = Color(0xffF9F9F1);
                                      }
                                      print(value);
                                    },
                                  )),
                            )
                          ]))),
                    ])))));
  }
}
