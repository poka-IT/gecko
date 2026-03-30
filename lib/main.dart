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
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope, Consumer;
import 'package:gecko/globals.dart';
import 'package:gecko/providers/text_scaling_provider.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';
import 'package:gecko/providers/squid_invalidation_provider.dart';
import 'package:gecko/providers/app_lifecycle_provider.dart';
import 'package:gecko/providers/deep_link_provider.dart';

import 'package:flutter/material.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/version_overlay.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/providers/theme_provider.dart';
import 'package:gecko/services/storage_init_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gecko/services/app_info_service.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/services/sentry_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:gecko/services/log_collection_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/services/empty_string_asset_loader.dart';
import 'package:gecko/services/eo_locale_delegate.dart';
import 'package:gecko/services/eo_date_symbols.dart';
import 'package:gecko/utils.dart' show safeLocale;
import 'package:timeago/timeago.dart' as timeago;
import 'package:gecko/services/eo_timeago_messages.dart';

import 'package:gecko/widgets/global_offline_overlay.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/sentry_context_provider.dart';
import 'package:gecko/widgets/certify/ready_certification_listener.dart';
import 'package:gecko/widgets/global_search_shortcut_scope.dart';

const bool showVersionOverlay = true; // Set to false to hide version overlay in production

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Configure desktop window size before anything else
  final isDesktop = !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);
  if (isDesktop) {
    await windowManager.ensureInitialized();
  }

  await EasyLocalization.ensureInitialized();

  // Register Esperanto date symbols (not in CLDR/intl package)
  registerEsperantoDateSymbols();

  // Register timeago locales for relative time display
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setLocaleMessages('it', timeago.ItMessages());
  timeago.setLocaleMessages('de', timeago.DeMessages());
  timeago.setLocaleMessages('eo', EoMessages());

  // Initialize storage service
  final storageService = StorageInitService();
  if (!storageService.isInitialized) {
    await storageService.initHive();
  } else {
    log.i('Storage service already initialized, skipping Hive setup');
  }

  // Initialize log collection service
  LogCollectionService.instance.initialize();

  final config = ConfigService(configBox);

  // Network selection: restore saved network, default to g1
  final savedNetwork = config.selectedNetwork;
  final Networks selectedNetwork;
  if (savedNetwork != null) {
    selectedNetwork = Networks.values.firstWhere((n) => n.name == savedNetwork, orElse: () => Networks.defaultNetwork);
  } else {
    selectedNetwork = Networks.defaultNetwork;
    config.selectedNetwork = selectedNetwork.name;
  }

  // Configure SSL certificate handling before any network connections.
  // Duniter nodes commonly use self-signed certificates, so we must accept them.
  // This is acceptable because blockchain data integrity is verified by cryptographic
  // signatures, not TLS — transactions and blocks are always validated locally.
  // On Android, this also handles older devices with outdated CA certificate stores.
  // TODO: Implement per-endpoint certificate pinning for CesiumPlus profile API.
  SslConfigService.configureSslCertificateHandling(allowBadCertificates: !kReleaseMode);

  //Init durt2 with selected network and keypair type
  await Durt().init(network: selectedNetwork, keyPairType: KeyPairType.ed25519);

  // Migrate old wallet names to new # convention
  WalletNameService.runMigration();

  // Initialize app info service and get version
  final appInfoService = AppInfoService();
  await appInfoService.init();
  appVersion = appInfoService.appVersion;

  // Read user's language preference
  final savedLocale = config.localeOverride;
  final startLocale = savedLocale != null ? Locale(savedLocale) : null;

  final enableSentry = config.sentryEnabled;

  // Lock orientation on mobile, configure window on desktop
  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  final easyLocalization = EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('es'), Locale('it'), Locale('eo'), Locale('de')],
    path: 'assets/translations',
    assetLoader: const EmptyStringAssetLoader(),
    fallbackLocale: const Locale('en'),
    useFallbackTranslations: true,
    startLocale: startLocale,
    child: const Gecko(),
  );

  if (kReleaseMode && enableSentry) {
    await SentryService.init(
      dsn: 'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110',
      appRunner: () async {
        runApp(easyLocalization);
        if (isDesktop) await _showDesktopWindow();
      },
    );
  } else {
    log.w('Sentry disabled');
    runApp(easyLocalization);
    if (isDesktop) await _showDesktopWindow();
  }
}

