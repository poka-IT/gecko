import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:gecko/ui/myWallets/changePin.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sentry/sentry.dart' as sentry;

class WalletOptions extends StatefulWidget {
  const WalletOptions({Key keyMyWallets, @required this.walletName})
      : super(key: keyMyWallets);

  final String walletName;
  @override
  WalletOptionsState createState() => WalletOptionsState();
}

class WalletOptionsState extends State<WalletOptions> {
  StreamController<ErrorAnimationType> errorController;
  Directory appPath;
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _enterPin = new TextEditingController();
  TextEditingController _newWalletName = new TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hasError = false;
  String validPin = 'NO PIN';
  var pinColor = Color(0xffF9F9F1);
  bool isWalletUnlock = false;
  var walletPin = '';

  Future<NewWallet> get badWallet => null;

  void initState() {
    super.initState();
    errorController = StreamController<ErrorAnimationType>();
    DubpRust.setup();
    isWalletUnlock = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            title: SizedBox(
          height: 22,
          child: Text(widget.walletName),
        )),
        body: Center(
            child: SafeArea(
                child: Column(children: <Widget>[
          Visibility(
              visible: isWalletUnlock,
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
                  this._pubkey.text,
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
                                onPressed: () =>
                                    _renameWalletAlerte().then((_) {
                                      setState(() {});
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
                                  walletName: widget.walletName,
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
                        onPressed: () {
                          _deleteWallet(widget.walletName);
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
              visible: !isWalletUnlock,
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
                              await _readLocalWallet(_pin.toUpperCase());
                          if (resultWallet == 'bad') {
                            errorController.add(ErrorAnimationType
                                .shake); // Triggering error shake animation
                            setState(() {
                              hasError = true;
                              pinColor = Colors.red[200];
                            });
                          } else {
                            pinColor = Colors.green[200];
                            // setState(() {});
                            // await Future.delayed(Duration(milliseconds: 50));
                            this.walletPin = _pin.toUpperCase();
                            isWalletUnlock = true;
                            setState(() {});
                          }
                        },
                        onChanged: (value) {
                          if (pinColor != Color(0xffF9F9F1)) {
                            setState(() {
                              pinColor = Color(0xffF9F9F1);
                            });
                          }
                          print(value);
                        },
                      )),
                )
              ]))),
        ]))));
  }

  Future _getPubkeyFromDewif(_dewif, _pin) async {
    String _pubkey;
    RegExp regExp = new RegExp(
      r'^[A-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(_pin) == true && _pin.length == 6) {
      print("Le format du code PIN est correct.");
    } else {
      print('Format de code PIN invalide');
      return 'false';
    }
    try {
      _pubkey = await DubpRust.getDewifPublicKey(dewif: _dewif, pin: _pin);
      setState(() {
        this._pubkey.text = _pubkey;
      });

      return _pubkey;
    } catch (e, stack) {
      print('Bad PIN code !');
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
      return 'false';
    }
  }

  Future _readLocalWallet(String _pin) async {
    // print(pin);
    try {
      final file = await _localWallet(widget.walletName);
      String _localDewif = await file.readAsString();
      String _localPubkey;

      if ((_localPubkey = await _getPubkeyFromDewif(_localDewif, _pin)) !=
          'false') {
        setState(() {
          this._pubkey.text = _localPubkey;
        });

        return _localDewif;
      } else {
        throw 'Bad pubkey';
      }
    } catch (e) {
      print('ERROR READING FILE: $e');
      setState(() {
        this._pubkey.clear();
      });
      return 'bad';
    }
  }

  Future _renameWallet(_newName) async {
    final appPath = await _localPath;
    final _walletFile = Directory('$appPath/wallets/${widget.walletName}');

    try {
      _walletFile.rename('$appPath/wallets/$_newName');
    } catch (e) {
      print('ERREUR lors du renommage du wallet: $e');
    }
  }

  Future<bool> _renameWalletAlerte() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisissez un nouveau nom pour ce portefeuille'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                    controller: this._newWalletName,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(),
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Valider"),
              onPressed: () {
                _renameWallet(this._newWalletName.text);
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<int> _deleteWallet(_name) async {
    try {
      final appPath = await _localPath;
      final _walletFile = Directory('$appPath/wallets/$_name');
      print('DELETE THAT ?: $_walletFile');

      final bool _answer = await _confirmDeletingWallet();

      if (_answer) {
        _walletFile.deleteSync(recursive: true);
        Navigator.pop(context);
      }
      return 0;
    } catch (e) {
      return 1;
    }
  }

  Future<bool> _confirmDeletingWallet() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Êtes-vous sûr de vouloir supprimer le portefeuille "${widget.walletName}" ?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Vous pourrez restaurer ce portefeuille à tout moment grace à votre phrase de restauration.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Non"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text("Oui"),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localWallet(_name) async {
    final path = await _localPath;
    return File('$path/wallets/$_name/wallet.dewif');
  }
}
