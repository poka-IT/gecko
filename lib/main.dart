//  Copyright (C) 2022 Axiom-Team.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';
import 'package:durt2/durt2.dart' show Durt, Networks, KeyPairType;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope, Consumer;
import 'package:gecko/globals.dart';
import 'package:gecko/providers/text_scaling_provider.dart';
import 'package:gecko/providers_deprecated/bottom_app_bar_provider.dart';
import 'package:gecko/providers_deprecated/safe_provider.dart';
import 'package:gecko/providers_deprecated/g1v1_migration.provider.dart';
import 'package:gecko/providers_deprecated/generate_wallets.dart';
import 'package:gecko/providers_deprecated/settings_provider.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/providers_deprecated/home.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers_deprecated/search.dart';
import 'package:gecko/providers_deprecated/wallet_options.dart';
import 'package:flutter/material.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/version_overlay.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:flutter/foundation.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/providers_deprecated/theme_provider.dart';
import 'package:gecko/providers_deprecated/block_height_provider.dart';
import 'package:gecko/widgets/global_offline_overlay.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';

const bool enableSentry = true;
const bool showVersionOverlay = true; // Set to false to hide version overlay in production

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final homeProvider = HomeProvider();

  // Initialize Hive first to access configBox
  await initHiveForFlutter();
  await homeProvider.initHive();

  // Get saved network from config or default to gtest
  final savedNetworkName = configBox.get('selectedNetwork') ?? 'gtest';
  final selectedNetwork = Networks.values.firstWhere(
    (network) => network.name == savedNetworkName,
    orElse: () => Networks.gtest,
  );

  //Init durt2 with selected network and keypair type
  await Durt().init(network: selectedNetwork, keyPairType: KeyPairType.ed25519);

  appVersion = await homeProvider.getAppVersion();

  if (kReleaseMode && enableSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110';
        options.replay.sessionSampleRate = 1.0;
        options.replay.onErrorSampleRate = 1.0;
        // Privacy settings for PII masking
        //TODO: Set this to false in production for Ğ1
        options.privacy.maskAllText = false;
        options.privacy.maskAllImages = false;
      },
      appRunner: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
        runApp(
          SentryWidget(
            child: EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('es'), Locale('it')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: const Gecko(),
            ),
          ),
        );
      }),
    );
  } else {
    log.i('Debug mode enabled: No sentry alert');

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(
        EasyLocalization(
          // test, force locale :: startLocale: Locale.fromSubtags(languageCode: 'it'),
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('es'), Locale('it')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: const Gecko(),
        ),
      );
    });
  }
}

class Gecko extends StatelessWidget {
  const Gecko({super.key});

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext? get navigatorContext => _navigatorKey.currentContext;

  @override
  Widget build(BuildContext context) {
    // To configure multi_endpoints GraphQLProvider: https://stackoverflow.com/q/70656513/8301867

    return ProviderScope(
      child: old_provider.MultiProvider(
        providers: [
          old_provider.ChangeNotifierProvider(create: (_) => HomeProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => WalletsProfilesProvider('')),
          old_provider.ChangeNotifierProvider(create: (_) => MyWalletsProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => SafeProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => GenerateWalletsProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => WalletOptionsProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => SearchProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => SettingsProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => BlockHeightProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => G1v1MigrationProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => BottomAppBarProvider()),
          old_provider.ChangeNotifierProvider(create: (_) => CurrentRouteProvider()),
        ],
        child: old_provider.Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            // Create the bottom app bar provider and observer
            final bottomAppBarProvider = old_provider.Provider.of<BottomAppBarProvider>(context, listen: false);
            final currentRouteProvider = old_provider.Provider.of<CurrentRouteProvider>(context, listen: false);
            final navigatorObserver = BottomAppBarNavigatorObserver(bottomAppBarProvider, currentRouteProvider);

            return Consumer(
              builder: (context, ref, _) {
                final textScale = ref.watch(textScalingProvider);

                return MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: themeProvider.currentThemeMode,
                  navigatorKey: _navigatorKey,
                  navigatorObservers: [
                    navigatorObserver,
                    // Add RouteObserver for immediate bottom bar state updates
                    globalRouteObserver,
                  ],
                  builder: (context, child) {
                    // Apply text scaling using Builder to preserve original MediaQuery context
                    final scaledChild = Builder(
                      builder: (builderContext) {
                        final originalData = MediaQuery.of(builderContext);
                        return MediaQuery(
                          data: originalData.copyWith(textScaler: TextScaler.linear(textScale)),
                          child: child!,
                        );
                      },
                    );

                    final responsiveChild = ResponsiveBreakpoints.builder(
                      child: scaledChild,
                      breakpoints: [
                        const Breakpoint(start: 0, end: 450, name: MOBILE),
                        const Breakpoint(start: 451, end: 800, name: TABLET),
                        const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
                      ],
                    );

                    // Wrap with padding wrapper to avoid content being hidden behind bottom bar
                    final childWithPadding = PageWithBottomPaddingWrapper(child: responsiveChild);

                    // Wrap with offline overlay and version overlay
                    final finalChild = showVersionOverlay ? VersionOverlay(child: childWithPadding) : childWithPadding;

                    // Add the global bottom app bar as an overlay
                    return Stack(
                      children: [
                        GlobalOfflineOverlay(child: finalChild),
                        Positioned(bottom: 0, left: 0, right: 0, child: const GlobalBottomAppBar()),
                      ],
                    );
                  },
                  title: 'Ğecko',
                  initialRoute: AppRoutes.initialRoute,
                  routes: AppRoutes.getRoutes(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
