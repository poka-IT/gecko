import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:gecko/screens/myWallets/changePin.dart';
import 'dart:async';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class WalletOptions extends StatelessWidget with ChangeNotifier {
  WalletOptions({Key keyMyWallets, @required this.walletName})
      : super(key: keyMyWallets);
  String walletName;

  StreamController<ErrorAnimationType> errorController;
  TextEditingController _enterPin = new TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hasError = false;
  var pinColor = Color(0xffF9F9F1);
  var walletPin = '';

  Future<NewWallet> get badWallet => null;

  @override
  Widget build(BuildContext context) {
    print("Build walletOptions");
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    errorController = StreamController<ErrorAnimationType>();
    // _walletOptions.isWalletUnlock = false;
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
                      Navigator.of(context).pop();
                      _walletOptions.isWalletUnlock = false;
                    }),
                title: SizedBox(
                  height: 22,
                  child: Text(walletName),
                )),
            body: Center(
                child: SafeArea(
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
                    Text(
                      _walletOptions.pubkey.text,
                      style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
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
                                      onPrimary: Colors.black, // foreground
                                    ),
                                    onPressed: () => _walletOptions
                                            .renameWalletAlerte(
                                                context, walletName)
                                            .then((_result) {
                                          if (_result == true) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              _myWalletProvider.listWallets =
                                                  _myWalletProvider
                                                      .getAllWalletsNames();
                                              _myWalletProvider.rebuildWidget();
                                            });
                                          }
                                        }),
                                    child: Text('Renommer ce portefeuille',
                                        style: TextStyle(fontSize: 20)))))),
                    SizedBox(height: 30),
                    SizedBox(
                        height: 50,
                        width: 300,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 5,
                              primary: Color(
                                  0xffFFD68E), //Color(0xffFFD68E), // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: () {
                              // changePin(widget.walletName, this.walletPin);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return ChangePinScreen(
                                      walletName: walletName,
                                      oldPin: this.walletPin);
                                }),
                              );
                            },
                            child: Text('Changer mon code secret',
                                style: TextStyle(fontSize: 20)))),
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
                              await _walletOptions.deleteWallet(
                                  context, walletName);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _myWalletProvider.listWallets =
                                    _myWalletProvider.getAllWalletsNames();
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
                            length: 6,
                            obscureText: false,
                            obscuringCharacter: '*',
                            animationType: AnimationType.fade,
                            validator: (v) {
                              if (v.length < 6) {
                                return "Votre code PIN fait 6 caractères";
                              } else {
                                return null;
                              }
                            },
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(5),
                              fieldHeight: 60,
                              fieldWidth: 50,
                              activeFillColor:
                                  hasError ? Colors.orange : Colors.white,
                            ),
                            cursorColor: Colors.black,
                            animationDuration: Duration(milliseconds: 300),
                            textStyle: TextStyle(fontSize: 20, height: 1.6),
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
                                      this.walletName, _pin.toUpperCase());
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
