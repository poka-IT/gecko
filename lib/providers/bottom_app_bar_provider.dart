// Global RouteObserver for bottom app bar state updates
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/routes.dart';

final RouteObserver<PageRoute> globalRouteObserver = RouteObserver<PageRoute>();

/// State class for bottom app bar visibility
class BottomAppBarState {
  final bool shouldShowBottomBar;
  final bool isKeyboardVisible;
  final bool isDialogVisible;

  const BottomAppBarState({
    required this.shouldShowBottomBar,
    required this.isKeyboardVisible,
    required this.isDialogVisible,
  });

  /// Combined visibility: route-based, keyboard-based, and dialog-based
  bool get isBottomBarActuallyVisible => shouldShowBottomBar && !isKeyboardVisible && !isDialogVisible;

  BottomAppBarState copyWith({bool? shouldShowBottomBar, bool? isKeyboardVisible, bool? isDialogVisible}) {
    return BottomAppBarState(
      shouldShowBottomBar: shouldShowBottomBar ?? this.shouldShowBottomBar,
      isKeyboardVisible: isKeyboardVisible ?? this.isKeyboardVisible,
      isDialogVisible: isDialogVisible ?? this.isDialogVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomAppBarState &&
        other.shouldShowBottomBar == shouldShowBottomBar &&
        other.isKeyboardVisible == isKeyboardVisible &&
        other.isDialogVisible == isDialogVisible;
  }

  @override
  int get hashCode => Object.hash(shouldShowBottomBar, isKeyboardVisible, isDialogVisible);
}

/// Notifier for tracking the current route name
class CurrentRouteNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Provider for tracking the current route name
final currentRouteProvider = NotifierProvider<CurrentRouteNotifier, String>(CurrentRouteNotifier.new);

/// Observer class to handle WidgetsBindingObserver for the notifier
class _BottomAppBarObserver with WidgetsBindingObserver {
  final BottomAppBarNotifier notifier;
  bool _isDisposed = false;

  _BottomAppBarObserver(this.notifier) {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_isDisposed) return;

    try {
      // Safe access to viewInsets without context dependency
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;

      final viewInsets = views.first.viewInsets;
      final bool keyboardVisible = viewInsets.bottom > 0;

      notifier._updateKeyboardVisibility(keyboardVisible);
    } catch (e) {
      // Silently handle any access errors during widget disposal
      return;
    }
  }
}

/// Notifier for bottom app bar state management
class BottomAppBarNotifier extends Notifier<BottomAppBarState> {
  _BottomAppBarObserver? _observer;

  @override
  BottomAppBarState build() {
    _observer = _BottomAppBarObserver(this);
    ref.onDispose(() => _observer?.dispose());

    return const BottomAppBarState(
      shouldShowBottomBar: false, // Home route should not show bottom bar initially
      isKeyboardVisible: false,
      isDialogVisible: false,
    );
  }

  void _updateKeyboardVisibility(bool keyboardVisible) {
    if (state.isKeyboardVisible != keyboardVisible) {
      // Use addPostFrameCallback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state = state.copyWith(isKeyboardVisible: keyboardVisible);
      });
    }
  }

  void updateCurrentPage(String? routeName, Widget? page) {
    // Determine if bottom bar should be shown based on route name
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

    if (state.shouldShowBottomBar != shouldShow) {
      // Use addPostFrameCallback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state = state.copyWith(shouldShowBottomBar: shouldShow);
      });
    }
  }

  void setDialogVisible(bool visible) {
    if (state.isDialogVisible != visible) {
      // Use addPostFrameCallback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state = state.copyWith(isDialogVisible: visible);
      });
    }
  }
}

/// Provider for bottom app bar state management
final bottomAppBarProvider = NotifierProvider<BottomAppBarNotifier, BottomAppBarState>(BottomAppBarNotifier.new);

/// NavigatorObserver to track page changes and update Riverpod providers
class BottomAppBarNavigatorObserver extends NavigatorObserver {
  final WidgetRef ref;

  BottomAppBarNavigatorObserver(this.ref);

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

    // Delay provider updates to avoid modifying during build
    Future(() {
      // Update current route
      ref.read(currentRouteProvider.notifier).set(routeName);

      // Update bottom bar visibility
      ref.read(bottomAppBarProvider.notifier).updateCurrentPage(routeName, null);
    });
  }
}
