import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:provider/provider.dart';

class ChooseChest extends StatefulWidget {
  const ChooseChest({this.action, Key? key}) : super(key: key);
  final String? action;

  @override
  State<StatefulWidget> createState() {
    return _ChooseChestState();
  }
}

// ignore: must_be_immutable
class _ChooseChestState extends State<ChooseChest> {
  TextEditingController tplController = TextEditingController();
  CarouselController buttonCarouselController = CarouselController();
  int? currentChest = configBox.get('currentChest');

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    log.d(widget.action);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Sélectionner mon coffre'),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 160 * ratio),
            CarouselSlider(
              carouselController: buttonCarouselController,
              options: CarouselOptions(
                height: 210,
                onPageChanged: (index, reason) {
                  currentChest = chestBox.toMap().keys.toList()[index];
                  setState(() {});
                },
                enableInfiniteScroll: false,
                initialPage: currentChest!,
                enlargeCenterPage: true,
                viewportFraction: 0.5,
              ),
              items: chestBox.toMap().entries.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Column(children: <Widget>[
                      i.value.imageFile == null
                          ? Image.asset(
                              'assets/chests/${i.value.imageName}',
                              height: 150,
                            )
                          : Image.file(
                              i.value.imageFile!,
                              height: 150,
                            ),
                      const SizedBox(height: 30),
                      Text(
                        i.value.name!,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ]);
                  },
                );
              }).toList(),
            ),
            if (chestBox.values.toList().length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: chestBox.toMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () =>
                        buttonCarouselController.animateToPage(entry.key),
                    child: Container(
                      width: 12.0,
                      height: 12.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                                  .withOpacity(
                                      currentChest == entry.key ? 0.9 : 0.4)),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 80 * ratio),
            SizedBox(
              width: 400,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: orangeC, // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: () {
                  configBox.put('currentChest', currentChest);
                  WalletData? defaultWallet =
                      _myWalletProvider.getDefaultWallet();
                  _myWalletProvider.rebuildWidget();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return UnlockingWallet(
                        wallet: defaultWallet,
                        action: widget.action ?? "mywallets",
                      );
                    }),
                    ModalRoute.withName('/'),
                  );
                },
                child: Text(
                  'Ouvrir ce coffre',
                  style: TextStyle(
                      fontSize: 22,
                      color: backgroundColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // const SizedBox(height: 20),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: InkWell(
                  key: const Key('createNewChest'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return const OnboardingStepFive(skipIntro: true);
                      }),
                    );
                  },
                  child: SizedBox(
                    width: 400,
                    height: 50,
                    child: Center(
                        child: Text('Créer un nouveau coffre',
                            style: TextStyle(
                                fontSize: 22,
                                color: orangeC,
                                fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
            ),
            InkWell(
                key: const Key('importChest'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const RestoreChest(skipIntro: true);
                    }),
                  );
                },
                child: SizedBox(
                  width: 400,
                  height: 50,
                  child: Center(
                      child: Text('Importer un coffre',
                          style: TextStyle(
                              fontSize: 22,
                              color: orangeC,
                              fontWeight: FontWeight.w600))),
                )),
            const SizedBox(height: 20),
          ]),
        ));
  }
}
