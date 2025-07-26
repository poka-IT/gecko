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
import 'package:gecko/screens/myWallets/switch_safe.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/buttons/add_new_derivation_button.dart';
import 'package:gecko/widgets/buttons/safe_options_buttons.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/wallet_tile.dart';
import 'package:gecko/widgets/wallet_tile_membre.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';

class WalletsHome extends ConsumerStatefulWidget {
  const WalletsHome({super.key});

  @override
  ConsumerState<WalletsHome> createState() => _WalletsHomeState();
}

class _WalletsHomeState extends ConsumerState<WalletsHome> with SingleTickerProviderStateMixin {
  bool _forceMultiWalletView = false;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);

    // Use a Builder to properly handle state transitions
    return Builder(
      builder: (context) {
        // If only one wallet and we're not forcing multi-wallet view, show WalletOptions directly
        if (myWalletProvider.listWallets.length == 1 && !_forceMultiWalletView) {
          return WalletOptions(
            wallet: myWalletProvider.listWallets[0],
            onDerivationCreated: () {
              // When a derivation is created from single wallet context,
              // force showing the multi-wallet view
              setState(() {
                _forceMultiWalletView = true;
              });
            },
          );
        }

        // Reset the force flag when we have multiple wallets
        if (myWalletProvider.listWallets.length > 1 && _forceMultiWalletView) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _forceMultiWalletView = false;
              });
            }
          });
        }

        // Show the wallets list
        return Scaffold(body: _WalletsHomeContent());
      },
    );
  }
}

class _WalletsHomeContent extends ConsumerWidget {
  // Static flag to prevent tutorial from showing multiple times in same session
  static bool _tutorialShownInSession = false;
  static int? _lastSafeNumber; // Track last safe to reset tutorial when safe changes
  // Static GlobalKey to ensure key stability across rebuilds
  static final Map<String, GlobalKey> _tutorialKeys = {};
  // Flag to prevent multiple tutorial calls during the same build cycle
  static bool _tutorialScheduled = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);

    final SafeEntity? currentSafe = () {
      try {
        return ref.read(walletServiceProvider).getSafeBox(myWalletProvider.getCurrentSafe);
      } catch (e) {
        return null;
      }
    }();

    if (currentSafe == null) {
      return const Center(child: Text('Error: Safe not found'));
    }

    // Reset tutorial session flag when safe changes
    if (_lastSafeNumber != currentSafe.number) {
      _tutorialShownInSession = false;
      _tutorialScheduled = false;
      _lastSafeNumber = currentSafe.number;

      // Clean up old tutorial keys when switching safes
      _tutorialKeys.removeWhere((key, _) => !key.contains('safe${currentSafe.number}'));
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

        return _buildWalletsContent(context, ref, currentSafe, allWallets, idtyWallet, walletsWithoutIdty, nTule);
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
          currentSafe,
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
    SafeEntity currentSafe,
    List<WalletEntity> allWallets,
    WalletEntity? idtyWallet,
    List<WalletEntity> walletsWithoutIdty,
    int nTule,
  ) {
    // SIMPLE tutorial logic: attach key to second wallet in grid if exists, otherwise first
    final int targetWalletIndex = walletsWithoutIdty.length > 1 ? 1 : 0;
    final bool shouldShowTutorial = walletsWithoutIdty.isNotEmpty;

    // Create a stable tutorial key using static map to avoid recreating keys
    final String tutorialKeyId = shouldShowTutorial && walletsWithoutIdty.isNotEmpty
        ? 'tutorial_${walletsWithoutIdty[targetWalletIndex].address}_safe${currentSafe.number}'
        : 'tutorial_empty_safe${currentSafe.number}';

    final GlobalKey tutorialKey = _tutorialKeys.putIfAbsent(tutorialKeyId, () => GlobalKey(debugLabel: tutorialKeyId));

    // Check if tutorial should be shown - use per-safe configuration
    final String tutorialConfigKey = 'showDraggableTutorial_safe${currentSafe.number}';
    final bool showDraggableTutorial = configBox.get(tutorialConfigKey) ?? true;

    // Show tutorial only once per session and per safe, and only if not already scheduled
    if (shouldShowTutorial && showDraggableTutorial && !_tutorialShownInSession && !_tutorialScheduled) {
      _tutorialScheduled = true; // Prevent multiple scheduling

      // Build tutorial with dynamic target
      final tutorialCoachMark = TutorialCoachMark(
        targets: [
          TargetFocus(
            identify: "drag_and_drop",
            keyTarget: tutorialKey,
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
        onFinish: () {
          _resetDragStateAndRoute(context);
          return true;
        },
        onSkip: () {
          _resetDragStateAndRoute(context);
          return true;
        },
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            tutorialCoachMark.show(context: context);
            _tutorialShownInSession = true; // Mark as shown for this session
            // Mark tutorial as shown for this specific safe
            configBox.put(tutorialConfigKey, false);
          }
        });
      });
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: scaleSize(57),
          backgroundColor: context.colorScheme.tertiary,
          title: Row(
            children: [
              Image.asset('assets/safes/${currentSafe.number % 4}.png', height: 32),
              ScaledSizedBox(width: 17),
              Text(
                currentSafe.name,
                style: scaledTextStyle(color: context.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.swap_horiz, color: context.colorScheme.onSurface, size: scaleSize(24)),
              tooltip: 'changeSafe'.tr(),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SwitchSafe()));
              },
            ),
            ScaledSizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
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
                            key: ValueKey('wallet_container_${stableWalletsWithoutIdty[i].address}_$i'),
                            wallet: stableWalletsWithoutIdty[i],
                            child: WalletTile(
                              repository: stableWalletsWithoutIdty[i],
                              tutorialKey: i == stableTargetIndex ? tutorialKey : null,
                              uniqueId: 'grid_$i',
                            ),
                          ),
                        ref.read(durtProvider).isConnected && myWalletProvider.listWallets.length < maxWalletsInSafe
                            ? const AddNewDerivationButton()
                            : const Text(''),
                      ],
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SafeOptionsButtons()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Clean method to reset drag state and fix route after tutorial
  void _resetDragStateAndRoute(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        try {
          // Reset drag state
          final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
          myWalletProvider.lastFlyBy = null;
          myWalletProvider.dragAddress = null;
          myWalletProvider.reload();

          // Fix route if it's empty (the main bug!)
          final currentRouteProvider = old_provider.Provider.of<CurrentRouteProvider>(context, listen: false);
          if (currentRouteProvider.currentRoute.isEmpty || currentRouteProvider.currentRoute != RouteNames.myWallets) {
            currentRouteProvider.updateRoute(RouteNames.myWallets);
          }
        } catch (e) {
          // Silent fallback
        }
      }
    });
  }
}
