import 'package:gecko/ui/myWallets/generateWalletsScreen.dart';
import 'package:gecko/ui/myWallets/myWalletsList.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class WalletsHome extends StatefulWidget {
  const WalletsHome({Key keyGenWallet}) : super(key: keyGenWallet);
  @override
  WalletsHomeState createState() => WalletsHomeState();
}

class WalletsHomeState extends State<WalletsHome> {
  GlobalKey<WalletsHomeState> _keyWalletsHome = GlobalKey();
  // GlobalKey<MyWalletState> _keyMyWallets = GlobalKey();
  // GlobalKey<ValidStoreWalletState> _keyValidWallets = GlobalKey();
  void initState() {
    super.initState();
    DubpRust.setup();
    getAppDirectory();
    // _keyWalletsHome.currentState.getAllWalletsNames();
    // _keyMyWallets.currentState.getAllWalletsNames();
  }

  String generatedMnemonic;
  bool walletIsGenerated = false;
  NewWallet actualWallet;
  String newWalletName;

  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];
  Directory appPath;

  @override
  Widget build(BuildContext context) {
    // getAppDirectory();
    return Scaffold(
        floatingActionButton: Visibility(
            visible:
                (checkIfWalletExist()), //!checkIfWalletExist('MonWallet') &&
            child: Container(
                height: 80.0,
                width: 80.0,
                child: FittedBox(
                    child: FloatingActionButton(
                        heroTag: "buttonGenerateWallet",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return GenerateWalletsScreen();
                            }),
                          ).then((value) => setState(() {
                                this.newWalletName = value;
                                checkIfWalletExist();
                              }));
                        },
                        child: Container(
                            height: 40.0,
                            width: 40.0,
                            child: Icon(Icons.person_add_alt_1_rounded)),
                        backgroundColor: Color(0xffEFEFBF))))),
        body: SafeArea(
            child: Column(children: <Widget>[
          Visibility(
              visible: (!checkIfWalletExist() && !walletIsGenerated),
              child: Column(children: <Widget>[
                SizedBox(height: 120),
                Center(
                    child: Text("Vous n'avez encore généré aucun portefeuille.",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center)),
                SizedBox(height: 80),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xffFFD68E), // background
                      onPrimary: Colors.black, // foreground
                    ),
                    onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return GenerateWalletsScreen();
                          }),
                        ).then((value) => setState(() {
                              this.newWalletName = value;
                              checkIfWalletExist();
                            })),
                    child: Text('Générer un portefeuille',
                        style: TextStyle(fontSize: 20))),
                SizedBox(height: 15),
                Center(
                    child: Text("ou",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center)),
                SizedBox(height: 15),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xffFFD68E), // background
                      onPrimary: Colors.black, // foreground
                    ),
                    onPressed: () => importWallet(),
                    child: Text('Importer un portefeuille existant',
                        style: TextStyle(fontSize: 20))),
              ])),
          Visibility(
              visible: checkIfWalletExist(),
              child: MyWalletsList(keyMyWallets: _keyWalletsHome))
        ])));
  }

  // Future resetWalletState() async {
  //   final bool _isExist = await checkIfWalletExist('MonWallet');
  //   print('The wallet exist in resetWalletState(): ' + _isExist.toString());
  //   // initState();
  //   // _keyMyWallets.currentState.setState(() {});
  //   // _keyMyWallets.currentState.initAppDirectory();
  //   setState(() {
  //     // getAllWalletsNames();
  //     // this.walletIsGenerated = true;
  //   });
  // }

  bool checkIfWalletExist() {
    if (this.appPath == null) {
      return false;
    }

    var walletsFolder = new Directory("${this.appPath.path}/wallets/");

    bool isWalletFolderExist = walletsFolder.existsSync();

    if (!isWalletFolderExist) {
      Directory(walletsFolder.path).createSync();
    }

    List contents = walletsFolder.listSync();
    if (contents.length == 0) {
      print('No wallets detected');
      return false;
    } else {
      print('Some wallets have been detected:');
      for (var _wallets in contents) {
        print(_wallets);
      }
      return true;
    }

    // final bool isExist =
    //     File('${walletsFolder.path}/$name/wallet.dewif').existsSync();
    // print(this.appPath.path);
    // print('Wallet existe ? : ' + isExist.toString());
    // print('Is wallet generated ? : ' + walletIsGenerated.toString());
    // if (isExist) {
    //   print('Un wallet existe !');
    //   return true;
    // } else {
    //   return false;
    // }
  }

  Future getAppDirectory() async {
    this.appPath = await getApplicationDocumentsDirectory();
    setState(() {});
  }

  Future importWallet() async {}
}
