import 'package:gecko/ui/myWallets/confirmWalletStorage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'package:dubp/dubp.dart';

class GenerateWalletsScreen extends StatefulWidget {
  const GenerateWalletsScreen({Key keyGenWallet}) : super(key: keyGenWallet);
  @override
  GenerateWalletsState createState() => GenerateWalletsState();
}

class GenerateWalletsState extends State<GenerateWalletsScreen> {
  // GlobalKey<MyWalletState> _keyMyWallets = GlobalKey();
  // GlobalKey<ValidStoreWalletState> _keyValidWallets = GlobalKey();
  void initState() {
    super.initState();
    DubpRust.setup();
    generateMnemonic();
  }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();
  String generatedMnemonic;
  bool walletIsGenerated = false;
  NewWallet actualWallet;
  // final formKey = GlobalKey<FormState>();

  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        floatingActionButton: Container(
            height: 80.0,
            width: 80.0,
            child: FittedBox(
                child: FloatingActionButton(
              heroTag: "buttonGenerateWallet",
              onPressed: () => generateMnemonic(),
              // print(resultScan);
              // if (resultScan != 'false') {
              //   onTabTapped(0);
              // }
              child: Container(
                  height: 40.0, width: 40.0, child: Icon(Icons.replay)),
              backgroundColor: Color(
                  0xffEFEFBF), //Color(0xffFFD68E), //Color.fromARGB(500, 204, 255, 255),
            ))),
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 20),
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
            SizedBox(height: 20),
            // Expanded(child: Align(alignment: Alignment.bottomCenter)),
            new ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Color(0xffFFD68E), // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: walletIsGenerated
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return ConfirmStoreWallet(
                                // validationKey: _keyValidWallets,
                                generatedMnemonic: this.generatedMnemonic,
                                generatedWallet: this.actualWallet);
                          }),
                        )
                            // .then((value) => setState(() {
                            //       if (value != null) {
                            //         _pin.clear();
                            //         _mnemonicController.clear();
                            //         _pubkey.clear();
                            //         this.generatedMnemonic = null;
                            //         this.actualWallet = null;
                            //         this.walletIsGenerated = false;
                            //       }
                            //     }))
                            ;
                      }
                    : null,
                child: Text('Enregistrer ce portefeuille',
                    style: TextStyle(fontSize: 20))),
            SizedBox(height: 20)
          ]),
        ));
  }

  Future generateMnemonic() async {
    try {
      this.generatedMnemonic =
          await DubpRust.genMnemonic(language: Language.french);
      this.actualWallet = await generateWallet(this.generatedMnemonic);
      this.walletIsGenerated = true;
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }
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
}
