// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:provider/provider.dart' as old_provider;

class ChooseChest extends ConsumerStatefulWidget {
  const ChooseChest({super.key});

  @override
  ConsumerState<ChooseChest> createState() => _ChooseChestState();
}

class _ChooseChestState extends ConsumerState<ChooseChest> {
  final tplController = TextEditingController();
  final buttonCarouselController = CarouselSliderController();
  late int currentChest;

  @override
  void initState() {
    super.initState();
    currentChest = ref.read(walletServiceProvider).defaultSafeBoxNumber;
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);

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
                  currentChest = ref
                      .read(walletServiceProvider)
                      .safeBox
                      .query()
                      .build()
                      .property(SafeEntity_.number)
                      .max();
                  setState(() {});
                },
                enableInfiniteScroll: false,
                initialPage: currentChest,
                enlargeCenterPage: true,
                viewportFraction: 0.5,
              ),
              items: ref.read(walletServiceProvider).safeBox.getAll().map((safe) {
                return Builder(
                  builder: (BuildContext context) {
                    return Column(
                      children: <Widget>[
                        safe.imagePath == null
                            ? Image.asset('assets/chests/${safe.number}.png', height: 150)
                            : Image.file(File(safe.imagePath!), height: 150),
                        const SizedBox(height: 30),
                        Text(safe.name, style: const TextStyle(fontSize: 20)),
                      ],
                    );
                  },
                );
              }).toList(),
            ),
            if (ref.read(walletServiceProvider).safeBox.query().build().count() > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ref.read(walletServiceProvider).safeBox.getAll().map((entry) {
                  return GestureDetector(
                    onTap: () => buttonCarouselController.animateToPage(entry.id),
                    child: Container(
                      width: 12.0,
                      height: 12.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                            .withValues(alpha: currentChest == entry.id ? 0.9 : 0.4),
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
                  ref.read(walletServiceProvider).setDefaultSafeBoxNumber(currentChest);
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
