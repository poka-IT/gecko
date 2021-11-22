import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/chest_provider.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:provider/provider.dart';

class ChestOptions extends StatelessWidget {
  const ChestOptions({Key keyMyWallets, @required this.walletProvider})
      : super(key: keyMyWallets);
  final MyWalletsProvider walletProvider;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    ChestProvider _chestProvider =
        Provider.of<ChestProvider>(context, listen: false);

    ChestData currentChest = chestBox.get(configBox.get('currentChest'));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          toolbarHeight: 60 * ratio,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/mywallets'),
                );
              }),
          title: SizedBox(
            height: 22,
            child: Text(currentChest.name),
          )),
      body: Builder(
        builder: (ctx) => SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 30 * ratio),
            InkWell(
              key: const Key('changePin'),
              onTap: () async {
                // await _chestProvider.changePin(context, cesiumWallet);
                String pinResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ChangePinScreen(
                        walletName: currentChest.name,
                        walletProvider: walletProvider,
                      );
                    },
                  ),
                );

                if (pinResult != null) {
                  walletProvider.pinCode = pinResult;
                }
              },
              child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 28),
                    Image.asset(
                      'assets/chests/secret_code.png',
                    ),
                    const SizedBox(width: 18),
                    const Text('Changer mon code secret',
                        style: TextStyle(fontSize: 20, color: Colors.black)),
                  ])),
            ),
            SizedBox(height: 10 * ratio),
            InkWell(
              key: const Key('deleteChest'),
              onTap: () async {
                await _chestProvider.deleteChest(context, currentChest);
              },
              child: SizedBox(
                height: 50,
                child: Row(children: <Widget>[
                  const SizedBox(width: 33),
                  Image.asset(
                    'assets/walletOptions/trash.png',
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    'Supprimer ce coffre',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xffD80000),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
