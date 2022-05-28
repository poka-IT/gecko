import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/choose_chest.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:provider/provider.dart';

class WalletsHome extends StatelessWidget {
  const WalletsHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    HomeProvider _homeProvider =
        Provider.of<HomeProvider>(context, listen: false);

    final int? _currentChestNumber = myWalletProvider.getCurrentChest();
    final ChestData _currentChest = chestBox.get(_currentChestNumber)!;
    myWalletProvider.listWallets =
        myWalletProvider.readAllWallets(_currentChestNumber);

    return WillPopScope(
      onWillPop: () {
        myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
        Navigator.popUntil(
          context,
          ModalRoute.withName('/'),
        );
        return Future<bool>.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
              }),
          title: Text(_currentChest.name!,
              key: const Key('myWallets'),
              style: TextStyle(color: Colors.grey[850])),
          backgroundColor: const Color(0xffFFD58D),
        ),
        bottomNavigationBar: _homeProvider.bottomAppBar(context, 3),
        body: SafeArea(
          child: myWalletsTiles(context, _currentChestNumber!),
        ),
      ),
    );
  }

  Widget chestOptions(
      BuildContext context, MyWalletsProvider _myWalletProvider) {
    return Column(children: [
      const SizedBox(height: 50),
      SizedBox(
          height: 90,
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
                return ChestOptions(walletProvider: _myWalletProvider);
              }),
            ),
            label: const Text(
              "    Paramétrer ce coffre",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff8a3c0f),
              ),
            ),
          )),
      const SizedBox(height: 30),
      SizedBox(
          height: 90,
          width: 420,
          child: ElevatedButton.icon(
            icon: Image.asset(
              'assets/chests/miniChests.png',
              height: 70,
            ),
            style: ElevatedButton.styleFrom(
              elevation: 2,
              primary: floattingYellow, // background
              onPrimary: Colors.black, // foreground
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return const ChooseChest();
              }),
            ),
            label: const Text(
              "     Changer de coffre",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff8a3c0f),
              ),
            ),
          )),
      const SizedBox(height: 30)
    ]);
  }

  Widget myWalletsTiles(BuildContext context, int _currentChestNumber) {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();

    if (!isWalletsExists) {
      return const Text('');
    }

    if (_myWalletProvider.listWallets.isEmpty) {
      return Expanded(
          child: Column(children: const <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        )),
      ]));
    }

    List _listWallets = _myWalletProvider.listWallets;
    WalletData? defaultWallet = _myWalletProvider.getDefaultWallet();
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
                      // _walletOptions.readLocalWallet(context, _repository,
                      //     _myWalletProvider.pinCode, pinLength);
                      _walletOptions.getAddress(
                          _currentChestNumber, _repository.derivation!);
                      Navigator.push(
                        context,
                        SmoothTransition(
                          page: WalletOptions(
                            wallet: _repository,
                          ),
                        ),
                      );

                      // Navigator.push(context,
                      //     MaterialPageRoute(builder: (context) {
                      //   return UnlockingWallet(wallet: _repository);
                      // }));
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
                                _repository.imageCustomPath == null ||
                                        _repository.imageCustomPath == ''
                                    ? Image.asset(
                                        'assets/avatars/${_repository.imageDefaultPath}',
                                        alignment: Alignment.bottomCenter,
                                        scale: 0.5,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.transparent,
                                          image: DecorationImage(
                                            fit: BoxFit.contain,
                                            image: FileImage(
                                              File(
                                                  _repository.imageCustomPath!),
                                            ),
                                          ),
                                        ),
                                      ),
                          )),
                          balanceBuilder(context, _repository.address!,
                              _repository.id()[1] == defaultWallet!.id()[1]),
                          ListTile(
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12))),
                            // contentPadding: const EdgeInsets.only(left: 7.0),
                            tileColor:
                                _repository.id()[1] == defaultWallet.id()[1]
                                    ? orangeC
                                    : const Color(0xffFFD58D),
                            // leading: Text('IMAGE'),

                            // subtitle: Text(_repository.split(':')[3],
                            //     style: TextStyle(fontSize: 12.0, fontFamily: 'Monospace')),
                            title: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  _repository.name!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 17.0,
                                      color: _repository.id()[1] ==
                                              defaultWallet.id()[1]
                                          ? const Color(0xffF9F9F1)
                                          : Colors.black,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                            // dense: true,
                            onTap: () {
                              // _walletOptions.readLocalWallet(
                              //     context,
                              //     _repository,
                              //     _myWalletProvider.pinCode,
                              //     pinLength);
                              _walletOptions.getAddress(
                                  _currentChestNumber, _repository.derivation!);
                              Navigator.push(
                                context,
                                SmoothTransition(
                                  page: WalletOptions(
                                    wallet: _repository,
                                  ),
                                ),
                              );
                            },
                          )
                        ]),
                      ),
                    ),
                  )),
            addNewDerivation(context),
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
      SliverToBoxAdapter(child: chestOptions(context, _myWalletProvider)),
    ]);
  }

  Widget balanceBuilder(context, String _address, bool isDefault) {
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
          balance(
              context, _address, 15, isDefault ? Colors.white : Colors.black)
        ]),
      ),
    );
  }

  Widget addNewDerivation(context) {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    String _newDerivationName =
        'Portefeuille ${_myWalletProvider.listWallets.last.number! + 2}';
    return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Column(children: <Widget>[
              Expanded(
                child: InkWell(
                    key: const Key('addDerivation'),
                    onTap: () async {
                      if (!_myWalletProvider.isNewDerivationLoading) {
                        await _myWalletProvider.generateNewDerivation(
                            context, _newDerivationName);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(color: floattingYellow),
                      child: Center(
                          child: _myWalletProvider.isNewDerivationLoading
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
      child: ClipRect(child: child, clipper: clipper),
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
