// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
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
    final currentSafe = Durt.i.walletService.defaultSafeBox;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      resizeToAvoidBottomInset: false,
      appBar: GeckoAppBar(currentSafe.name),
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
    final currentChest = Durt.i.walletService.defaultSafeBox;
    final isAlone = myWalletProvider.listWallets.length == 1;

    return Column(
      spacing: 5,
      children: [
        InkWell(
          key: keyShowSeed,
          onTap: () async {
            if (!await myWalletProvider.askPinCode(force: true)) return;
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
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  size: scaleSize(24),
                  color: context.colorScheme.onSurface,
                ),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'displayMnemonic'.tr(),
                    style: scaledTextStyle(
                      fontSize: 16,
                      color: context.colorScheme.onSurface,
                    ),
                    softWrap: true,
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
              onTap: () async {
                if (!await myWalletProvider.askPinCode(force: true)) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePinScreen(
                      walletName: currentChest.name,
                      walletProvider: myWalletProvider,
                    ),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: scaleSize(24),
                      color: const Color.fromARGB(255, 255, 142, 142),
                    ),
                    ScaledSizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'changePassword'.tr(),
                        style: scaledTextStyle(
                          fontSize: 16,
                          color: context.colorScheme.onSurface,
                        ),
                        softWrap: true,
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
                onTap: Durt.i.isConnected
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomDerivation()),
                        );
                      }
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.manage_accounts,
                        size: scaleSize(24),
                        color: Durt.i.isConnected ? context.colorScheme.onSurface : Colors.grey[400],
                      ),
                      ScaledSizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'createDerivation'.tr(),
                          style: scaledTextStyle(
                            fontSize: 16,
                            color: Durt.i.isConnected ? context.colorScheme.onSurface : Colors.grey[500],
                          ),
                          softWrap: true,
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
            if (!await myWalletProvider.askPinCode(force: true)) return;

            await chestProvider.forgetSafe(context, currentChest);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Image.asset(
                  'assets/walletOptions/trash.png',
                  height: scaleSize(24),
                  color: const Color(0xffD80000),
                ),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'forgetSafe'.tr(),
                    style: scaledTextStyle(
                      fontSize: 16,
                      color: const Color(0xffD80000),
                    ),
                    softWrap: true,
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
