import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/choose_chest.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:provider/provider.dart';

class WalletsHome extends StatelessWidget {
  const WalletsHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    HomeProvider homeProvider =
        Provider.of<HomeProvider>(context, listen: false);

    final int currentChestNumber = myWalletProvider.getCurrentChest();
    final ChestData currentChest = chestBox.get(currentChestNumber)!;
    myWalletProvider.listWallets =
        myWalletProvider.readAllWallets(currentChestNumber);

    return WillPopScope(
      onWillPop: () {
        // myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
        Navigator.popUntil(
          context,
          ModalRoute.withName('/'),
        );
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                // myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
              }),
          title: Text(currentChest.name!,
              style: TextStyle(color: Colors.grey[850])),
          backgroundColor: const Color(0xffFFD58D),
        ),
        bottomNavigationBar: homeProvider.bottomAppBar(context),
        body: SafeArea(
          child: Stack(children: [
            myWalletsTiles(context, currentChestNumber),
            CommonElements().offlineInfo(context),
          ]),
        ),
      ),
    );
  }

  Widget chestOptions(
      BuildContext context, MyWalletsProvider myWalletProvider) {
    return Column(children: [
      const SizedBox(height: 50),
      SizedBox(
          height: 80,
          width: 420,
          child: ElevatedButton.icon(
            icon: Image.asset(
              'assets/chests/config.png',
              height: 60,
            ),
            style: ElevatedButton.styleFrom(
              elevation: 2,
              primary: floattingYellow, // background
              onPrimary: Colors.black, // foreground
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return ChestOptions(walletProvider: myWalletProvider);
              }),
            ),
            label: Text(
              "   ${"manageChest".tr()}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff8a3c0f),
              ),
            ),
          )),
      const SizedBox(height: 30),
      InkWell(
        key: keyImportG1v1,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const ImportG1v1();
            }),
          );
        },
        child: SizedBox(
          width: 400,
          height: 60,
          child: Center(
              child: Text('importG1v1'.tr(),
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500))),
        ),
      ),
      const SizedBox(height: 5),
      InkWell(
        key: keyChangeChest,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const ChooseChest();
            }),
          );
        },
        child: SizedBox(
          width: 400,
          height: 60,
          child: Center(
              child: Text('changeChest'.tr(),
                  style: TextStyle(
                      fontSize: 22,
                      color: orangeC,
                      fontWeight: FontWeight.w500))),
        ),
      ),
      const SizedBox(height: 30)
    ]);
  }

  Widget myWalletsTiles(BuildContext context, int currentChestNumber) {
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletOptionsProvider walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

    if (!isWalletsExists) {
      return const Text('');
    }

    if (myWalletProvider.listWallets.isEmpty) {
      return Expanded(
          child: Column(children: const <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        )),
      ]));
    }

    List listWallets = myWalletProvider.listWallets;
    WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
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
                    key: keyOpenWallet(repository.address!),
                    onTap: () {
                      walletOptions.getAddress(
                          currentChestNumber, repository.derivation!);
                      Navigator.push(
                        context,
                        SmoothTransition(
                          page: WalletOptions(
                            wallet: repository,
                          ),
                        ),
                      );
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
                            child:
                                // SvgPicture.asset('assets/chopp-gecko2.png',
                                //         semanticsLabel: 'Gecko', height: 48),
                                repository.imageCustomPath == null ||
                                        repository.imageCustomPath == ''
                                    ? Image.asset(
                                        'assets/avatars/${repository.imageDefaultPath}',
                                        alignment: Alignment.bottomCenter,
                                        scale: 0.5,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.transparent,
                                          image: DecorationImage(
                                            fit: BoxFit.fitHeight,
                                            image: FileImage(
                                              File(repository.imageCustomPath!),
                                            ),
                                          ),
                                        ),
                                      ),
                          )),
                          Stack(children: <Widget>[
                            balanceBuilder(context, repository.address!,
                                repository.address == defaultWallet.address),
                            nameBuilder(context, repository, defaultWallet,
                                currentChestNumber),
                          ]),
                        ]),
                      ),
                    ),
                  )),
            Consumer<SubstrateSdk>(builder: (context, sub, _) {
              return sub.nodeConnected
                  ? addNewDerivation(context)
                  : const Text('');
            }),
            // SizedBox(height: 1),
            // Padding(
            //     padding: EdgeInsets.symmetric(horizontal: 35),
            //     child: Text(
            //       'Ajouter un portefeuille',
            //       textAlign: TextAlign.center,
            //       style: TextStyle(fontSize: 18),
            //     ))
          ]),
      // SliverToBoxAdapter(child: Spacer()),
      SliverToBoxAdapter(child: chestOptions(context, myWalletProvider)),
    ]);
  }

  Widget balanceBuilder(context, String address, bool isDefault) {
    return Container(
      width: double.infinity,
      color: isDefault ? orangeC : yellowC,
      child: Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, top: 38),
          child: balance(
              context,
              address,
              15,
              isDefault ? Colors.white : Colors.black,
              isDefault ? yellowC : orangeC)),
    );
  }

  Widget nameBuilder(BuildContext context, WalletData repository,
      WalletData defaultWallet, int currentChestNumber) {
    WalletOptionsProvider walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    DuniterIndexer duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);
    return ListTile(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
      // contentPadding: const EdgeInsets.only(left: 7.0),
      tileColor: repository.address == defaultWallet.address
          ? orangeC
          : const Color(0xffFFD58D),
      // leading: Text('IMAGE'),

      // subtitle: Text(_repository.split(':')[3],
      //     style: TextStyle(fontSize: 12.0, fontFamily: 'Monospace')),
      title: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 35, top: 5),
          child: duniterIndexer.getNameByAddress(
              context,
              repository.address!,
              repository,
              20,
              true,
              repository.id()[1] == defaultWallet.id()[1]
                  ? const Color(0xffF9F9F1)
                  : Colors.black),
        ),
      ),
      // dense: true,
      onTap: () {
        // _walletOptions.readLocalWallet(
        //     context,
        //     _repository,
        //     _myWalletProvider.pinCode,
        //     pinLength);
        walletOptions.getAddress(currentChestNumber, repository.derivation!);
        Navigator.push(
          context,
          SmoothTransition(
            page: WalletOptions(
              wallet: repository,
            ),
          ),
        );
      },
    );
  }

  Widget addNewDerivation(context) {
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    String newDerivationName =
        '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number! + 2}';
    return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Column(children: <Widget>[
              Expanded(
                child: InkWell(
                    key: keyAddDerivation,
                    onTap: () async {
                      if (!myWalletProvider.isNewDerivationLoading) {
                        WalletData? defaultWallet =
                            myWalletProvider.getDefaultWallet();
                        String? pin;
                        if (myWalletProvider.pinCode == '') {
                          pin = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (homeContext) {
                                return UnlockingWallet(wallet: defaultWallet);
                              },
                            ),
                          );
                        }
                        if (pin != null || myWalletProvider.pinCode != '') {
                          await myWalletProvider.generateNewDerivation(
                              context, newDerivationName);
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(color: floattingYellow),
                      child: Center(
                          child: myWalletProvider.isNewDerivationLoading
                              ? SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: CircularProgressIndicator(
                                    color: orangeC,
                                    strokeWidth: 7,
                                  ),
                                )
                              : const Text(
                                  '+',
                                  style: TextStyle(
                                      fontSize: 150,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFCB437)),
                                )),
                    )),
              ),
            ])));
  }
}

// extension Range on num {
//   bool isBetween(num from, num to) {
//     return from < this && this < to;
//   }
// }

class CustomClipperOval extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromCircle(
        center: Offset(size.width / 2, size.width / 2),
        radius: size.width / 2 + 3);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }
}

class ClipOvalShadow extends StatelessWidget {
  final Shadow shadow;
  final CustomClipper<Rect> clipper;
  final Widget child;

  const ClipOvalShadow({
    Key? key,
    required this.shadow,
    required this.clipper,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClipOvalShadowPainter(
        clipper: clipper,
        shadow: shadow,
      ),
      child: ClipRect(clipper: clipper, child: child),
    );
  }
}

class _ClipOvalShadowPainter extends CustomPainter {
  final Shadow shadow;
  final CustomClipper<Rect> clipper;

  _ClipOvalShadowPainter({required this.shadow, required this.clipper});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = shadow.toPaint();
    var clipRect = clipper.getClip(size).shift(const Offset(0, 0));
    canvas.drawOval(clipRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
