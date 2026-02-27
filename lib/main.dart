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
import 'dart:io';
import 'package:durt2/durt2.dart' show Durt, Networks, KeyPairType, SslConfigService;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope, Consumer;
import 'package:gecko/globals.dart';
import 'package:gecko/providers/text_scaling_provider.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';
import 'package:gecko/providers/squid_invalidation_provider.dart';
import 'package:gecko/providers/app_lifecycle_provider.dart';

import 'package:flutter/material.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/version_overlay.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/providers/theme_provider.dart';
import 'package:gecko/services/storage_init_service.dart';
import 'package:gecko/services/app_info_service.dart';
import 'package:gecko/services/sentry_service.dart';
import 'package:gecko/services/log_collection_service.dart';
import 'package:gecko/services/g1_genesis_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/services/empty_string_asset_loader.dart';

import 'package:gecko/widgets/global_offline_overlay.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/sentry_context_provider.dart';
import 'package:gecko/widgets/certify/ready_certification_listener.dart';

const bool enableSentry = true;
const bool showVersionOverlay = true; // Set to false to hide version overlay in production

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await EasyLocalization.ensureInitialized();

  // Initialize storage service
  final storageService = StorageInitService();
  if (!storageService.isInitialized) {
    await initHiveForFlutter();
    await storageService.initHive();
  } else {
    log.i('Storage service already initialized, skipping Hive setup');
  }

  // Initialize log collection service
  LogCollectionService.instance.initialize();

  // Check G1 genesis hash (blocking on first run, cached after)
  final g1Available = await G1GenesisService.initializeAtStartup(configBox);

  // Network selection: local override preserved, then g1 if available, else default (gtest)
  final savedNetwork = configBox.get('selectedNetwork');
  final Networks selectedNetwork;
  if (savedNetwork == Networks.local.name) {
    selectedNetwork = Networks.local;
  } else if (g1Available) {
    selectedNetwork = Networks.g1;
  } else {
    selectedNetwork = Networks.defaultNetwork;
  }

  // Sync the saved network so the rest of the app is consistent
  configBox.put('selectedNetwork', selectedNetwork.name);

  // Clear any custom endpoint configuration to ensure clean connection
  configBox.delete('customEndpoint');
  configBox.delete('customIndexer');
  configBox.put('autoEndpoint', true);

  // Configure SSL certificate handling before any network connections.
  // Duniter nodes commonly use self-signed certificates, so we must accept them.
  // This is acceptable because blockchain data integrity is verified by cryptographic
  // signatures, not TLS — transactions and blocks are always validated locally.
  // On Android, this also handles older devices with outdated CA certificate stores.
  // TODO: Implement per-endpoint certificate pinning for CesiumPlus profile API.
  SslConfigService.configureSslCertificateHandling(allowBadCertificates: !kReleaseMode || Platform.isAndroid);

  //Init durt2 with selected network and keypair type
  await Durt().init(network: selectedNetwork, keyPairType: KeyPairType.ed25519);

  // Migrate old wallet names to new # convention
  WalletNameService.runMigration();

  // Initialize app info service and get version
  final appInfoService = AppInfoService();
  await appInfoService.init();
  appVersion = appInfoService.appVersion;

  // Read user's language preference
  final savedLocale = configBox.get('localeOverride');
  final startLocale = savedLocale != null ? Locale(savedLocale) : null;

  if (kReleaseMode && enableSentry) {
    await SentryService.init(
      dsn: 'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110',
      appRunner: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
        runApp(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('es'), Locale('it')],
            path: 'assets/translations',
            assetLoader: const EmptyStringAssetLoader(),
            fallbackLocale: const Locale('en'),
            startLocale: startLocale,
            child: const Gecko(),
          ),
        );
      }),
    );
  } else {
    log.w('Sentry disabled');

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('es'), Locale('it')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: startLocale,
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
      child: Consumer(
        builder: (context, ref, _) {
          // Activate the Squid endpoint change notifier to enable provider invalidation
          ref.watch(squidEndpointChangeNotifierProvider);

          // Activate lifecycle observer for WebSocket reconnection after background
          ref.watch(appLifecycleProvider);

          return SentryContextProvider(
            child: Builder(
              builder: (context) {
                // Create the navigator observer with Riverpod ref
                final navigatorObserver = BottomAppBarNavigatorObserver(ref);
                final textScale = ref.watch(textScalingProvider);
                final themeMode = ref.watch(currentThemeModeProvider);

                return MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: themeMode,
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
                    // Wrap with ReadyCertificationListener to handle certification ready notifications globally
                    return ReadyCertificationListener(
                      child: Stack(
                        children: [
                          GlobalOfflineOverlay(child: finalChild),
                          Positioned(bottom: 0, left: 0, right: 0, child: const GlobalBottomAppBar()),
                        ],
                      ),
                    );
                  },
                  title: 'Ğecko',
                  initialRoute: AppRoutes.initialRoute,
                  routes: AppRoutes.getRoutes(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
