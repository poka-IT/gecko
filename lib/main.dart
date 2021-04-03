//  Copyright (C) 2020 Axiom-Team.
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
import 'package:gecko/models/cesiumPlus.dart';
import 'package:gecko/models/changePin.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/home.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:gecko/screens/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/walletsHome.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final bool enableSentry = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HomeProvider _homeProvider = HomeProvider();
  MyWalletsProvider _walletsProvider = MyWalletsProvider();
  await _homeProvider.getAppPath();
  await _homeProvider.createDefaultAvatar();
  await _walletsProvider.initWalletFolder();
  _walletsProvider.getDefaultWallet();
  appVersion = await _homeProvider.getAppVersion();
  prefs = await SharedPreferences.getInstance();
  // final HiveStore _store =
  //     await HiveStore.open(path: '${appPath.path}/gqlCache');

  // Get a valid GVA endpoint
  endPointGVA = await _homeProvider.getValidEndpoint();

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

    await SentryFlutter.init((options) {
      options.dsn =
          'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110';
    }, appRunner: () => runApp(Gecko(endPointGVA)));

    // runZoned<Future<void>>(
    //       () async {
    //         runApp(Gecko(endPointGVA, _store));
    //       },
    //       onError: (dynamic error, StackTrace stackTrace) {
    //         print("=================== CAUGHT DART ERROR");
    //         // Sentry.captureException(
    //         //   error,
    //         //   stackTrace: stackTrace,
    //         // );
    //       },
    //     ));
  } else {
    print('Debug mode enabled: No sentry alerte');

    runApp(Gecko(endPointGVA));
  }
}

class Gecko extends StatelessWidget {
  Gecko(this.randomEndpoint);
  final String randomEndpoint;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final _httpLink = HttpLink(
      randomEndpoint,
    );

    final _client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(),
        link: _httpLink,
      ),
    );

    // HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    // HistoryProvider('').snackNode(context);
    return MultiProvider(
        providers: [
          // Provider(create: (context) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider('')),
          ChangeNotifierProvider(create: (_) => MyWalletsProvider()),
          ChangeNotifierProvider(create: (_) => GenerateWalletsProvider()),
          ChangeNotifierProvider(create: (_) => WalletOptionsProvider()),
          ChangeNotifierProvider(create: (_) => ChangePinProvider()),
          ChangeNotifierProvider(create: (_) => CesiumPlusProvider())
        ],
        child: GraphQLProvider(
          client: _client,
          child: MaterialApp(
            builder: (context, widget) => ResponsiveWrapper.builder(
                BouncingScrollWrapper.builder(context, widget),
                maxWidth: 1200,
                minWidth: 480,
                defaultScale: true,
                breakpoints: [
                  ResponsiveBreakpoint.resize(480, name: MOBILE),
                  ResponsiveBreakpoint.autoScale(800, name: TABLET),
                  ResponsiveBreakpoint.resize(1000, name: DESKTOP),
                ],
                background: Container(color: Color(0xFFF5F5F5))),
            title: 'Ğecko',
            theme: ThemeData(
              primaryColor: Color(0xffFFD58D),
              accentColor: Colors.grey[850],
              textTheme: TextTheme(
                bodyText1: TextStyle(),
                bodyText2: TextStyle(),
              ).apply(
                bodyColor: Color(0xff855F2D),
              ),
            ),
            home: HomeScreen(),
            initialRoute: "/",
            routes: {
              '/mywallets': (context) => WalletsHome(),
            },
          ),
        ));
  }
}
