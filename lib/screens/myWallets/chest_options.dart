// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';

import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:gecko/screens/myWallets/custom_derivations.dart';
import 'package:gecko/screens/myWallets/show_seed.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:provider/provider.dart';

class ChestOptions extends StatelessWidget {
  const ChestOptions({Key? keyMyWallets, required this.walletProvider})
      : super(key: keyMyWallets);
  final MyWalletsProvider walletProvider;

  @override
  Widget build(BuildContext context) {
    ChestProvider chestProvider =
        Provider.of<ChestProvider>(context, listen: false);
    HomeProvider homeProvider =
        Provider.of<HomeProvider>(context, listen: false);

    ChestData currentChest = chestBox.get(configBox.get('currentChest'))!;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          // leading: IconButton(
          //     icon: const Icon(Icons.arrow_back, color: Colors.black),
          //     onPressed: () {
          //       // Navigator.popUntil(
          //       //   context,
          //       //   ModalRoute.withName('/mywallets'),
          //       // );
          //       Navigator.pop(context);
          //     }),
          title: SizedBox(
            height: 22,
            child: Text(currentChest.name!),
          )),
      bottomNavigationBar: homeProvider.bottomAppBar(context),
      body: Stack(children: [
        Builder(
          builder: (ctx) => SafeArea(
            child: Column(children: <Widget>[
              SizedBox(height: 30 * ratio),
              InkWell(
                key: keyShowSeed,
                onTap: () async {
                  MyWalletsProvider myWalletProvider =
                      Provider.of<MyWalletsProvider>(context, listen: false);
                  WalletData? defaultWallet =
                      myWalletProvider.getDefaultWallet();
                  String? pin;
                  pin = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (homeContext) {
                        return UnlockingWallet(wallet: defaultWallet);
                      },
                    ),
                  );

                  if (pin != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return ShowSeed(
                          walletName: currentChest.name,
                          walletProvider: walletProvider,
                        );
                      }),
                    );
                  }
                },
                child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 20),
                    Image.asset(
                      'assets/onBoarding/phrase_de_restauration_flou.png',
                      width: 60,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      'displayMnemonic'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: orangeC,
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: 10 * ratio),
              Consumer<SubstrateSdk>(builder: (context, sub, _) {
                return InkWell(
                  key: keyChangePin,
                  onTap: sub.nodeConnected
                      ? () async {
                          // await _chestProvider.changePin(context, cesiumWallet);
                          String? pinResult = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return ChangePinScreen(
                                  walletName: currentChest.name,
                                  walletProvider: walletProvider,
                                );
                              },
                            ),
                          );

                          if (pinResult != null) {
                            walletProvider.pinCode = pinResult;
                          }
                        }
                      : null,
                  child: SizedBox(
                      height: 50,
                      child: Row(children: <Widget>[
                        const SizedBox(width: 26),
                        Image.asset(
                          'assets/chests/secret_code.png',
                          height: 25,
                        ),
                        const SizedBox(width: 18),
                        Text(
                          'changePassword'.tr(),
                          style: TextStyle(
                              fontSize: 20,
                              color: sub.nodeConnected
                                  ? Colors.black
                                  : Colors.grey[500]),
                        ),
                      ])),
                );
              }),
              SizedBox(height: 10 * ratio),
              Consumer<SubstrateSdk>(builder: (context, sub, _) {
                return InkWell(
                  key: keycreateRootDerivation,
                  onTap: sub.nodeConnected
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const CustomDerivation();
                              },
                            ),
                          );
                        }
                      : null,
                  child: SizedBox(
                    height: 50,
                    child: Row(children: <Widget>[
                      const SizedBox(width: 35),
                      const Icon(
                        Icons.manage_accounts,
                        size: 33,
                      ),
                      const SizedBox(width: 25),
                      Text(
                        'createDerivation'.tr(),
                        style: TextStyle(
                            fontSize: 20,
                            color: sub.nodeConnected
                                ? Colors.black
                                : Colors.grey[500]),
                      ),
                    ]),
                  ),
                );
              }),
              SizedBox(height: 10 * ratio),
              InkWell(
                key: keyDeleteChest,
                onTap: () async {
                  await chestProvider.deleteChest(context, currentChest);
                },
                child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 28),
                    Image.asset(
                      'assets/walletOptions/trash.png',
                      height: 45,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'deleteChest'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xffD80000),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        CommonElements().offlineInfo(context),
      ]),
    );
  }
}
