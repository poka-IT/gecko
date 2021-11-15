import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

class ChooseChest extends StatefulWidget {
  const ChooseChest({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChooseChestState();
  }
}

// ignore: must_be_immutable
class _ChooseChestState extends State<ChooseChest> {
  TextEditingController tplController = TextEditingController();
  CarouselController buttonCarouselController = CarouselController();
  int currentChest = configBox.get('currentChest');

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    return Scaffold(
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
                  currentChest = index;
                  setState(() {});
                },
                enableInfiniteScroll: false,
                initialPage: currentChest,
                enlargeCenterPage: true,
                viewportFraction: 0.6,
              ),
              items: chestBox.toMap().entries.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Column(children: <Widget>[
                      Image.asset(
                        'assets/chests/${i.value.imageName}',
                        height: 150,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        i.value.name,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ]);
                  },
                );
              }).toList(),
            ),
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
                        color: (Theme.of(context).brightness == Brightness.dark
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
                  WalletData defaultWallet =
                      _myWalletProvider.getDefaultWallet(currentChest);
                  _myWalletProvider.rebuildWidget();
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (context) {
                    return UnlockingWallet(
                      wallet: defaultWallet,
                      action: "mywallets",
                    );
                  }), ModalRoute.withName('/'));
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
            const SizedBox(height: 20),
            InkWell(
                key: const Key('createNewChest'),
                onTap: () {
                  Navigator.push(
                    context,
                    FaderTransition(page: OnboardingStepOne(), isFast: false),
                  );
                },
                child: SizedBox(
                  width: 400,
                  height: 70,
                  child: Center(
                      child: Text('Créer un nouveau coffre',
                          style: TextStyle(
                              fontSize: 22,
                              color: orangeC,
                              fontWeight: FontWeight.w600))),
                )),
            const SizedBox(height: 10),
          ]),
        ));
  }
}
