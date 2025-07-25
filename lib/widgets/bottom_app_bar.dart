// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/drag_wallets_info.dart';
import 'package:provider/provider.dart';

// Global RouteObserver for bottom app bar state updates
final RouteObserver<PageRoute> globalRouteObserver = RouteObserver<PageRoute>();

/// Simple provider to track the current route name
class CurrentRouteProvider extends ChangeNotifier {
  String _currentRoute = '';

  String get currentRoute => _currentRoute;

  void updateRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      // Use addPostFrameCallback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}

/// Provider to track the current page and determine if bottom bar should be shown
class BottomAppBarProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _shouldShowBottomBar = true;
  bool _isKeyboardVisible = false;
  bool _isDialogVisible = false;

  bool get shouldShowBottomBar => _shouldShowBottomBar;
  bool get isKeyboardVisible => _isKeyboardVisible;
  bool get isDialogVisible => _isDialogVisible;

  // Combined visibility: route-based, keyboard-based, and dialog-based
  bool get isBottomBarActuallyVisible => _shouldShowBottomBar && !_isKeyboardVisible && !_isDialogVisible;

  BottomAppBarProvider() {
    WidgetsBinding.instance.addObserver(this);
    // Initialize with correct state for initial route (home)
    // NavigatorObserver is not called for initial route, so we need to set this manually
    _shouldShowBottomBar = false; // Home route should not show bottom bar
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    try {
      // Safe access to viewInsets without context dependency
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;

      final viewInsets = views.first.viewInsets;
      final bool keyboardVisible = viewInsets.bottom > 0;

      if (_isKeyboardVisible != keyboardVisible) {
        _isKeyboardVisible = keyboardVisible;
        // Use addPostFrameCallback to avoid calling notifyListeners during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      // Silently handle any access errors during widget disposal
      return;
    }
  }

  void updateCurrentPage(String? routeName, Widget? page) {
    // Determine if bottom bar should be shown based on route name or page type
    bool shouldShow = true;

    const excludedRoutes = [
      RouteNames.home,
      RouteNames.unlockingWallet,
      RouteNames.restoreSafe,
      RouteNames.onboardingStepOne,
      RouteNames.onboardingStepTwo,
      RouteNames.onboardingStepThree,
      RouteNames.onboardingStepFour,
      RouteNames.onboardingStepFive,
      RouteNames.onboardingStepSix,
      RouteNames.onboardingStepSeven,
      RouteNames.onboardingStepEight,
      RouteNames.onboardingStepNine,
      RouteNames.onboardingStepTen,
      RouteNames.onboardingStepEleven,
      RouteNames.printWallet,
    ];

    if (excludedRoutes.contains(routeName)) {
      shouldShow = false;
    }

    if (_shouldShowBottomBar != shouldShow) {
      _shouldShowBottomBar = shouldShow;
      // Use addPostFrameCallback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void setDialogVisible(bool visible) {
    if (_isDialogVisible != visible) {
      _isDialogVisible = visible;
      // Use addPostFrameCallback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}

/// NavigatorObserver to track page changes
class BottomAppBarNavigatorObserver extends NavigatorObserver {
  final BottomAppBarProvider bottomBarProvider;
  final CurrentRouteProvider currentRouteProvider;

  BottomAppBarNavigatorObserver(this.bottomBarProvider, this.currentRouteProvider);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateProviders(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateProviders(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateProviders(newRoute);
    }
  }

  void _updateProviders(Route<dynamic> route) {
    final routeName = route.settings.name ?? '';

    // Update current route immediately
    currentRouteProvider.updateRoute(routeName);

    // Update bottom bar visibility
    bottomBarProvider.updateCurrentPage(routeName, null);
  }
}

/// Global widget that shows bottom app bar when appropriate
class GlobalBottomAppBar extends StatelessWidget {
  const GlobalBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomAppBarProvider>(
      builder: (context, bottomBarProvider, child) {
        if (!bottomBarProvider.isBottomBarActuallyVisible) {
          return const SizedBox.shrink(); // Hidden
        }

        // Also check if wallets exist - never show bottom bar without safes
        return Consumer<MyWalletsProvider>(
          builder: (context, myWalletsProvider, child) {
            if (!myWalletsProvider.isWalletsExists) {
              return const SizedBox.shrink(); // Hidden - no safes
            }

            return Consumer<CurrentRouteProvider>(
              builder: (context, currentRouteProvider, child) {
                final currentRoute = currentRouteProvider.currentRoute;

                // Special case for wallets home with drag functionality
                if (currentRoute == RouteNames.myWallets) {
                  return myWalletsProvider.lastFlyBy == null
                      ? const _GeckoBottomAppBar(actualRoute: 'safeHome')
                      : SafeArea(
                          child: DragWalletsInfo(
                            lastFlyBy: myWalletsProvider.lastFlyBy!,
                            dragAddress: myWalletsProvider.dragAddress!,
                          ),
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
              },
            );
          },
        );
      },
    );
  }
}

/// Wrapper that automatically adds bottom app bar to pages when needed
class PageWithBottomPaddingWrapper extends StatelessWidget {
  const PageWithBottomPaddingWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomAppBarProvider>(
      builder: (context, bottomBarProvider, _) {
        // If bottom bar should not be shown, return child as-is
        if (!bottomBarProvider.isBottomBarActuallyVisible) {
          return child;
        }

        final myWalletsProvider = Provider.of<MyWalletsProvider>(context, listen: false);
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
      },
    );
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
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final historyProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    final size = MediaQuery.of(context).size;

    return Consumer<CurrentRouteProvider>(
      builder: (context, currentRouteProvider, child) {
        // Get current route for immediate state updates
        final currentRoute = currentRouteProvider.currentRoute;
        final lockAction = currentRoute == RouteNames.myWallets;

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
