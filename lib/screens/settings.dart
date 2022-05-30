import 'package:flutter/material.dart';
import 'package:durt/durt.dart';
import 'package:flutter/services.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'dart:io';
import 'package:gecko/globals.dart';
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
      backgroundColor: backgroundColor,
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
              Consumer<SubstrateSdk>(builder: (context, _sub, _) {
                return Expanded(
                  child: Row(children: [
                    Text(' Noeud $currencyName :'),
                    const Spacer(),
                    Icon(_sub.nodeConnected && !_sub.isLoadingEndpoint
                        ? Icons.check
                        : Icons.close),
                    const Spacer(),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: TextField(
                        controller: _endpointController,
                        autocorrect: false,
                      ),
                    ),
                    const Spacer(flex: 5),
                    _sub.isLoadingEndpoint
                        ? CircularProgressIndicator(color: orangeC)
                        : IconButton(
                            icon: Icon(
                              Icons.send,
                              color: orangeC,
                              size: 40,
                            ),
                            onPressed: () async {
                              configBox
                                  .put('endpoint', [_endpointController.text]);
                              await _sub.connectNode(context);
                            }),
                    const Spacer(flex: 8),
                  ]),
                );
              }),
            ]),
            // SizedBox(height: isTall ? 80 : 120),
            const Spacer(),
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
                      fontSize: fontSize + 4,
                      color: Color(0xffD80000),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // const Spacer(),
            SizedBox(height: isTall ? 90 : 60),
          ]),
    );
  }
}
