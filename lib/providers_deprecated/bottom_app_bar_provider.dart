// Global RouteObserver for bottom app bar state updates
import 'package:flutter/material.dart';
import 'package:gecko/routes.dart';

final RouteObserver<PageRoute> globalRouteObserver = RouteObserver<PageRoute>();

/// Simple provider to track the current route name
class CurrentRouteProvider with ChangeNotifier {
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

/// old_provider.Provider to track the current page and determine if bottom bar should be shown
class BottomAppBarProvider with ChangeNotifier, WidgetsBindingObserver {
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
