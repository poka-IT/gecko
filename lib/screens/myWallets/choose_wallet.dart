// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

class ChooseWalletScreen extends StatelessWidget {
  ChooseWalletScreen({Key? key, required this.pin}) : super(key: key);
  final String pin;
  WalletData? selectedWallet;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);
    final int chest = configBox.get('currentChest');

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: SizedBox(
              height: 22,
              child: Text('choiceOfSourceWallet'.tr()),
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
                    key: keyConfirm,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, elevation: 4, backgroundColor: orangeC, // foreground
                    ),
                    onPressed: () async {
                      await sub.setCurrentWallet(selectedWallet!);

                      // _walletViewProvider.reload();
                      sub.reload();

                      // Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'chooseThisWallet'.tr(),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ));
  }

  Widget myWalletsTiles(BuildContext context, int? currentChest) {
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();
    WalletData? defaultWallet = myWalletProvider.getDefaultWallet();

    selectedWallet ??= defaultWallet;
    myWalletProvider.readAllWallets(currentChest);

    if (!isWalletsExists) {
      return const Text('');
    }

    if (myWalletProvider.listWallets.isEmpty) {
      return Column(children: const <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        )),
      ]);
    }

    List listWallets = myWalletProvider.listWallets;
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
          key: keyListWallets,
          crossAxisCount: nTule,
          childAspectRatio: 1,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          children: <Widget>[
            for (WalletData repository in listWallets as Iterable<WalletData>)
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    key: keySelectThisWallet(repository.address!),
                    onTap: () {
                      selectedWallet = repository;
                      myWalletProvider.rebuildWidget();
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
                            child: repository.imageCustomPath == null
                                ? Image.asset(
                                    'assets/avatars/${repository.imageDefaultPath}',
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
                                          File(repository.imageCustomPath!),
                                        ),
                                      ),
                                    ),
                                  ),
                          )),
                          balanceBuilder(context, repository.address!,
                              selectedWallet!.address == repository.address!),
                          ListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            tileColor:
                                repository.address == selectedWallet!.address
                                    ? orangeC
                                    : const Color(0xffFFD58D),
                            title: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  repository.name!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 17.0,
                                      color: repository.address ==
                                              selectedWallet!.address
                                          ? const Color(0xffF9F9F1)
                                          : Colors.black,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                            onTap: () async {
                              selectedWallet = repository;
                              myWalletProvider.rebuildWidget();
                            },
                          )
                        ]),
                      ),
                    ),
                  )),
          ]),
    ]);
  }

  Widget balanceBuilder(context, String address, bool isDefault) {
    return Container(
      width: double.infinity,
      color: isDefault ? orangeC : yellowC,
      child: SizedBox(
        height: 25,
        child: Column(children: [
          const Spacer(),
          // Text(
          //   '0.0 gd',
          //   textAlign: TextAlign.center,
          //   style: TextStyle(color: isDefault ? Colors.white : Colors.black),
          // ),
          balance(context, address, 15, isDefault ? Colors.white : Colors.black)
        ]),
      ),
    );
  }
}
