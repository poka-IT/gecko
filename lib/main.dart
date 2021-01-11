import 'package:gecko/ui/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
// import 'dart:convert';

final bool enableSentry = true;

// Future<String> getJsonEndpoints() {
//   return rootBundle.loadString('config/gva_endpoints.json');
// }

T getRandomElement<T>(List<T> list) {
  final random = new Random();
  var i = random.nextInt(list.length);
  return list[i];
}

Future<String> getRandomEndpoint() async {
  // TODO: Improve implemention of getRandomEndpoint() with JSON and error handling
  // final _json = json.decode(await getJsonEndpoints());
  // print('JSON !! :');
  // print(_json);
  // final _list = _json[];

  final _list = ['https://g1.librelois.fr/gva'];
  final _endpoint = getRandomElement(_list);
  print('ENDPOINT: ' + _endpoint);

  // http.post(_endpoint);
  final response = await http.post(_endpoint);
  if (response.statusCode != 200) {
    print('Endpoint statutcode: ' + response.statusCode.toString());
    // _endpoint = getRandomElement(_list);
    return 'HS';
  }

  return _endpoint;
}

Future<void> main() async {
  String randomEndpoint; // = await getRandomEndpoint();
  int i = 0;
  do {
    print(i);
    if (i >= 3) {
      print('NO VALID ENDPOINT FOUND !');
      break;
    }
    if (i != 0) {
      await Future.delayed(Duration(milliseconds: 500));
    }
    randomEndpoint = await getRandomEndpoint();
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
    runApp(Gecko(randomEndpoint));
  }
}

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
    return MaterialApp(
      title: 'Ğecko',
      theme: ThemeData(
        primaryColor: Color(0xffD28928),
        accentColor: Color(0xffFFD68E),
        textTheme: TextTheme(
          bodyText1: TextStyle(),
          bodyText2: TextStyle(),
        ).apply(
          bodyColor: Color(0xff855F2D),
          // displayColor: Colors.blue,
        ),
      ),
      home: GraphQLProvider(
        client: _client,
        child: HomeScreen(),
      ),
    );
  }
}
