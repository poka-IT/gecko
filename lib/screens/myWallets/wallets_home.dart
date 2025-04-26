// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
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

class WalletsHome extends StatefulWidget {
  const WalletsHome({super.key});

  @override
  State<WalletsHome> createState() => _WalletsHomeState();
}

class _WalletsHomeState extends State<WalletsHome> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    return Scaffold(
      body: myWalletProvider.listWallets.length == 1 ? WalletOptions(wallet: myWalletProvider.listWallets[0]) : _WalletsHomeContent(),
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
        body: SafeArea(
          child: Stack(children: [
            myWalletsTiles(context, currentChestNumber),
            const OfflineInfo(),
          ]),
        ));
  }

  Widget myWalletsTiles(BuildContext context, int currentChestNumber) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final isWalletsExists = myWalletProvider.isWalletsExists();

    if (!isWalletsExists) {
      return const Text('');
    }

    if (myWalletProvider.listWallets.isEmpty) {
      return Center(
          child: Text(
        'Veuillez générer votre premier portefeuille',
        style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ));
    }

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

    if (myWalletProvider.listWallets.length > 1 && showDraggableTutorial) {
      tutorialCoachMark.show(context: context);
      configBox.put('showDraggableTutorial', false);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: CustomScrollView(slivers: <Widget>[
        SliverToBoxAdapter(child: ScaledSizedBox(height: 12)),
        if (myWalletProvider.idtyWallet != null)
          SliverToBoxAdapter(
            child: DragTuleAction(
              wallet: myWalletProvider.idtyWallet!,
              child: WalletTileMembre(wallet: myWalletProvider.idtyWallet!),
            ),
          ),
        SliverGrid.count(key: keyListWallets, crossAxisCount: nTule, childAspectRatio: 1, crossAxisSpacing: 0, mainAxisSpacing: 0, children: <Widget>[
          for (final repository in myWalletProvider.listWalletsWithoutIdty)
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
