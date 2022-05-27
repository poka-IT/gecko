import 'package:flutter/material.dart';
import 'package:durt/durt.dart';
import 'package:flutter/services.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'dart:io';
// import 'package:gecko/screens/myWallets/import_cesium_wallet.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class SettingsScreen extends StatelessWidget {
  String? generatedMnemonic;
  bool walletIsGenerated = false;
  NewWallet? actualWallet;
  String? newWalletName;

  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];
  Directory? appPath;

  final MyWalletsProvider _myWallets = MyWalletsProvider();

  SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    const double buttonHigh = 50;
    const double buttonWidth = 240;
    const double fontSize = 16;
    TextEditingController _endpointController =
        TextEditingController(text: configBox.get('endpoint').first);

    // getAppDirectory();
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text('Paramètres'),
          )),
      body: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 60),
            Row(children: [
              Text(' Noeud $currencyName :'),
              const SizedBox(width: 20),
              SizedBox(
                width: 200,
                height: 50,
                child: TextField(
                  controller: _endpointController,
                  autocorrect: false,
                ),
              ),
              const Spacer(),
              Consumer<SubstrateSdk>(builder: (context, _sub, _) {
                return _sub.isLoadingEndpoint
                    ? CircularProgressIndicator(color: orangeC)
                    : IconButton(
                        icon: Icon(
                          Icons.send,
                          color: orangeC,
                          size: 40,
                        ),
                        onPressed: () async {
                          configBox.put('endpoint', [_endpointController.text]);
                          await _sub.connectNode(context);
                        });
              }),
              const Spacer(),
            ]),
            SizedBox(height: isTall ? 50 : 20),
            SizedBox(
              height: buttonHigh,
              width: buttonWidth,
              child: ElevatedButton(
                key: const Key('generateKeychain'),
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  primary: yellowC, // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return const OnboardingStepFive(skipIntro: true);
                  }),
                ),
                child: const Text(
                  "Générer un coffre",
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: buttonHigh,
              width: buttonWidth,
              child: ElevatedButton(
                key: const Key('generateKeychain'),
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  primary: yellowC, // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return const RestoreChest(skipIntro: true);
                  }),
                ),
                child: const Text(
                  "Restaurer un coffre",
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: buttonHigh,
              width: buttonWidth,
              child: Center(
                child: InkWell(
                  key: const Key('deleteChest'),
                  onTap: () async {
                    log.i('Oublier tous mes coffres');
                    await _myWallets.deleteAllWallet(context);
                  },
                  child: const Text(
                    'Oublier tous mes coffres',
                    style: TextStyle(
                      fontSize: fontSize + 3,
                      color: Color(0xffD80000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ]),
    );
  }
}
