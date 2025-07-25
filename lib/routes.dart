import 'package:flutter/material.dart';
import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:gecko/screens/home/home_screen.dart';
import 'package:gecko/screens/myWallets/restore_safe.dart';
import 'package:gecko/screens/myWallets/show_seed.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:gecko/screens/onBoarding/10.dart';
import 'package:gecko/screens/onBoarding/11_congratulations.dart';
import 'package:gecko/screens/onBoarding/2.dart';
import 'package:gecko/screens/onBoarding/3.dart';
import 'package:gecko/screens/onBoarding/4.dart';
import 'package:gecko/screens/onBoarding/5.dart';
import 'package:gecko/screens/onBoarding/6.dart';
import 'package:gecko/screens/onBoarding/7.dart';
import 'package:gecko/screens/onBoarding/8.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:gecko/screens/search.dart';
import 'package:gecko/screens/search_result.dart';

/// Base class for route arguments - provides type safety
abstract class RouteArguments {}

/// Route arguments for routes that don't need parameters
class NoArguments extends RouteArguments {}

/// Arguments for unlocking wallet route
class UnlockingWalletArguments extends RouteArguments {
  final WalletEntity wallet;
  final bool canSwitch;

  UnlockingWalletArguments({required this.wallet, this.canSwitch = false});
}

/// Arguments for onboarding step 5
class OnboardingStepFiveArguments extends RouteArguments {
  final bool skipIntro;

  OnboardingStepFiveArguments({this.skipIntro = false});
}

/// Arguments for onboarding step 6
class OnboardingStepSixArguments extends RouteArguments {
  final bool skipIntro;
  final String? generatedMnemonic;

  OnboardingStepSixArguments({this.skipIntro = false, required this.generatedMnemonic});
}

/// Arguments for onboarding steps 7, 8, 9
class OnboardingStepsSevenToNineArguments extends RouteArguments {
  final bool scanDerivation;
  final bool fromRestore;

  OnboardingStepsSevenToNineArguments({this.scanDerivation = false, this.fromRestore = false});
}

/// Arguments for onboarding step 10
class OnboardingStepTenArguments extends RouteArguments {
  final bool scanDerivation;
  final bool fromRestore;
  final String pinCode;

  OnboardingStepTenArguments({this.scanDerivation = false, this.fromRestore = false, required this.pinCode});
}

/// Arguments for onboarding step 11
class OnboardingStepElevenArguments extends RouteArguments {
  final bool fromRestore;
  final String? pinCode; // Add PIN code parameter

  OnboardingStepElevenArguments({this.fromRestore = false, this.pinCode});
}

/// Arguments for restore safe
class RestoreSafeArguments extends RouteArguments {
  final bool skipIntro;

  RestoreSafeArguments({this.skipIntro = false});
}

/// Arguments for print wallet
class PrintWalletArguments extends RouteArguments {
  final String sentence;

  PrintWalletArguments({required this.sentence});
}

/// Route name constants
class RouteNames {
  static const String home = '/';
  static const String myWallets = '/mywallets';
  static const String search = '/search';
  static const String searchResult = '/searchResult';
  static const String unlockingWallet = '/unlockingWallet';
  static const String onboardingStepOne = '/onboardingStepOne';
  static const String onboardingStepTwo = '/onboardingStepTwo';
  static const String onboardingStepThree = '/onboardingStepThree';
  static const String onboardingStepFour = '/onboardingStepFour';
  static const String onboardingStepFive = '/onboardingStepFive';
  static const String onboardingStepSix = '/onboardingStepSix';
  static const String onboardingStepSeven = '/onboardingStepSeven';
  static const String onboardingStepEight = '/onboardingStepEight';
  static const String onboardingStepNine = '/onboardingStepNine';
  static const String onboardingStepTen = '/onboardingStepTen';
  static const String onboardingStepEleven = '/onboardingStepEleven';
  static const String restoreSafe = '/restoreSafe';
  static const String printWallet = '/printWallet';
}

