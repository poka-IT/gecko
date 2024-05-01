// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/custom_derivations.dart';
import 'package:gecko/screens/myWallets/show_seed.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class ChestOptions extends StatelessWidget {
  const ChestOptions({Key? keyMyWallets, required this.walletProvider})
      : super(key: keyMyWallets);
  final MyWalletsProvider walletProvider;

  @override
  Widget build(BuildContext context) {
    final chestProvider = Provider.of<ChestProvider>(context, listen: false);

    ChestData currentChest = chestBox.get(configBox.get('currentChest'))!;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: GeckoAppBar(currentChest.name!),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: Stack(children: [
        Builder(
          builder: (ctx) => SafeArea(
            child: Column(children: <Widget>[
              ScaledSizedBox(height: 20),
              InkWell(
                key: keyShowSeed,
                onTap: () async {
                  final myWalletProvider =
                      Provider.of<MyWalletsProvider>(context, listen: false);
                  if (!await myWalletProvider.askPinCode()) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return ShowSeed(
                        walletName: currentChest.name,
                        walletProvider: walletProvider,
                      );
                    }),
                  );
                },
                child: ScaledSizedBox(
                  height: 60,
                  child: Row(children: <Widget>[
                    ScaledSizedBox(width: 20),
                    Image.asset(
                      'assets/onBoarding/phrase_de_restauration_flou.png',
                      width: scaleSize(60),
                    ),
                    ScaledSizedBox(width: 13),
                    ScaledSizedBox(
                      width: 270,
                      child: Text(
                        'displayMnemonic'.tr(),
                        style: scaledTextStyle(
                          fontSize: 16,
                          color: orangeC,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              ScaledSizedBox(height: 2),
              Consumer<SubstrateSdk>(builder: (context, sub, _) {
                return InkWell(
                  key: keyChangePin,
                  onTap: null,
                  //  sub.nodeConnected
                  //     ? () async {
                  //         // await _chestProvider.changePin(context, cesiumWallet);
                  //         String? pinResult = await Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //             builder: (context) {
                  //               return ChangePinScreen(
                  //                 walletName: currentChest.name,
                  //                 walletProvider: walletProvider,
                  //               );
                  //             },
                  //           ),
                  //         );

                  //         if (pinResult != null) {
                  //           walletProvider.pinCode = pinResult;
                  //         }
                  //       }
                  //     : null,
                  child: ScaledSizedBox(
                      height: 60,
                      child: Row(children: <Widget>[
                        ScaledSizedBox(width: 30),
                        Image.asset(
                          'assets/chests/secret_code.png',
                          height: scaleSize(22),
                        ),
                        ScaledSizedBox(width: 18),
                        Text(
                          'changePassword'.tr(),
                          style: scaledTextStyle(
                              fontSize: 16,
                              color: sub.nodeConnected
                                  ? Colors.grey[500]
                                  : Colors.grey[500]),
                        ),
                      ])),
                );
              }),
              ScaledSizedBox(height: 2),
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
                  child: ScaledSizedBox(
                    height: 60,
                    child: Row(children: <Widget>[
                      ScaledSizedBox(width: 37),
                      Icon(
                        Icons.manage_accounts,
                        size: scaleSize(31),
                      ),
                      ScaledSizedBox(width: 23),
                      Text(
                        'createDerivation'.tr(),
                        style: scaledTextStyle(
                            fontSize: 16,
                            color: sub.nodeConnected
                                ? Colors.black
                                : Colors.grey[500]),
                      ),
                    ]),
                  ),
                );
              }),
              ScaledSizedBox(height: 2),
              InkWell(
                key: keyDeleteChest,
                onTap: () async {
                  await chestProvider.deleteChest(context, currentChest);
                },
                child: ScaledSizedBox(
                  height: 60,
                  child: Row(children: <Widget>[
                    ScaledSizedBox(width: 32),
                    Image.asset(
                      'assets/walletOptions/trash.png',
                      height: scaleSize(38),
                    ),
                    ScaledSizedBox(width: 22),
                    Text(
                      'deleteChest'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: const Color(0xffD80000),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        const OfflineInfo(),
      ]),
    );
  }
}
