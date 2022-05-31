import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:gecko/screens/myWallets/show_seed.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:provider/provider.dart';

class ChestOptions extends StatelessWidget {
  const ChestOptions({Key? keyMyWallets, required this.walletProvider})
      : super(key: keyMyWallets);
  final MyWalletsProvider walletProvider;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    ChestProvider _chestProvider =
        Provider.of<ChestProvider>(context, listen: false);
    HomeProvider _homeProvider =
        Provider.of<HomeProvider>(context, listen: false);

    ChestData currentChest = chestBox.get(configBox.get('currentChest'))!;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          // leading: IconButton(
          //     icon: const Icon(Icons.arrow_back, color: Colors.black),
          //     onPressed: () {
          //       // Navigator.popUntil(
          //       //   context,
          //       //   ModalRoute.withName('/mywallets'),
          //       // );
          //       Navigator.pop(context);
          //     }),
          title: SizedBox(
            height: 22,
            child: Text(currentChest.name!),
          )),
      bottomNavigationBar: _homeProvider.bottomAppBar(context),
      body: Builder(
        builder: (ctx) => SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 30 * ratio),
            InkWell(
              key: const Key('showSeed'),
              onTap: () async {
                MyWalletsProvider _myWalletProvider =
                    Provider.of<MyWalletsProvider>(context, listen: false);
                WalletData? defaultWallet =
                    _myWalletProvider.getDefaultWallet();
                String? _pin;
                if (_myWalletProvider.pinCode == '') {
                  _pin = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (homeContext) {
                        return UnlockingWallet(wallet: defaultWallet);
                      },
                    ),
                  );
                }
                if (_pin != null || _myWalletProvider.pinCode != '') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return ShowSeed(
                        walletName: currentChest.name,
                        walletProvider: walletProvider,
                      );
                    }),
                  );
                }
              },
              child: SizedBox(
                height: 50,
                child: Row(children: <Widget>[
                  const SizedBox(width: 20),
                  Image.asset(
                    'assets/onBoarding/phrase_de_restauration_flou.png',
                    width: 60,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'Afficher ma phrase de restauration',
                    style: TextStyle(
                      fontSize: 20,
                      color: orangeC,
                    ),
                  ),
                ]),
              ),
            ),
            SizedBox(height: 10 * ratio),
            InkWell(
              key: const Key('changePin'),
              onTap: () async {
                // await _chestProvider.changePin(context, cesiumWallet);
                String? pinResult = await Navigator.push(
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
                      height: 25,
                    ),
                    const SizedBox(width: 18),
                    const Text(
                      'Changer mon code secret',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
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
                  const SizedBox(width: 30),
                  Image.asset(
                    'assets/walletOptions/trash.png',
                    height: 45,
                  ),
                  const SizedBox(width: 20),
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
