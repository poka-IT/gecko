import 'package:durt2/durt2.dart' show SafeEntity, WalletEntity, SafeType;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/screens/myWallets/switch_safe.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/buttons/add_new_derivation_button.dart';
import 'package:gecko/widgets/buttons/safe_options_buttons.dart';
import 'package:gecko/widgets/bottom_sheets/safe_options_menu.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/wallet_tile.dart';
import 'package:gecko/widgets/wallet_tile_membre.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// Note: cleanupWalletsHomeKeys() is no longer needed since we use instance-specific state

class WalletsHome extends ConsumerStatefulWidget {
  /// The safe fingerprint used for unique widget identity
  final String safeFingerprint;

  /// Create WalletsHome with mandatory safe fingerprint for unique widget identity
  /// This prevents GlobalKey conflicts by ensuring each safe gets its own widget instance
  WalletsHome({required this.safeFingerprint}) : super(key: ValueKey('wallets_safe_$safeFingerprint'));

  @override
  ConsumerState<WalletsHome> createState() => _WalletsHomeState();

  /// Factory constructor that automatically resolves the current safe's fingerprint
  /// This is the recommended way to create WalletsHome instances
  factory WalletsHome.fromCurrentSafe(WidgetRef ref) {
    final walletService = ref.read(walletServiceProvider);
    final currentSafeNumber = walletService.defaultSafeBoxNumber;

    // Find the safe by number (not by ObjectBox ID) to avoid "Illegal ID value: 0" error
    final allSafes = walletService.safeBox.getAll();
    final currentSafe = allSafes.where((safe) => safe.number == currentSafeNumber).firstOrNull;

    // Use the safe's fingerprint as a unique key to ensure each safe gets its own widget tree
    final uniqueKey = currentSafe?.fingerprint ?? 'unknown_safe_$currentSafeNumber';

    return WalletsHome(safeFingerprint: uniqueKey);
  }
}

class _WalletsHomeState extends ConsumerState<WalletsHome> with SingleTickerProviderStateMixin {
  bool _forceMultiWalletView = false;

  @override
  Widget build(BuildContext context) {
    final walletsState = ref.watch(walletsListProvider);

    // Use a Builder to properly handle state transitions
    return Builder(
      builder: (context) {
        // If only one wallet and we're not forcing multi-wallet view, show WalletOptions directly
        if (walletsState.wallets.length == 1 && !_forceMultiWalletView) {
          return WalletOptions(
            wallet: walletsState.wallets[0],
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
        if (walletsState.wallets.length > 1 && _forceMultiWalletView) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _forceMultiWalletView = false;
              });
            }
          });
        }

        // Show the wallets list
        return Scaffold(body: _WalletsHomeContent(safeFingerprint: widget.safeFingerprint));
      },
    );
  }
}

class _WalletsHomeContent extends ConsumerStatefulWidget {
  /// The safe fingerprint for unique instance identification
  final String safeFingerprint;

  const _WalletsHomeContent({required this.safeFingerprint});

  @override
  ConsumerState<_WalletsHomeContent> createState() => _WalletsHomeContentState();
}

class _WalletsHomeContentState extends ConsumerState<_WalletsHomeContent> with SingleTickerProviderStateMixin {
  // Instance-specific state (no more static variables!)
  bool _tutorialShownInSession = false;
  int? _lastSafeNumber;
  int _keyCounter = 0;
  bool _tutorialScheduled = false;
  GlobalKey? _currentTutorialKey;
  bool _hasAttemptedReload = false;

  // Fade-in animation controller
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    // Start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final walletsState = ref.watch(walletsListProvider);
    final currentSafeNumber = ref.watch(currentSafeNumberProvider);

    final SafeEntity? currentSafe = () {
      try {
        return ref.read(walletServiceProvider).getSafeBox(currentSafeNumber);
      } catch (e) {
        return null;
      }
    }();

    if (currentSafe == null) {
      return const Center(child: Text('Error: Safe not found'));
    }

    // Preload safe on-chain data (balances, certifications, identity statuses)
    // This ensures all data is loaded before wallets are displayed
    final safeDataAsync = ref.watch(safeOnChainDataProvider(currentSafeNumber));

    // Reset tutorial session flag when safe changes
    if (_lastSafeNumber != currentSafe.number) {
      _tutorialShownInSession = false;
      _tutorialScheduled = false;
      _hasAttemptedReload = false;
      _lastSafeNumber = currentSafe.number;

      // Increment key counter and reset tutorial key for new safe
      _keyCounter++;
      _currentTutorialKey = null; // Reset tutorial key for new safe

      // Restart fade-in animation for new safe
      _fadeController.reset();
      _fadeController.forward();
    }