Future<void> _showDesktopWindow() async {
  const defaultSize = Size(1185, 845);

  final config = ConfigService(configBox);

  // Restore saved window size, or use default
  final savedWidth = config.windowWidth;
  final savedHeight = config.windowHeight;
  final size = (savedWidth != null && savedHeight != null) ? Size(savedWidth, savedHeight) : defaultSize;

  // Restore saved window position, if available and on-screen
  final savedX = config.windowX;
  final savedY = config.windowY;
  final hasValidPosition = savedX != null && savedY != null && savedX >= 0 && savedY >= 0;

  final bypassMinSize = config.bypassMinWindowSize;
  const minSize = Size(800, 600);
  final windowOptions = WindowOptions(
    size: size,
    minimumSize: bypassMinSize ? null : minSize,
    center: !hasValidPosition,
    title: 'Ğecko',
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (!bypassMinSize) {
      await windowManager.setMinimumSize(minSize);
    }
    if (hasValidPosition) {
      await windowManager.setPosition(Offset(savedX, savedY));
    }
    await windowManager.show();
    await windowManager.focus();
  });

  // Listen for resize to persist window size, and handle app close cleanup
  windowManager.addListener(_DesktopWindowListener());
  await windowManager.setPreventClose(true);
}

class _DesktopWindowListener extends WindowListener {
  Timer? _saveDebounce;

  void _debounceSaveWindowGeometry() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      final config = ConfigService(configBox);
      config.windowWidth = size.width;
      config.windowHeight = size.height;
      config.windowX = position.dx;
      config.windowY = position.dy;
    });
  }

  @override
  void onWindowResize() => _debounceSaveWindowGeometry();

  @override
  void onWindowMove() => _debounceSaveWindowGeometry();

  @override
  void onWindowClose() async {
    // Clean up Hive boxes to release file locks and avoid mutex deadlocks on Windows
    try {
      await Hive.close();
    } catch (e) {
      // Best effort — don't block shutdown
    }
    await windowManager.destroy();
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

          // Activate deep link listener for june:// URIs
          ref.watch(deepLinkProvider);

          return SentryWidget(
            child: SentryContextProvider(
              child: Builder(
                builder: (context) {
                  // Create the navigator observer with Riverpod ref
                  final navigatorObserver = BottomAppBarNavigatorObserver(ref);
                  final textScale = ref.watch(textScalingProvider);
                  final themeMode = ref.watch(currentThemeModeProvider);

                  // Override Intl.defaultLocale with a safe fallback for locales
                  // not supported by the intl package (e.g. Esperanto "eo").
                  // easy_localization sets Intl.defaultLocale automatically,
                  // which would crash every DateFormat call for unsupported locales.
                  Intl.defaultLocale = safeLocale(context.locale.languageCode);

                  return MaterialApp(
                    localizationsDelegates: [...eoLocalizationDelegates, ...context.localizationDelegates],
                    supportedLocales: context.supportedLocales,
                    locale: context.locale,
                    theme: lightTheme,
                    darkTheme: darkTheme,
                    themeMode: themeMode,
                    navigatorKey: _navigatorKey,
                    navigatorObservers: [SentryNavigatorObserver(), navigatorObserver, globalRouteObserver],
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
                      final finalChild = showVersionOverlay
                          ? VersionOverlay(child: childWithPadding)
                          : childWithPadding;

                      // Add the global bottom app bar as an overlay
                      // Wrap with ReadyCertificationListener to handle certification ready notifications globally
                      return GlobalSearchShortcutScope(
                        child: ReadyCertificationListener(
                          child: Stack(
                            children: [
                              GlobalOfflineOverlay(child: finalChild),
                              Positioned(bottom: 0, left: 0, right: 0, child: const GlobalBottomAppBar()),
                            ],
                          ),
                        ),
                      );
                    },
                    title: 'Ğecko',
                    initialRoute: AppRoutes.initialRoute,
                    routes: AppRoutes.getRoutes(),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
