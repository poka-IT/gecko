// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/buttons/add_new_derivation_button.dart';
import 'package:gecko/widgets/buttons/chest_options_buttons.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/drag_wallets_info.dart';
import 'package:gecko/widgets/wallet_tile.dart';
import 'package:gecko/widgets/wallet_tile_membre.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class WalletsHome extends StatelessWidget {
  const WalletsHome({super.key});

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    return FutureBuilder<List<WalletData>>(
      future: myWalletProvider.readAllWallets(myWalletProvider.getCurrentChest()),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: orangeC),
            ),
          );
        }

        // If only one wallet, directly show WalletOptions
        if (myWalletProvider.listWallets.length == 1) {
          return WalletOptions(wallet: myWalletProvider.listWallets[0]);
        }

        // Otherwise show normal WalletsHome screen
        return _WalletsHomeContent();
      },
    );
  }
}

class _WalletsHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final currentChestNumber = myWalletProvider.getCurrentChest();
    final ChestData currentChest = chestBox.get(currentChestNumber)!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: yellowC,
        toolbarHeight: scaleSize(57),
        title: Row(
          children: [
            Image.asset(
              'assets/chests/${currentChest.imageName}',
              height: 32,
            ),
            ScaledSizedBox(width: 17),
            Text(
              currentChest.name!,
              style: scaledTextStyle(color: Colors.grey[850], fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<MyWalletsProvider>(builder: (context, _, __) {
        return myWalletProvider.lastFlyBy == null
            ? const GeckoBottomAppBar(
                actualRoute: 'safeHome',
              )
            : DragWalletsInfo(
                lastFlyBy: myWalletProvider.lastFlyBy!,
                dragAddress: myWalletProvider.dragAddress!,
              );
      }),
      body: FutureBuilder(
          future: myWalletProvider.readAllWallets(currentChestNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done || snapshot.hasError) {
              return Center(
                child: ScaledSizedBox(
                  height: 50,
                  width: 50,
                  child: const CircularProgressIndicator(
                    color: orangeC,
                    strokeWidth: 3,
                  ),
                ),
              );
            }
            return SafeArea(
              child: Stack(children: [
                myWalletsTiles(context, currentChestNumber),
                const OfflineInfo(),
              ]),
            );
          }),
    );
  }

  Widget myWalletsTiles(BuildContext context, int currentChestNumber) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final bool isWalletsExists = myWalletProvider.isWalletsExists();

    if (!isWalletsExists) {
      return const Text('');
    }

    if (myWalletProvider.listWallets.isEmpty) {
      return Expanded(
          child: Column(children: <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        )),
      ]));
    }

    // Get wallet list and sort by derivation number
    List<WalletData> listWallets = myWalletProvider.listWallets;
    listWallets.sort((p1, p2) {
      return Comparable.compare(p1.number!, p2.number!);
    });

    // Get first wallet with identity
    final idtyWallet = listWallets.firstWhere(
      (w) => w.hasIdentity,
      orElse: () => WalletData(address: ''),
    );

    List<WalletData> listWalletsWithoutIdty = listWallets.toList();
    listWalletsWithoutIdty.removeWhere((w) => w.address == idtyWallet.address);

    final screenWidth = MediaQuery.of(context).size.width;
    int nTule;

    if (screenWidth >= 700) {
      nTule = 4;
    } else if (screenWidth >= 450) {
      nTule = 3;
    } else {
      nTule = 2;
    }

    final tutorialCoachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "drag_and_drop",
          keyTarget: keyDragAndDrop,
          contents: [
            TargetContent(
                child: Column(
              children: [
                Image.asset('assets/drag-and-drop.png', height: scaleSize(115)),
                ScaledSizedBox(height: 15),
                Text(
                  'explainDraggableWallet'.tr(),
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ))
          ],
          alignSkip: Alignment.bottomRight,
          enableOverlayTab: true,
        ),
      ],
      colorShadow: orangeC,
      textSkip: "skip".tr(),
      paddingFocus: 10,
      opacityShadow: 0.8,
    );

    // configBox.delete('showDraggableTutorial');
    final bool showDraggableTutorial = configBox.get('showDraggableTutorial') ?? true;

    if (listWallets.length > 1 && showDraggableTutorial) {
      tutorialCoachMark.show(context: context);
      configBox.put('showDraggableTutorial', false);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: CustomScrollView(slivers: <Widget>[
        SliverToBoxAdapter(child: ScaledSizedBox(height: 12)),
        if (idtyWallet.address != '')
          SliverToBoxAdapter(
            child: DragTuleAction(
              wallet: idtyWallet,
              child: WalletTileMembre(repository: idtyWallet),
            ),
          ),
        SliverGrid.count(key: keyListWallets, crossAxisCount: nTule, childAspectRatio: 1, crossAxisSpacing: 0, mainAxisSpacing: 0, children: <Widget>[
          for (WalletData repository in listWalletsWithoutIdty)
            DragTuleAction(
              wallet: repository,
              child: WalletTile(repository: repository),
            ),
          Consumer<SubstrateSdk>(builder: (context, sub, _) {
            return sub.nodeConnected && myWalletProvider.listWallets.length < maxWalletsInSafe ? const AddNewDerivationButton() : const Text('');
          }),
        ]),
        const SliverToBoxAdapter(child: ChestOptionsButtons()),
      ]),
    );
  }
}