    if (walletsState.wallets.isEmpty) {
      // One-shot defensive reload: Riverpod state may be out of sync with ObjectBox
      // after legacy migration. Only attempt once to avoid infinite reload loops.
      if (!_hasAttemptedReload) {
        _hasAttemptedReload = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            log.w('WalletsHome: wallet list empty for safe $currentSafeNumber, attempting reload');
            ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafeNumber);
          }
        });
        return Center(child: CircularProgressIndicator(color: context.colorScheme.primary));
      }
      // Reload already attempted and wallets still empty — show empty state
      return Center(
        child: Text(
          'noWalletFound'.tr(),
          textAlign: TextAlign.center,
          style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Reset reload flag when wallets are present (for future safe switches)
    _hasAttemptedReload = false;

    final screenWidth = MediaQuery.of(context).size.width;
    int nTule;
    if (screenWidth >= 1200) {
      nTule = 6;
    } else if (screenWidth >= 900) {
      nTule = 5;
    } else if (screenWidth >= 700) {
      nTule = 4;
    } else if (screenWidth >= 450) {
      nTule = 3;
    } else {
      nTule = 2;
    }

    // Get identity wallet info and wait for it to resolve to avoid flash
    final idtyWalletAsync = ref.watch(idtyWalletAsyncProvider);

    // safeDataAsync is watched to trigger loading - actual data display is handled
    // by individual widgets (Balance, Certifications) with shimmer placeholders
    // ignore: unused_local_variable
    final _ = safeDataAsync;

    return idtyWalletAsync.when(
      data: (idtyWallet) {
        // Data is ready, render the UI with correct wallet separation
        // Balance/Certification widgets will show shimmer while their data loads
        final allWallets = walletsState.wallets;

        // Validate that the identity wallet belongs to the current safe.
        // During safe switches, a stale cached value from the previous safe
        // can briefly be returned before the provider rebuilds.
        final validIdtyWallet = (idtyWallet != null && allWallets.any((w) => w.address == idtyWallet.address))
            ? idtyWallet
            : null;

        final walletsWithoutIdty = validIdtyWallet != null
            ? allWallets.where((w) => w.address != validIdtyWallet.address).toList()
            : allWallets;

        return _buildWalletsContent(context, ref, currentSafe, allWallets, validIdtyWallet, walletsWithoutIdty, nTule);
      },
      loading: () {
        // Show wallets immediately with shimmer placeholders for balances
        // This provides a smoother UX than a blocking loader
        final allWallets = walletsState.wallets;
        return _buildWalletsContent(context, ref, currentSafe, allWallets, null, allWallets, nTule);
      },
      error: (error, stack) {
        // On error, treat as no identity wallet
        final allWallets = walletsState.wallets;

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
    // Freeze the wallet list to prevent mutations during layout
    final frozenWalletsWithoutIdty = List<WalletEntity>.unmodifiable(walletsWithoutIdty);
    // Tutorial logic: only show when user has at least 2 wallets (drag & drop becomes useful)
    final int targetWalletIndex = frozenWalletsWithoutIdty.length > 1 ? 1 : 0;
    final bool shouldShowTutorial = frozenWalletsWithoutIdty.length >= 2;

    // Create a stable tutorial key using the safe fingerprint for true uniqueness
    final String tutorialKeyId = shouldShowTutorial && walletsWithoutIdty.isNotEmpty
        ? 'tutorial_${walletsWithoutIdty[targetWalletIndex].address}_${widget.safeFingerprint}'
        : 'tutorial_empty_${widget.safeFingerprint}';

    // Create or reuse tutorial key for current safe to ensure stability during tutorial
    _currentTutorialKey ??= GlobalKey(debugLabel: '${tutorialKeyId}_$_keyCounter');
    final GlobalKey tutorialKey = _currentTutorialKey!;

    // Check if tutorial should be shown - global configuration (once for all safes)
    final config = ref.read(configServiceProvider);
    final bool showDraggableTutorial = config.showDraggableTutorial;
    // Show tutorial only once EVER (global) when user has at least 2 wallets
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
            // Hide bottom app bar when tutorial starts
            final container = ProviderScope.containerOf(context);
            container.read(bottomAppBarProvider.notifier).setDialogVisible(true);

            tutorialCoachMark.show(context: context);
            _tutorialShownInSession = true; // Mark as shown for this session
            // Mark tutorial as shown GLOBALLY (never show again)
            config.showDraggableTutorial = false;
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
              // Show Cesium logo for legacy safes, normal safe icon for others
              currentSafe.safeType == SafeType.legacy
                  ? SvgPicture.asset('assets/cesium_bw2.svg', height: 32, semanticsLabel: 'Cesium')
                  : Image.asset('assets/safes/${currentSafe.number % 4}.png', height: 32),
              ScaledSizedBox(width: 17),
              Text(
                WalletNameService.displayName(currentSafe.name),
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
            IconButton(
              icon: Icon(Icons.settings, color: context.colorScheme.onSurface, size: scaleSize(24)),
              tooltip: 'manageSafe'.tr(),
              onPressed: () => showSafeOptionsMenu(context),
            ),
            ScaledSizedBox(width: 8),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: CustomScrollView(
                    slivers: <Widget>[
                      SliverToBoxAdapter(child: ScaledSizedBox(height: 12)),
                      // Identity wallet section
                      if (idtyWallet != null)
                        SliverToBoxAdapter(
                          child: Consumer(
                            builder: (context, ref, child) {
                              // Get the latest wallet data to ensure avatar updates are reflected
                              final latestIdtyWallet =
                                  ref.watch(walletByAddressProvider(idtyWallet.address)) ?? idtyWallet;
                              return DragTuleAction(
                                wallet: latestIdtyWallet,
                                child: WalletTileMembre(wallet: latestIdtyWallet, attachTutorialKey: false),
                              );
                            },
                          ),
                        ),
                      // Regular wallets - manual grid using Column/Row
                      SliverToBoxAdapter(
                        key: keyListWallets,
                        child: Builder(
                          builder: (context) {
                            // Calculate tile size once, outside of any complex layout
                            final screenWidth = MediaQuery.of(context).size.width;
                            final availableWidth = screenWidth - 10; // Account for horizontal padding (5px each side)
                            final tileWidth = (availableWidth / nTule) - 0.1; // Slight reduction to prevent overflow
                            final tileHeight = tileWidth;

                            // Create list of all items including add button
                            final allItems = <Widget>[
                              for (var i = 0; i < frozenWalletsWithoutIdty.length; i++)
                                DragTuleAction(
                                  key: ValueKey(
                                    'wallet_container_${frozenWalletsWithoutIdty[i].address}_${widget.safeFingerprint}_$i',
                                  ),
                                  wallet: frozenWalletsWithoutIdty[i],
                                  child: WalletTile(
                                    repository: frozenWalletsWithoutIdty[i],
                                    tutorialKey: i == targetWalletIndex ? tutorialKey : null,
                                    uniqueId: 'grid_${widget.safeFingerprint}_$i',
                                    currentSafe: currentSafe.number,
                                    hasIdentityWallet: idtyWallet != null,
                                  ),
                                ),
                              if (ref.read(durtProvider).isConnected &&
                                  frozenWalletsWithoutIdty.length < maxWalletsInSafe)
                                const AddNewDerivationButton(),
                            ];

                            // Build rows manually using Expanded to avoid overflow
                            final rows = <Widget>[];
                            for (int i = 0; i < allItems.length; i += nTule) {
                              final rowItems = <Widget>[];
                              for (int j = 0; j < nTule; j++) {
                                if (i + j < allItems.length) {
                                  rowItems.add(
                                    Expanded(
                                      child: SizedBox(height: tileHeight, child: allItems[i + j]),
                                    ),
                                  );
                                } else {
                                  rowItems.add(Expanded(child: SizedBox(height: tileHeight)));
                                }
                              }
                              rows.add(Row(children: rowItems));
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Column(children: rows),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SafeOptionsButtons()),
                    ],
                  ),
                ),
              ),
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
          final container = ProviderScope.containerOf(context);
          // Reset drag state
          container.read(dragDropProvider.notifier).clearDrag();

          // Fix route if it's empty (the main bug!)

          final currentRoute = container.read(currentRouteProvider);
          if (currentRoute.isEmpty || currentRoute != RouteNames.myWallets) {
            container.read(currentRouteProvider.notifier).set(RouteNames.myWallets);
          }

          // Show bottom app bar again when tutorial closes
          container.read(bottomAppBarProvider.notifier).setDialogVisible(false);
        } catch (e) {
          // Silent fallback
        }
      }
    });
  }
}
