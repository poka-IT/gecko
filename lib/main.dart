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

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/screens/search.dart';
import 'package:gecko/screens/search_result.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_size/window_size.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

const bool enableSentry = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    setWindowTitle('Ğecko');
    setWindowMinSize(const Size(400, 700));
    setWindowMaxSize(const Size(800, 1000));
  }

  HomeProvider _homeProvider = HomeProvider();
  // DuniterIndexer _duniterIndexer = DuniterIndexer();
  await initHiveForFlutter();
  await _homeProvider.initHive();
  appVersion = await _homeProvider.getAppVersion();
  prefs = await SharedPreferences.getInstance();

  // Reset GraphQL cache
  final cache = HiveStore();
  cache.reset();

  // Configure Hive and open boxes
  Hive.registerAdapter(WalletDataAdapter());
  Hive.registerAdapter(ChestDataAdapter());
  Hive.registerAdapter(G1WalletsListAdapter());
  Hive.registerAdapter(IdAdapter());

  walletBox = await Hive.openBox<WalletData>("walletBox");
  chestBox = await Hive.openBox<ChestData>("chestBox");
  configBox = await Hive.openBox("configBox");
  await Hive.deleteBoxFromDisk('g1WalletsBox');
  g1WalletsBox = await Hive.openBox<G1WalletsList>("g1WalletsBox");

  await _homeProvider.getValidEndpoints();
  // await configBox.delete('isCacheChecked');
  if (configBox.get('isCacheChecked') == null) {
    configBox.put('isCacheChecked', false);
  }
  // log.d(await configBox.get('endpoint'));

  HttpOverrides.global = MyHttpOverrides();

  if (kReleaseMode && enableSentry) {
    // CatcherOptions debugOptions = CatcherOptions(DialogReportMode(), [
    //   SentryHandler(SentryClient(SentryOptions(
    //       dsn:
    //           "https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110")))
    // ]);
    // // CatcherOptions releaseOptions = CatcherOptions(NotificationReportMode(), [
    // //   EmailManualHandler(["poka@p2p.legal"])
    // // ]);
    // Catcher(rootWidget: Gecko(endPointGVA, _store), debugConfig: debugOptions);

    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110';
      },
      appRunner: () => runApp(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: Gecko(indexerEndpoint),
        ),
      ),
    );
  } else {
    print('Debug mode enabled: No sentry alerte');

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
        path: 'assets/translations',
        fallbackLocale: const Locale('fr'),
        child: Gecko(indexerEndpoint),
      ),
    );
  }
}

class Gecko extends StatelessWidget {
  const Gecko(this.indexerEndpoint, {Key? key}) : super(key: key);
  final String? indexerEndpoint;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // To configure multi_endpoints GraphQLProvider: https://stackoverflow.com/q/70656513/8301867

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WalletsProfilesProvider('')),
        ChangeNotifierProvider(create: (_) => MyWalletsProvider()),
        ChangeNotifierProvider(create: (_) => ChestProvider()),
        ChangeNotifierProvider(create: (_) => GenerateWalletsProvider()),
        ChangeNotifierProvider(create: (_) => WalletOptionsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => CesiumPlusProvider()),
        ChangeNotifierProvider(create: (_) => SubstrateSdk()),
        ChangeNotifierProvider(create: (_) => DuniterIndexer()),
        ChangeNotifierProvider(create: (_) => SettingsProvider())
      ],
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, widget) => ResponsiveWrapper.builder(
            BouncingScrollWrapper.builder(context, widget!),
            maxWidth: 1200,
            minWidth: 480,
            defaultScale: true,
            breakpoints: [
              const ResponsiveBreakpoint.resize(480, name: MOBILE),
              const ResponsiveBreakpoint.autoScale(800, name: TABLET),
              const ResponsiveBreakpoint.resize(1000, name: DESKTOP),
            ],
            background: Container(color: backgroundColor)),
        title: 'Ğecko',
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            color: Color(0xffFFD58D),
            foregroundColor: Color(0xFF000000),
          ),
          primaryColor: const Color(0xffFFD58D),
          textTheme: const TextTheme(
            bodyText1: TextStyle(fontSize: 16),
            bodyText2: TextStyle(fontSize: 18),
          ).apply(
            bodyColor: const Color(0xFF000000),
          ),
          colorScheme:
              ColorScheme.fromSwatch().copyWith(secondary: Colors.grey[850]),
        ),
        home: const HomeScreen(),
        initialRoute: "/",
        routes: {
          '/mywallets': (context) => const WalletsHome(),
          '/search': (context) => const SearchScreen(),
          '/searchResult': (context) => const SearchResultScreen(),
        },
      ),
    );
  }
}

// This http overriding is needed to fix fail certifcat checking for Duniter node on old Android version
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
