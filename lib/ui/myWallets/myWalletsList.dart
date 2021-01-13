// import 'package:gecko/ui/generateWallets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class MyWalletsScreen extends StatefulWidget {
  const MyWalletsScreen({Key keyMyWallets}) : super(key: keyMyWallets);
  @override
  MyWalletState createState() => MyWalletState();
}

class MyWalletState extends State<MyWalletsScreen> {
  // GlobalKey<GenerateWalletState> _keyGenWallet = GlobalKey();
  StreamController<ErrorAnimationType> errorController;
  Directory appPath;
  List _listWallets = [];

  void initState() {
    super.initState();
    errorController = StreamController<ErrorAnimationType>();
    initAppDirectory();
    DubpRust.setup();
    // getAllWalletsNames();
    // initAppDirectory();
    // _walletsList = await getAllWalletsNames();
    // HistoryScreen(
    //   keyHistory: _keyHistory,
    // );
  }

  void initAppDirectory() async {
    appPath = await getApplicationDocumentsDirectory();
    appPath = Directory('${appPath.path}/wallets');
    _listWallets = getAllWalletsNames();
  }

  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _enterPin = new TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Color(0xffF9F9F1);

  @override
  Widget build(BuildContext context) {
    // final _walletsList = getAllWalletsNames();
    return SafeArea(
        child: Column(children: <Widget>[
      SizedBox(height: 8),
      for (var repository in this._listWallets)
        ListTile(
            contentPadding: const EdgeInsets.all(5.0),
            leading: Text(repository, style: TextStyle(fontSize: 14.0)),
            title: Text(repository, style: TextStyle(fontSize: 14.0)),
            subtitle: Text(repository, style: TextStyle(fontSize: 14.0)),
            dense: true,
            onTap: () {
              openWalletOptions(repository);
            }),
      InkWell(
        child: TextField(
            enabled: false,
            controller: this._pubkey,
            maxLines: 1,
            textAlign: TextAlign.center,
            decoration: InputDecoration(),
            style: TextStyle(
                fontSize: 14.0,
                color: Colors.black,
                fontWeight: FontWeight.bold)),
        onTap: () {
          print("Ma pubkey click");
          // _keyHistory.currentState.scan();
        },
      ),
      SizedBox(height: 12),
      Form(
        key: formKey,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30),
            child: PinCodeTextField(
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
                activeFillColor: hasError ? Colors.orange : Colors.white,
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
              onCompleted: (v) async {
                print("Completed");
                final resultWallet = await readLocalWallet(v.toUpperCase());
                if (resultWallet == 'bad') {
                  errorController.add(ErrorAnimationType
                      .shake); // Triggering error shake animation
                  setState(() {
                    hasError = true;
                    pinColor = Colors.red[200];
                  });
                } else {
                  setState(() {
                    pinColor = Colors.green[200];
                  });
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
    ]));
  }

  Future getPubkeyFromDewif(_dewif, _pin) async {
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

  //   Future<bool> checkIfWalletExist(_name) async {
  //   final appPath = await _localPath;
  //   final _walletFile = File('$appPath/$_name/wallet.dewif');

  //   // deleteWallet();
  //   print(_walletFile.path);
  //   final isExist = await File(_walletFile.path).exists();
  //   print('Wallet existe ? : ' + isExist.toString());
  //   print('Is wallet generated ? : ' + walletIsGenerated.toString());
  //   if (isExist == true) {
  //     print('Un wallet existe !');
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  List getAllWalletsNames() {
    // final _appPath = await getApplicationDocumentsDirectory();
    // List _listWallets = [];
    // _listWallets.add('tortuuue');
    this._listWallets.clear();
    print(this.appPath);

    this
        .appPath
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      print(entity.path.split('/').last);
      this._listWallets.add(entity.path.split('/').last);
    });

    print('Mes wallets: ');
    print(_listWallets);
    return _listWallets;

    // final _local = await _appPath.path.list().toList();
  }

  Future openWalletOptions(_name) async {
    deleteWallet(_name);
    // getAllWalletsNames();
    // setState(() {});
    // GenerateWalletScreen(keyGenWallet: _keyGenWallet);
    // _keyGenWallet.currentState.setState(() {
    //   getAllWalletsNames();
    // });
  }

  Future readLocalWallet(String _pin) async {
    // print(pin);
    try {
      final file = await _localWallet('this.walletName');
      String _localDewif = await file.readAsString();
      String _localPubkey;

      if ((_localPubkey = await getPubkeyFromDewif(_localDewif, _pin)) !=
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

  Future<int> deleteWallet(_name) async {
    try {
      final appPath = await _localPath;
      final _walletFile = File('$appPath/wallets/$_name/wallet.dewif');

      _walletFile.delete();
      getAllWalletsNames();
      setState(() {
        // getAllWalletsNames();
      });
      return 0;
    } catch (e) {
      getAllWalletsNames();
      setState(() {
        // getAllWalletsNames();
      });
      return 1;
    }
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