/// Helper class for type-safe route extraction
class RouteUtils {
  /// Safely extract typed arguments from route
  static T getArguments<T extends RouteArguments>(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is T) {
      return arguments;
    }
    // If arguments are null or wrong type, return a default instance
    // This requires each argument class to have a default constructor
    throw Exception('Invalid route arguments: expected $T, got ${arguments.runtimeType}');
  }

  /// Safe extraction with fallback for optional arguments
  static T? getOptionalArguments<T extends RouteArguments>(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is T ? arguments : null;
  }
}

/// Type-safe navigation helper
class AppNavigator {
  /// Navigate to a route without arguments
  static Future<T?> pushNamed<T extends Object?>(BuildContext context, String routeName) {
    return Navigator.pushNamed<T>(context, routeName);
  }

  /// Navigate to a route with typed arguments
  static Future<T?> pushNamedWithArguments<T extends Object?>(
    BuildContext context,
    String routeName,
    RouteArguments arguments,
  ) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Navigate with FaderTransition
  static Future<T?> pushWithFader<T extends Object?>(
    BuildContext context,
    String routeName, {
    RouteArguments? arguments,
    bool isFast = false,
  }) {
    final routeBuilder = AppRoutes.getRoutes()[routeName];
    if (routeBuilder == null) {
      throw Exception('Route $routeName not found');
    }

    final route = PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName, arguments: arguments),
      pageBuilder: (context, animation, secondaryAnimation) => routeBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = isFast
            ? Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn))
            : Tween<double>(begin: 0.0, end: 1.0).animate(animation);
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
    );
    return Navigator.push<T>(context, route);
  }

  /// Navigate with FaderTransition and remove all previous routes
  static Future<T?> pushAndRemoveUntilWithFader<T extends Object?>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    RouteArguments? arguments,
    bool isFast = false,
  }) {
    final routeBuilder = AppRoutes.getRoutes()[routeName];
    if (routeBuilder == null) {
      throw Exception('Route $routeName not found');
    }

    final route = PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName, arguments: arguments),
      pageBuilder: (context, animation, secondaryAnimation) => routeBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = isFast
            ? Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn))
            : Tween<double>(begin: 0.0, end: 1.0).animate(animation);
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
    );
    return Navigator.pushAndRemoveUntil<T>(context, route, predicate);
  }

  /// Specific navigation methods for each route with arguments
  static Future<void> toUnlockingWallet(BuildContext context, WalletEntity wallet, {bool canSwitch = false}) {
    return pushNamedWithArguments(
      context,
      RouteNames.unlockingWallet,
      UnlockingWalletArguments(wallet: wallet, canSwitch: canSwitch),
    );
  }

  static Future<void> toOnboardingStepFive(BuildContext context, {bool skipIntro = false}) {
    return pushNamedWithArguments(
      context,
      RouteNames.onboardingStepFive,
      OnboardingStepFiveArguments(skipIntro: skipIntro),
    );
  }

  static Future<void> toOnboardingStepSix(BuildContext context, String generatedMnemonic, {bool skipIntro = false}) {
    return pushNamedWithArguments(
      context,
      RouteNames.onboardingStepSix,
      OnboardingStepSixArguments(skipIntro: skipIntro, generatedMnemonic: generatedMnemonic),
    );
  }

  static Future<void> toOnboardingStepSeven(
    BuildContext context, {
    bool scanDerivation = false,
    bool fromRestore = false,
  }) {
    return pushNamedWithArguments(
      context,
      RouteNames.onboardingStepSeven,
      OnboardingStepsSevenToNineArguments(scanDerivation: scanDerivation, fromRestore: fromRestore),
    );
  }

  static Future<void> toOnboardingStepEight(
    BuildContext context, {
    bool scanDerivation = false,
    bool fromRestore = false,
  }) {
    return pushNamedWithArguments(
      context,
      RouteNames.onboardingStepEight,
      OnboardingStepsSevenToNineArguments(scanDerivation: scanDerivation, fromRestore: fromRestore),
    );
  }

  static Future<void> toOnboardingStepNine(
    BuildContext context, {
    bool scanDerivation = false,
    bool fromRestore = false,
  }) {
    return pushNamedWithArguments(
      context,
      RouteNames.onboardingStepNine,
      OnboardingStepsSevenToNineArguments(scanDerivation: scanDerivation, fromRestore: fromRestore),
    );
  }

  static Future<void> toOnboardingStepTen(
    BuildContext context,
    String pinCode, {
    bool scanDerivation = false,
    bool fromRestore = false,
  }) {
    return pushNamedWithArguments(
      context,
      RouteNames.onboardingStepTen,
      OnboardingStepTenArguments(scanDerivation: scanDerivation, fromRestore: fromRestore, pinCode: pinCode),
    );
  }

  static Future<void> toOnboardingStepEleven(BuildContext context, {bool fromRestore = false, String? pinCode}) {
    return pushNamedWithArguments(
      context,
      RouteNames.onboardingStepEleven,
      OnboardingStepElevenArguments(fromRestore: fromRestore, pinCode: pinCode),
    );
  }
}

