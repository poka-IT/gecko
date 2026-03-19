import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/main.dart';
import 'package:gecko/widgets/drag_wallets_info.dart';

/// Global widget that shows bottom app bar when appropriate
class GlobalBottomAppBar extends ConsumerWidget {
  const GlobalBottomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // Never show bottom bar in desktop layout
      if (isDesktopLayout(context)) {
        return const SizedBox.shrink();
      }

      final bottomBarState = ref.watch(bottomAppBarProvider);
      if (!bottomBarState.isBottomBarActuallyVisible) {
        return const SizedBox.shrink(); // Hidden
      }

      // Also check if wallets exist - never show bottom bar without safes
      final isWalletsExists = ref.watch(isWalletsExistsProvider);
      if (!isWalletsExists) {
        return const SizedBox.shrink(); // Hidden - no safes
      }

      final currentRoute = ref.watch(currentRouteProvider);

      // Special case for wallets home with drag functionality
      if (currentRoute == RouteNames.myWallets) {
        // Watch drag state for changes
        final dragState = ref.watch(dragDropProvider);
        return dragState.lastFlyBy == null
            ? const _GeckoBottomAppBar(actualRoute: 'safeHome')
            : SafeArea(
                child: DragWalletsInfo(lastFlyBy: dragState.lastFlyBy!, dragAddress: dragState.dragAddress!),
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
class PageWithBottomPaddingWrapper extends ConsumerWidget {
  const PageWithBottomPaddingWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // No bottom padding needed in desktop layout
      if (isDesktopLayout(context)) {
        return child;
      }

      final bottomBarState = ref.watch(bottomAppBarProvider);

      // If bottom bar should not be shown, return child as-is
      if (!bottomBarState.isBottomBarActuallyVisible) {
        return child;
      }

      final isWalletsExists = ref.watch(isWalletsExistsProvider);
      if (!isWalletsExists) {
        return child;
      }

      // Add bottom padding to prevent content from being hidden behind bottom bar
      // Must use scaleSize to match the actual bottom bar height
      final bottomPadding = scaleSize(67);

      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: child,
      );
    } catch (e) {
      // If provider access fails (during navigation), just return child without padding
      return child;
    }
  }
}

class _GeckoBottomAppBar extends ConsumerStatefulWidget {
  const _GeckoBottomAppBar({this.actualRoute = ''});
  final String actualRoute;

  @override
  ConsumerState<_GeckoBottomAppBar> createState() => _GeckoBottomAppBarState();
}

class _GeckoBottomAppBarState extends ConsumerState<_GeckoBottomAppBar> {
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
    final walletsState = ref.watch(walletsListProvider);

    final size = MediaQuery.of(context).size;
    final currentRoute = ref.watch(currentRouteProvider);

    // Check if we're in mono wallet mode (only one wallet in the safe)
    final isMonoWalletMode = walletsState.wallets.length == 1;

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  key: keyAppBarHome,
                  icon: Icons.home_outlined,
                  isSelected: false,
                  semanticLabel: 'Home',
                  onTap: () {
                    final navContext = Gecko.navigatorContext;
                    if (navContext == null) return;
                    Navigator.popUntil(navContext, ModalRoute.withName(RouteNames.home));
                  },
                ),
                _buildNavItem(
                  key: keyAppBarQrcode,
                  imagePath: 'assets/qrcode-scan.png',
                  isSelected: widget.actualRoute == 'scan',
                  semanticLabel: 'Scan QR code',
                  onTap: () async {
                    final scanQr = ref.read(qrScanProvider);
                    await scanQr(context);
                  },
                ),
                _buildNavItem(
                  key: keyAppBarSafe,
                  imagePath: 'assets/wallet.png',
                  isSelected: lockAction,
                  isDisabled: lockAction,
                  semanticLabel: 'My wallets',
                  onTap: lockAction
                      ? null
                      : () async {
                          if (!await PinCodeService.askPinCode(context, canSwitch: true)) return;

                          if (!mounted) return;
                          final navContext = Gecko.navigatorContext;
                          if (navContext == null) return;
                          Navigator.pushNamedAndRemoveUntil(
                            navContext, // ignore: use_build_context_synchronously
                            RouteNames.myWallets,
                            ModalRoute.withName(RouteNames.home),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
    required bool isSelected,
    required VoidCallback? onTap,
    required String semanticLabel,
    IconData? icon,
    String? imagePath,
    bool isDisabled = false,
  }) {
    // Use local context instead of context to avoid deactivated widget errors
    final color = isSelected
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
        : Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8);
    final size = scaleSize(34);

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      enabled: !isDisabled,
      child: Material(
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
      ),
    );
  }
}
