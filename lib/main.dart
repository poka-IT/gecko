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
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/v2s_datapod.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/screens/search.dart';
import 'package:gecko/screens/search_result.dart';

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

const bool enableSentry = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // if (kDebugMode) {
  //   await dotenv.load();
  // }

  final homeProvider = HomeProvider();
  // DuniterIndexer _duniterIndexer = DuniterIndexer();

  // Initialize Hive
  await initHiveForFlutter();
  await homeProvider.initHive();

  appVersion = await homeProvider.getAppVersion();

  if (kReleaseMode && enableSentry) {
    await SentryFlutter.init((options) {
      options.dsn = 'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110';
    },
        appRunner: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
              runApp(EasyLocalization(
                supportedLocales: const [Locale('en'), Locale('fr'), Locale('es'), Locale('it')],
                path: 'assets/translations',
                fallbackLocale: const Locale('en'),
                child: const Gecko(),
              ));
            }));
  } else {
    log.i('Debug mode enabled: No sentry alert');

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(EasyLocalization(
        // test, force locale :: startLocale: Locale.fromSubtags(languageCode: 'it'),
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('es'), Locale('it')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const Gecko(),
      ));
    });
  }
}

class Gecko extends StatelessWidget {
  const Gecko({super.key});

  @override
  Widget build(BuildContext context) {
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
        ChangeNotifierProvider(create: (_) => SubstrateSdk()),
        ChangeNotifierProvider(create: (_) => DuniterIndexer()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => V2sDatapodProvider())
      ],
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
          ],
        ),
        title: 'Ğecko',
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: headerColor,
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
            bodySmall: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: 'Roboto',
            ),
            labelMedium: TextStyle(
              fontSize: 15,
              fontFamily: 'Monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
          primaryColor: const Color(0xffFFD58D),
          scaffoldBackgroundColor: backgroundColor,
          canvasColor: backgroundColor,
          dialogBackgroundColor: backgroundColor,
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.grey[850]),
        ),
        initialRoute: "/",
        routes: {
          '/': (context) => const HomeScreen(),
          '/mywallets': (context) => const WalletsHome(),
          '/search': (context) => const SearchScreen(),
          '/searchResult': (context) => const SearchResultScreen(),
        },
      ),
    );
  }
}
