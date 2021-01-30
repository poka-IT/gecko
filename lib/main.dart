import 'package:dubp/dubp.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/home.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:gecko/screens/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final bool enableSentry = true;

// Future<String> getJsonEndpoints() {
//   return rootBundle.loadString('config/gva_endpoints.json');
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeProvider _homeProvider = HomeProvider();
  await _homeProvider.getAppPath();
  appVersion = await _homeProvider.getAppVersion();
  prefs = await SharedPreferences.getInstance();

  String randomEndpoint; // = await getRandomEndpoint();
  int i = 0;
  do {
    if (i >= 5) {
      print('NO VALID ENDPOINT FOUND !');
      break;
    }
    if (i != 0) {
      print(i.toString() + ' ème essai de recherche de endpoint GVA.');
      await Future.delayed(Duration(milliseconds: 300));
    }
    randomEndpoint = await _homeProvider.getRandomEndpoint();
    i++;
  } while (randomEndpoint == 'HS');

  if (kReleaseMode && enableSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110';
      },
      appRunner: () => runApp(Gecko(randomEndpoint)),
    );
  } else {
    print('Debug mode enabled: No sentry alerte');

    runApp(Gecko(
      randomEndpoint,
    ));
  }
}

// ignore: must_be_immutable
class Gecko extends StatelessWidget {
  Gecko(this.randomEndpoint);
  final String randomEndpoint;

  @override
  Widget build(BuildContext context) {
    final _httpLink = HttpLink(
      // 'http://192.168.1.91:10060/gva',
      randomEndpoint,
    );

    final _client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(store: null),
        link: _httpLink,
      ),
    );

    DubpRust.setup();
    return MultiProvider(
        providers: [
          // Provider(create: (context) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider('')),
          ChangeNotifierProvider(create: (_) => MyWalletsProvider()),
          ChangeNotifierProvider(create: (_) => GenerateWalletsProvider()),
          ChangeNotifierProvider(create: (_) => WalletOptionsProvider())
        ],
        child: GraphQLProvider(
            client: _client,
            child: MaterialApp(
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
            )));
  }
}
