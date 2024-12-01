// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
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
  const ChestOptions({Key? keyMyWallets}) : super(key: keyMyWallets);

  @override
  Widget build(BuildContext context) {
    final currentChest = chestBox.get(configBox.get('currentChest'))!;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: GeckoAppBar(currentChest.name!),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: Stack(children: [
        Builder(
          builder: (ctx) => SafeArea(
            child: Column(
              children: [
                ScaledSizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(left: scaleSize(16)),
                  child: ChestOptionsContent(),
                ),
              ],
            ),
          ),
        ),
        const OfflineInfo(),
      ]),
    );
  }
}

class ChestOptionsContent extends StatelessWidget {
  const ChestOptionsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final chestProvider = Provider.of<ChestProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final currentChest = chestBox.get(configBox.get('currentChest'))!;
    final isAlone = myWalletProvider.listWallets.length == 1;

    return Column(
      children: [
        InkWell(
          key: keyShowSeed,
          onTap: () async {
            if (!await myWalletProvider.askPinCode()) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ShowSeed(
                        walletName: currentChest.name,
                        walletProvider: myWalletProvider,
                      )),
            );
          },
          child: Container(
            height: scaleSize(48),
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
            child: Row(
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  size: scaleSize(24),
                  color: Colors.black87,
                ),
                ScaledSizedBox(width: 16),
                Text(
                  'displayMnemonic'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        Consumer<SubstrateSdk>(
          builder: (context, sub, _) {
            return InkWell(
              key: keyChangePin,
              onTap: null,
              child: Container(
                height: scaleSize(48),
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: scaleSize(24),
                      color: Colors.grey[400],
                    ),
                    ScaledSizedBox(width: 16),
                    Text(
                      'changePassword'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (!isAlone)
          Consumer<SubstrateSdk>(
            builder: (context, sub, _) {
              return InkWell(
                key: keycreateRootDerivation,
                onTap: sub.nodeConnected
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomDerivation()),
                        );
                      }
                    : null,
                child: Container(
                  height: scaleSize(48),
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.manage_accounts,
                        size: scaleSize(24),
                        color: sub.nodeConnected ? Colors.black87 : Colors.grey[400],
                      ),
                      ScaledSizedBox(width: 16),
                      Text(
                        'createDerivation'.tr(),
                        style: scaledTextStyle(
                          fontSize: 16,
                          color: sub.nodeConnected ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        InkWell(
          key: keyDeleteChest,
          onTap: () async {
            await chestProvider.deleteChest(context, currentChest);
          },
          child: Container(
            height: scaleSize(48),
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
            child: Row(
              children: [
                Image.asset(
                  'assets/walletOptions/trash.png',
                  height: scaleSize(24),
                  color: const Color(0xffD80000),
                ),
                ScaledSizedBox(width: 16),
                Text(
                  'deleteChest'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    color: const Color(0xffD80000),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
