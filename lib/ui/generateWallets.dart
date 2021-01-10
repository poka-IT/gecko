import 'package:gecko/ui/myWallets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class GenerateWalletScreen extends StatefulWidget {
  @override
  _GenerateWalletState createState() => _GenerateWalletState();
}

class _GenerateWalletState extends State<GenerateWalletScreen> {
  void initState() {
    super.initState();
    DubpRust.setup();
  }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();
  String generatedMnemonic;
  bool walletIsGenerated = false;
  NewWallet actualWallet;
  final formKey = GlobalKey<FormState>();

  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Container(
          height: 80.0,
          width: 80.0,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: "buttonGenerateWallet",
              onPressed: () async {
                await generateMnemonic();
                // print(resultScan);
                // if (resultScan != 'false') {
                //   onTabTapped(0);
                // }
              },
              child: Container(
                  height: 40.0,
                  width: 40.0,
                  child: Icon(Icons.person_add_alt_1_rounded)),
              backgroundColor: Color(
                  0xffEFEFBF), //Color(0xffFFD68E), //Color.fromARGB(500, 204, 255, 255),
            ),
          ),
        ),
        body: SafeArea(
            child: Column(children: <Widget>[
          FutureBuilder<bool>(
              future: checkIfWalletExist(),
              builder: (context, fSnapshot) {
                if (fSnapshot.hasData)
                  return Visibility(
                      visible: (!fSnapshot.data && !walletIsGenerated),
                      child: Column(children: <Widget>[
                        SizedBox(height: 80),
                        Center(
                            child: Text(
                                "Vous n'avez encore généré aucun portefeuille.",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center)),
                        SizedBox(height: 50),
                        RaisedButton(
                            color: Color(0xffFFD68E),
                            onPressed: () => generateMnemonic(),
                            child: Text('Générer un portefeuille',
                                style: TextStyle(fontSize: 20))),
                        SizedBox(height: 15),
                        Center(
                            child: Text("ou",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center)),
                        SizedBox(height: 15),
                        RaisedButton(
                            color: Color(0xffFFD68E),
                            onPressed: () => importWallet(),
                            child: Text('Importer un portefeuille existant',
                                style: TextStyle(fontSize: 20))),
                      ])); // WelcomeWalletScreen());
                return Center(child: CircularProgressIndicator());
              }),
          FutureBuilder<bool>(
              future: checkIfWalletExist(),
              builder: (context, fSnapshot) {
                if (fSnapshot.hasData)
                  return Visibility(
                      visible: fSnapshot.data, child: MyWalletsScreen());
                return Center(child: CircularProgressIndicator());
              }),
          SizedBox(height: 8),
          Visibility(
            visible: walletIsGenerated,
            child: Column(children: <Widget>[
              Text(
                'Clé publique:',
                style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
              TextField(
                  enabled: false,
                  controller: this._pubkey,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(),
                  style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'Phrase de restauration:',
                style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
              TextField(
                  enabled: false,
                  controller: this._mnemonicController,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(15.0),
                  ),
                  style: TextStyle(
                      fontSize: 22.0,
                      color: Colors.black,
                      fontWeight: FontWeight.w400)),
              SizedBox(height: 8),
              Text(
                'Code secret:',
                style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
              TextField(
                  enabled: false,
                  controller: this._pin,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(),
                  style: TextStyle(
                      fontSize: 30.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              // Expanded(child: Align(alignment: Alignment.bottomCenter)),
              new RaisedButton(
                  color: Color(0xffFFD68E),
                  onPressed: walletIsGenerated
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return ValidStoreWalletScreen(
                                  generatedMnemonic: this.generatedMnemonic,
                                  generatedWallet: this.actualWallet);
                            }),
                          ).then((value) => setState(() {
                                print(
                                    'TODO: Fix error null boolean ?'); //TODO: Fix error null boolean
                                if (value) {
                                  _pin.clear();
                                  _mnemonicController.clear();
                                  _pubkey.clear();
                                  this.generatedMnemonic = null;
                                  this.actualWallet = null;
                                  this.walletIsGenerated = false;
                                }
                              }));
                        }
                      : null,
                  child: Text('Enregistrer ce wallet',
                      style: TextStyle(fontSize: 20))),
              SizedBox(height: 20)
            ]),
//           Visibility(
//             visible: walletIsGenerated,
//             child: Text("""
//     Notez bien votre phrase de restauration sur un papier ou imprimez le, ainsi que votre code secret, que vous devrez retenir.
// Pour payer ou manipuler votre wallet, seul votre code secret vous sera nécessaire.
// Votre phrase de restauration quant à elle, constitué de 12 mots, vous permet de restaurer votre wallet sur un autre appareil. Gardez la précieusement, en lieu sûr.
//             """,
//                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center),
//           )
          )
        ])));
  }

  Future generateMnemonic() async {
    try {
      this.generatedMnemonic =
          await DubpRust.genMnemonic(language: Language.french);
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }
    this.actualWallet = await generateWallet(this.generatedMnemonic);
    this.walletIsGenerated = true;
    // await checkIfWalletExist();
    return this.generatedMnemonic;
  }

  Future generateWallet(generatedMnemonic) async {
    try {
      this.actualWallet = await DubpRust.genWalletFromMnemonic(
          language: Language.french,
          mnemonic: generatedMnemonic,
          secretCodeType: SecretCodeType.letters);
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }

    setState(() {
      this._mnemonicController.text = generatedMnemonic;
      this._pubkey.text = actualWallet.publicKey;
      this._pin.text = actualWallet.pin;
    });

    return actualWallet;
  }

  Future<bool> checkIfWalletExist() async {
    // deleteWallet();
    final _walletFile = await _localWallet;
    // final isExist = File(_walletFile.toString()).existsSync();
    print(_walletFile.path);
    final isExist = await File(_walletFile.path).exists();
    print('Wallet existe ? : ' + isExist.toString());
    print('Is wallet generated ? : ' + walletIsGenerated.toString());
    if (isExist == true) {
      print('Un wallet existe !');
      return true;
    } else {
      return false;
    }
  }

  Future importWallet() async {}

  Future<int> deleteWallet() async {
    try {
      final _walletFile = await _localWallet;

      await _walletFile.delete();
    } catch (e) {
      return 1;
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localWallet async {
    // /data/user/0/com.example.gecko/app_flutter/wallet.dewif
    final path = await _localPath;
    return File('$path/wallet.dewif');
  }
}

/* *** ValidStoreWalletScreen Class *** */

class ValidStoreWalletScreen extends StatefulWidget {
  final String generatedMnemonic;
  final NewWallet generatedWallet;

  ValidStoreWalletScreen(
      {Key validationKey,
      @required this.generatedMnemonic,
      @required this.generatedWallet})
      : super(key: validationKey);

  @override
  _ValidStoreWalletScreen createState() => _ValidStoreWalletScreen();
}

class _ValidStoreWalletScreen extends State<ValidStoreWalletScreen> {
  void initState() {
    super.initState();
    // DubpRust.setup();
    this._mnemonicController.text = widget.generatedMnemonic;
    this._pubkey.text = widget.generatedWallet.publicKey;
  }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(children: <Widget>[
          TextField(
              enabled: false,
              controller: this._mnemonicController,
              maxLines: 2,
              textAlign: TextAlign.center,
              decoration: InputDecoration(),
              style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold)),
          TextField(
              enabled: false,
              controller: this._pubkey,
              maxLines: 1,
              textAlign: TextAlign.center,
              decoration: InputDecoration(),
              style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold)),
          new RaisedButton(
              color: Color(0xffFFD68E),
              onPressed: () => storeWallet(),
              child: Text('Confirmer', style: TextStyle(fontSize: 20))),
        ]),
      ),
    );
  }

  Future storeWallet() async {
    final walletFile = await _localWallet;
    walletFile.writeAsString('${widget.generatedWallet.dewif}');
    _pin.clear();
    Navigator.pop(context, true);
    FocusScope.of(context).unfocus();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localWallet async {
    final path = await _localPath;
    return File('$path/wallet.dewif');
  }
}
