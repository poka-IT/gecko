// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers_deprecated/bottom_app_bar_provider.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers_deprecated/search.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/drag_wallets_info.dart';
import 'package:provider/provider.dart' as old_provider;

/// Global widget that shows bottom app bar when appropriate
class GlobalBottomAppBar extends StatelessWidget {
  const GlobalBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final bottomBarProvider = old_provider.Provider.of<BottomAppBarProvider>(context);
      if (!bottomBarProvider.isBottomBarActuallyVisible) {
        return const SizedBox.shrink(); // Hidden
      }

      // Also check if wallets exist - never show bottom bar without safes
      final myWalletsProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
      if (!myWalletsProvider.isWalletsExists) {
        return const SizedBox.shrink(); // Hidden - no safes
      }

      final currentRouteProvider = old_provider.Provider.of<CurrentRouteProvider>(context);
      final currentRoute = currentRouteProvider.currentRoute;

      // Special case for wallets home with drag functionality
      if (currentRoute == RouteNames.myWallets) {
        // Use Consumer only for MyWalletsProvider to listen to drag state changes
        return old_provider.Consumer<MyWalletsProvider>(
          builder: (context, myWalletsProviderDrag, child) {
            return myWalletsProviderDrag.lastFlyBy == null
                ? const _GeckoBottomAppBar(actualRoute: 'safeHome')
                : SafeArea(
                    child: DragWalletsInfo(
                      lastFlyBy: myWalletsProviderDrag.lastFlyBy!,
                      dragAddress: myWalletsProviderDrag.dragAddress!,
                    ),
                  );
          },
        );
      }

      // Default bottom app bar
      String actualRoute = '';
      if (currentRoute.contains('scan')) {
        actualRoute = 'scan';
      } else if (currentRoute.contains('wallet')) {
        actualRoute = 'wallet';
      }

      return _GeckoBottomAppBar(actualRoute: actualRoute);
    } catch (e) {
      // If provider access fails during navigation, return empty widget
      return const SizedBox.shrink();
    }
  }
}

/// Wrapper that automatically adds bottom app bar to pages when needed
class PageWithBottomPaddingWrapper extends StatelessWidget {
  const PageWithBottomPaddingWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    try {
      final bottomBarProvider = old_provider.Provider.of<BottomAppBarProvider>(context);

      // If bottom bar should not be shown, return child as-is
      if (!bottomBarProvider.isBottomBarActuallyVisible) {
        return child;
      }

      final myWalletsProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
      if (!myWalletsProvider.isWalletsExists) {
        return child;
      }

      // Add bottom padding to prevent content from being hidden behind bottom bar
      // Use a fixed value since scaleSize depends on homeContext which might not be ready
      const bottomPadding = 67.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: bottomPadding),
        child: child,
      );
    } catch (e) {
      // If provider access fails (during navigation), just return child without padding
      return child;
    }
  }
}

class _GeckoBottomAppBar extends StatefulWidget {
  const _GeckoBottomAppBar({this.actualRoute = ''});
  final String actualRoute;

  @override
  State<_GeckoBottomAppBar> createState() => _GeckoBottomAppBarState();
}

class _GeckoBottomAppBarState extends State<_GeckoBottomAppBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final historyProvider = old_provider.Provider.of<WalletsProfilesProvider>(context, listen: false);
    final searchProvider = old_provider.Provider.of<SearchProvider>(context, listen: false);

    final size = MediaQuery.of(context).size;

    return old_provider.Consumer<CurrentRouteProvider>(
      builder: (context, currentRouteProvider, child) {
        // Get current route for immediate state updates
        final currentRoute = currentRouteProvider.currentRoute;

        // Check if we're in mono wallet mode (only one wallet in the safe)
        final isMonoWalletMode = myWalletProvider.listWallets.length == 1;

        // Lock action when on myWallets route OR when on walletOptions in mono wallet mode
        final lockAction =
            currentRoute == RouteNames.myWallets || (currentRoute == RouteNames.walletOptions && isMonoWalletMode);

        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: context.colorScheme.tertiary,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(0, -4), blurRadius: 10),
              ],
            ),
            width: size.width,
            height: scaleSize(67),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  key: keyAppBarHome,
                  icon: Icons.home_outlined,
                  isSelected: false,
                  onTap: () {
                    searchProvider.reload();
                    Navigator.popUntil(homeContext, ModalRoute.withName(RouteNames.home));
                  },
                ),
                _buildNavItem(
                  key: keyAppBarQrcode,
                  imagePath: 'assets/qrcode-scan.png',
                  isSelected: widget.actualRoute == 'scan',
                  onTap: () async {
                    historyProvider.scan(context);
                  },
                ),
                _buildNavItem(
                  key: keyAppBarSafe,
                  imagePath: 'assets/wallet.png',
                  isSelected: lockAction,
                  isDisabled: lockAction,
                  onTap: lockAction
                      ? null
                      : () async {
                          if (!await myWalletProvider.askPinCode(canSwitch: true)) return;

                          Navigator.pushNamedAndRemoveUntil(
                            homeContext,
                            RouteNames.myWallets,
                            ModalRoute.withName(RouteNames.home),
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required Key key,
    required bool isSelected,
    required VoidCallback? onTap,
    IconData? icon,
    String? imagePath,
    bool isDisabled = false,
  }) {
    // Use local context instead of homeContext to avoid deactivated widget errors
    final color = isSelected
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
        : Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8);
    final size = scaleSize(34);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: isDisabled
            ? null
            : () {
                // Safe execution of onTap callback
                if (mounted && onTap != null) {
                  onTap();
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(scaleSize(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5) : Colors.transparent,
          ),
          child: icon != null
              ? Icon(icon, size: size, color: color)
              : Image.asset(imagePath!, height: size, width: size, color: color),
        ),
      ),
    );
  }
}
