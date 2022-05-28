import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChooseWalletScreen extends StatelessWidget {
  ChooseWalletScreen({Key? key, required this.chest, required this.pin})
      : super(key: key);
  final int chest;
  final String pin;
  WalletData? selectedWallet;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Choix du portefeuille source'),
            )),
        body: SafeArea(
          child: Stack(children: [
            myWalletsTiles(context, chest),
            Positioned.fill(
              bottom: 60,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 470,
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      primary: orangeC, // background
                      onPrimary: Colors.white, // foreground
                    ),
                    onPressed: () async {
                      await _sub.setCurrentWallet(selectedWallet!);

                      // _walletViewProvider.reload();
                      _sub.reload();

                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Choisir ce portefeuille',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ));
  }

  Widget myWalletsTiles(BuildContext context, int? currentChest) {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();
    WalletData? defaultWallet = _myWalletProvider.getDefaultWallet();

    selectedWallet ??= defaultWallet!;
    _myWalletProvider.readAllWallets(currentChest);

    if (!isWalletsExists) {
      return const Text('');
    }

    if (_myWalletProvider.listWallets.isEmpty) {
      return Column(children: const <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        )),
      ]);
    }

    List _listWallets = _myWalletProvider.listWallets;
    final double screenWidth = MediaQuery.of(context).size.width;
    int nTule = 2;

    if (screenWidth >= 900) {
      nTule = 4;
    } else if (screenWidth >= 650) {
      nTule = 3;
    }

    return CustomScrollView(slivers: <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      SliverGrid.count(
          key: const Key('listWallets'),
          crossAxisCount: nTule,
          childAspectRatio: 1,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          children: <Widget>[
            for (WalletData _repository in _listWallets as Iterable<WalletData>)
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () {
                      selectedWallet = _repository;
                      _myWalletProvider.rebuildWidget();
                    },
                    child: ClipOvalShadow(
                      shadow: const Shadow(
                        color: Colors.transparent,
                        offset: Offset(0, 0),
                        blurRadius: 5,
                      ),
                      clipper: CustomClipperOval(),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        child: Column(children: <Widget>[
                          Expanded(
                              child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                                gradient: RadialGradient(
                              radius: 0.6,
                              colors: [
                                Colors.green[400]!,
                                const Color(0xFFE7E7A6),
                              ],
                            )),
                            child: _repository.imageCustomPath == null
                                ? Image.asset(
                                    'assets/avatars/${_repository.imageDefaultPath}',
                                    alignment: Alignment.bottomCenter,
                                    scale: 0.5,
                                  )
                                : Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                      image: DecorationImage(
                                        fit: BoxFit.contain,
                                        image: FileImage(
                                          File(_repository.imageCustomPath!),
                                        ),
                                      ),
                                    ),
                                  ),
                          )),
                          ListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            tileColor:
                                _repository.address == selectedWallet!.address
                                    ? orangeC
                                    : const Color(0xffFFD58D),
                            title: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  _repository.name!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 17.0,
                                      color: _repository.address ==
                                              selectedWallet!.address
                                          ? const Color(0xffF9F9F1)
                                          : Colors.black,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                            onTap: () async {
                              selectedWallet = _repository;
                              _myWalletProvider.rebuildWidget();
                            },
                          )
                        ]),
                      ),
                    ),
                  )),
          ]),
    ]);
  }
}
