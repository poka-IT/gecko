// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:provider/provider.dart';

class ChooseChest extends StatefulWidget {
  const ChooseChest({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChooseChestState();
  }
}

class _ChooseChestState extends State<ChooseChest> {
  final tplController = TextEditingController();
  CarouselController buttonCarouselController = CarouselController();
  int? currentChest = configBox.get('currentChest');

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: scaleSize(57), title: Text('selectMyChest'.tr())),
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 160),
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
            const SizedBox(height: 80),
            SizedBox(
              width: 400,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: orangeC,
                ),
                onPressed: () async {
                  await configBox.put('currentChest', currentChest);
                  myWalletProvider.pinCode = '';
                  WalletData? defaultWallet =
                      myWalletProvider.getDefaultWallet();
                  myWalletProvider.reload();

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (homeContext) {
                        return UnlockingWallet(wallet: defaultWallet);
                      },
                    ),
                  );
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/'),
                  );
                  if (myWalletProvider.pinCode != '') {
                    Navigator.pushNamed(context, '/mywallets');
                  }
                },
                child: Text(
                  'openThisChest'.tr(),
                  style: const TextStyle(
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
                  key: keyCreateNewChest,
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
                        child: Text('createChest'.tr(),
                            style: const TextStyle(
                                fontSize: 22,
                                color: orangeC,
                                fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
            ),
            InkWell(
                key: keyImportChest,
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
                      child: Text('importChest'.tr(),
                          style: const TextStyle(
                              fontSize: 22,
                              color: orangeC,
                              fontWeight: FontWeight.w600))),
                )),
            const SizedBox(height: 20),
          ]),
        ));
  }
}
