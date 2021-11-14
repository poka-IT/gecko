import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChooseChest extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  CarouselController buttonCarouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    int currentChest = configBox.get('currentChest');

    return Scaffold(
        appBar: AppBar(
            title: SizedBox(
          height: 22,
          child: Text('Sélectionner mon coffre'),
        )),
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 190),
            CarouselSlider(
              carouselController: buttonCarouselController,
              options: CarouselOptions(
                height: 210,
                onPageChanged: (index, reason) {
                  currentChest = index;
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
                      ),
                      SizedBox(height: 30),
                      Text(
                        i.value.name,
                        style: TextStyle(fontSize: 21),
                      ),
                    ]);
                  },
                );
              }).toList(),
            ),
            Image.asset('assets/chests/vector.png'),
            SizedBox(height: 15),
            Text(
              'Choisir un autre\ncoffre',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 80),
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
                  _myWalletProvider.rebuildWidget();
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/mywallets'),
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
            SizedBox(height: 20),
            InkWell(
                key: Key('createNewChest'),
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
            SizedBox(height: 10),
          ]),
        ));
  }
}