/// Application routes configuration
class AppRoutes {
  /// Generate all application routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      RouteNames.home: (context) => const HomeScreen(),
      RouteNames.myWallets: (context) => const WalletsHome(),
      RouteNames.search: (context) => const SearchScreen(),
      RouteNames.searchResult: (context) => const SearchResultScreen(),
      RouteNames.unlockingWallet: (context) {
        try {
          final args = RouteUtils.getArguments<UnlockingWalletArguments>(context);
          return UnlockingWallet(wallet: args.wallet, canSwitch: args.canSwitch);
        } catch (e) {
          // Fallback for backward compatibility
          return const Scaffold(body: Center(child: Text('Error: Invalid arguments for unlocking wallet')));
        }
      },
      RouteNames.onboardingStepOne: (context) => const OnboardingStepOne(),
      RouteNames.onboardingStepTwo: (context) => const OnboardingStepTwo(),
      RouteNames.onboardingStepThree: (context) => const OnboardingStepThree(),
      RouteNames.onboardingStepFour: (context) => const OnboardingStepFour(),
      RouteNames.onboardingStepFive: (context) {
        final args = RouteUtils.getOptionalArguments<OnboardingStepFiveArguments>(context);
        return OnboardingStepFive(skipIntro: args?.skipIntro ?? false);
      },
      RouteNames.onboardingStepSix: (context) {
        final args = RouteUtils.getArguments<OnboardingStepSixArguments>(context);
        return OnboardingStepSix(skipIntro: args.skipIntro, generatedMnemonic: args.generatedMnemonic);
      },
      RouteNames.onboardingStepSeven: (context) {
        final args = RouteUtils.getArguments<OnboardingStepsSevenToNineArguments>(context);
        return OnboardingStepSeven(scanDerivation: args.scanDerivation, fromRestore: args.fromRestore);
      },
      RouteNames.onboardingStepEight: (context) {
        final args = RouteUtils.getArguments<OnboardingStepsSevenToNineArguments>(context);
        return OnboardingStepEight(scanDerivation: args.scanDerivation, fromRestore: args.fromRestore);
      },
      RouteNames.onboardingStepNine: (context) {
        final args = RouteUtils.getArguments<OnboardingStepsSevenToNineArguments>(context);
        return OnboardingStepNine(scanDerivation: args.scanDerivation, fromRestore: args.fromRestore);
      },
      RouteNames.onboardingStepTen: (context) {
        final args = RouteUtils.getArguments<OnboardingStepTenArguments>(context);
        return OnboardingStepTen(
          scanDerivation: args.scanDerivation,
          fromRestore: args.fromRestore,
          pinCode: args.pinCode,
        );
      },
      RouteNames.onboardingStepEleven: (context) {
        final args = RouteUtils.getOptionalArguments<OnboardingStepElevenArguments>(context);
        return OnboardingStepEleven(fromRestore: args?.fromRestore ?? false);
      },
      RouteNames.restoreSafe: (context) {
        final args = RouteUtils.getOptionalArguments<RestoreSafeArguments>(context);
        return RestoreSafe(skipIntro: args?.skipIntro ?? false);
      },
      RouteNames.printWallet: (context) {
        final args = RouteUtils.getArguments<PrintWalletArguments>(context);
        return PrintWallet(args.sentence);
      },
    };
  }

  /// Initial route for the application
  static const String initialRoute = RouteNames.home;
}
