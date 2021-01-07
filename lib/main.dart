import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gecko/ui/home.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';

// void main() => runApp(Gecko());

Future<void> main() async {
  if (kReleaseMode) {
    print('Release');
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://c09587b46eaa42e8b9fda28d838ed180@o496840.ingest.sentry.io/5572110';
      },
      appRunner: () => runApp(Gecko()),
    );
  } else {
    print('Debug');
    runApp(Gecko());
  }
}

class Gecko extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _httpLink = HttpLink(
      // 'http://192.168.1.91:10060/gva',
      'https://g1.librelois.fr/gva',
    );

    final _client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(store: null),
        link: _httpLink,
      ),
    );
    return MaterialApp(
      title: 'Ğecko',
      theme:
          ThemeData(primaryColor: Colors.blue[50], accentColor: Colors.black),
      home: GraphQLProvider(
        client: _client,
        child: HomeScreen(),
      ),
    );
  }
}
