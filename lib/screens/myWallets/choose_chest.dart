// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:provider/provider.dart';

class ChooseChest extends StatefulWidget {
  const ChooseChest({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ChooseChestState();
  }
}

class _ChooseChestState extends State<ChooseChest> {
  final tplController = TextEditingController();
  final buttonCarouselController = CarouselSliderController();
  int currentChest = Durt.i.wallets.defaultSafeBoxNumber;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(toolbarHeight: scaleSize(57), title: Text('selectMyChest'.tr())),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 160),
            CarouselSlider(
              carouselController: buttonCarouselController,
              options: CarouselOptions(
                height: 210,
                onPageChanged: (index, reason) {
                  currentChest = Durt.i.wallets.safeBox.toMap().keys.toList()[index];
                  setState(() {});
                },
                enableInfiniteScroll: false,
                initialPage: currentChest,
                enlargeCenterPage: true,
                viewportFraction: 0.5,
              ),
              items: Durt.i.wallets.safeBox.toMap().entries.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Column(
                      children: <Widget>[
                        i.value.imagePath == null
                            ? Image.asset('assets/chests/${i.value.number}.png', height: 150)
                            : Image.file(File(i.value.imagePath!), height: 150),
                        const SizedBox(height: 30),
                        Text(i.value.name, style: const TextStyle(fontSize: 20)),
                      ],
                    );
                  },
                );
              }).toList(),
            ),
            if (Durt.i.wallets.safeBox.values.toList().length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: Durt.i.wallets.safeBox.values.toList().map((entry) {
                  return GestureDetector(
                    onTap: () => buttonCarouselController.animateToPage(entry.key),
                    child: Container(
                      width: 12.0,
                      height: 12.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                            .withValues(alpha: currentChest == entry.key ? 0.9 : 0.4),
                      ),
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
                  backgroundColor: context.colorScheme.primary,
                ),
                onPressed: () async {
                  await configBox.put('currentChest', currentChest);
                  myWalletProvider.pinCode = '';
                  if (!await myWalletProvider.askPinCode()) return;

                  Navigator.popUntil(context, ModalRoute.withName('/'));
                  Navigator.pushNamed(context, '/mywallets');
                },
                child: Text(
                  'openThisChest'.tr(),
                  style: TextStyle(fontSize: 21, color: context.colorScheme.surface, fontWeight: FontWeight.w600),
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
                      MaterialPageRoute(
                        builder: (context) {
                          return const OnboardingStepFive(skipIntro: true);
                        },
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 400,
                    height: 50,
                    child: Center(
                      child: Text(
                        'createChest'.tr(),
                        style: TextStyle(fontSize: 21, color: context.colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              key: keyImportChest,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const RestoreChest(skipIntro: true);
                    },
                  ),
                );
              },
              child: SizedBox(
                width: 400,
                height: 50,
                child: Center(
                  child: Text(
                    'importChest'.tr(),
                    style: TextStyle(fontSize: 21, color: context.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
