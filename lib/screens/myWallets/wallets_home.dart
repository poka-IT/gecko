// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show SafeEntity, WalletEntity;
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

    // If only one wallet, navigate to WalletOptions instead of showing inline
    if (myWalletProvider.listWallets.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => WalletOptions(wallet: myWalletProvider.listWallets[0])),
          );
        }
      });
      // Show loading screen while navigation happens
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(body: _WalletsHomeContent());
  }
}

class _WalletsHomeContent extends ConsumerWidget {
  // Static flag to prevent tutorial from showing multiple times in same session
  static bool _tutorialShownInSession = false; // Reset for testing

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);

    final SafeEntity? currentChest = () {
      try {
        return ref.read(walletServiceProvider).getSafeBox(myWalletProvider.getCurrentSafe);
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

    // Get identity wallet info and wait for it to resolve to avoid flash
    final idtyWalletAsync = ref.watch(idtyWalletAsyncProvider);

    // Show loading state while identity wallet is being determined
    return idtyWalletAsync.when(
      data: (idtyWallet) {
        // Data is ready, render the UI with correct wallet separation
        final allWallets = myWalletProvider.listWallets;
        final walletsWithoutIdty = idtyWallet != null
            ? allWallets.where((w) => w.address != idtyWallet.address).toList()
            : allWallets;

        return _buildWalletsContent(context, ref, currentChest, allWallets, idtyWallet, walletsWithoutIdty, nTule);
      },
      loading: () {
        // Show loading while determining identity wallet to prevent flash
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stack) {
        // On error, treat as no identity wallet
        final allWallets = myWalletProvider.listWallets;

        return _buildWalletsContent(
          context,
          ref,
          currentChest,
          allWallets,
          null, // No identity wallet
          allWallets, // All wallets without identity
          nTule,
        );
      },
    );
  }

  Widget _buildWalletsContent(
    BuildContext context,
    WidgetRef ref,
    SafeEntity currentChest,
    List<WalletEntity> allWallets,
    WalletEntity? idtyWallet,
    List<WalletEntity> walletsWithoutIdty,
    int nTule,
  ) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);

    // SIMPLE tutorial logic: attach key to second wallet in grid if exists, otherwise first
    final int targetWalletIndex = walletsWithoutIdty.length > 1 ? 1 : 0;
    final bool shouldShowTutorial = walletsWithoutIdty.isNotEmpty;

    // Build tutorial with simple target
    final tutorialCoachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "drag_and_drop",
          keyTarget: keyTutorialTarget,
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

    // Show tutorial only once and only if we have wallets
    final bool showDraggableTutorial = configBox.get('showDraggableTutorial') ?? true;
    // Re-enable tutorial now that GlobalKey duplication is fixed
    const bool tutorialDisabled = false; // Fixed: was true

    if (shouldShowTutorial && showDraggableTutorial && !_tutorialShownInSession && !tutorialDisabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            tutorialCoachMark.show(context: context);
            _tutorialShownInSession = true; // Mark as shown for this session
          }
        });
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
                    // Regular wallets grid - isolated from provider rebuilds
                    old_provider.Consumer<MyWalletsProvider>(
                      builder: (context, myWalletProvider, child) {
                        // Create stable lists that won't change during layout
                        final stableWalletsWithoutIdty = List.from(walletsWithoutIdty);
                        final stableTargetIndex = targetWalletIndex;

                        return SliverGrid.count(
                          key: keyListWallets,
                          crossAxisCount: nTule,
                          childAspectRatio: 1,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                          children: <Widget>[
                            for (var i = 0; i < stableWalletsWithoutIdty.length; i++)
                              DragTuleAction(
                                key: ValueKey('drag_${stableWalletsWithoutIdty[i].address}'),
                                wallet: stableWalletsWithoutIdty[i],
                                child: WalletTile(
                                  repository: stableWalletsWithoutIdty[i],
                                  attachTutorialKey: i == stableTargetIndex,
                                ),
                              ),
                            ref.read(durtProvider).isConnected && myWalletProvider.listWallets.length < maxWalletsInSafe
                                ? const AddNewDerivationButton()
                                : const Text(''),
                          ],
                        );
                      },
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
