// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show SafeEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/buttons/add_new_derivation_button.dart';
import 'package:gecko/widgets/buttons/chest_options_buttons.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/drag_wallets_info.dart';
import 'package:gecko/widgets/wallet_tile.dart';
import 'package:gecko/widgets/wallet_tile_membre.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class WalletsHome extends ConsumerStatefulWidget {
  const WalletsHome({super.key});

  @override
  ConsumerState<WalletsHome> createState() => _WalletsHomeState();
}

class _WalletsHomeState extends ConsumerState<WalletsHome> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);

    return Scaffold(
      body: myWalletProvider.listWallets.length == 1
          ? WalletOptions(wallet: myWalletProvider.listWallets[0])
          : _WalletsHomeContent(),
    );
  }
}

class _WalletsHomeContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    final currentChestNumber = myWalletProvider.getCurrentSafe;

    final SafeEntity? currentChest = () {
      try {
        return ref.read(walletServiceProvider).getSafeBox(currentChestNumber);
      } catch (e) {
        return null;
      }
    }();

    if (currentChest == null) {
      return const Center(child: Text('Error: Safe not found'));
    }

    if (myWalletProvider.listWallets.isEmpty) {
      return Center(
        child: Text(
          'Veuillez générer votre premier portefeuille',
          style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
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
    // Get identity wallet info asynchronously but don't block UI
    final idtyWalletAsync = ref.watch(idtyWalletAsyncProvider);

    // Use optimistic rendering: show all wallets immediately, identify identity wallet in background
    final allWallets = myWalletProvider.listWallets;
    final idtyWallet = idtyWalletAsync.valueOrNull;
    final walletsWithoutIdty = idtyWallet != null
        ? allWallets.where((w) => w.address != idtyWallet.address).toList()
        : allWallets;

    // Build tutorial target based on whether there's an identity wallet
    final tutorialCoachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "drag_and_drop",
          keyTarget: keyDragAndDrop, // Always use keyDragAndDrop for tutorial target
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
              ),
            ),
          ],
          alignSkip: Alignment.bottomRight,
          enableOverlayTab: true,
        ),
      ],
      colorShadow: context.colorScheme.primary,
      textSkip: "skip".tr(),
      paddingFocus: 10,
      opacityShadow: 0.8,
    );

    // Show tutorial if needed
    final bool showDraggableTutorial = configBox.get('showDraggableTutorial') ?? true;
    if (myWalletProvider.listWallets.length > 1 && showDraggableTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tutorialCoachMark.show(context: context);
      });
      configBox.put('showDraggableTutorial', false);
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: scaleSize(57),
          backgroundColor: context.colorScheme.tertiary,
          title: Row(
            children: [
              Image.asset('assets/chests/${currentChest.number}.png', height: 32),
              ScaledSizedBox(width: 17),
              Text(
                currentChest.name,
                style: scaledTextStyle(color: context.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        bottomNavigationBar: old_provider.Consumer<MyWalletsProvider>(
          builder: (context, _, _) {
            return myWalletProvider.lastFlyBy == null
                ? const GeckoBottomAppBar(actualRoute: 'safeHome')
                : DragWalletsInfo(lastFlyBy: myWalletProvider.lastFlyBy!, dragAddress: myWalletProvider.dragAddress!);
          },
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(child: ScaledSizedBox(height: 12)),
                    // Identity wallet section
                    if (idtyWallet != null)
                      SliverToBoxAdapter(
                        child: DragTuleAction(
                          wallet: idtyWallet,
                          child: WalletTileMembre(wallet: idtyWallet, attachTutorialKey: false),
                        ),
                      ),
                    // Regular wallets grid
                    SliverGrid.count(
                      key: keyListWallets,
                      crossAxisCount: nTule,
                      childAspectRatio: 1,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                      children: <Widget>[
                        for (var i = 0; i < walletsWithoutIdty.length; i++)
                          DragTuleAction(
                            wallet: walletsWithoutIdty[i],
                            child: WalletTile(
                              repository: walletsWithoutIdty[i],
                              attachTutorialKey: i == 1, // Always attach to second wallet for tutorial
                            ),
                          ),
                        ref.read(durtProvider).isConnected && myWalletProvider.listWallets.length < maxWalletsInSafe
                            ? const AddNewDerivationButton()
                            : const Text(''),
                      ],
                    ),
                    const SliverToBoxAdapter(child: ChestOptionsButtons()),
                  ],
                ),
              ),
              const OfflineInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
