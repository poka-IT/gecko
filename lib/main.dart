import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:flutter_html_view';
import 'home.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  runApp(Gecko());
}

class Gecko extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _httpLink = HttpLink(
      uri: 'https://g1.librelois.fr/gva',
    );

    final _client = ValueNotifier(
      GraphQLClient(
        cache: InMemoryCache(),
        link: _httpLink,
      ),
    );
    return MaterialApp(
      title: 'Ğecko',
      theme: ThemeData(primaryColor: Colors.white, accentColor: Colors.black),
      home: GraphQLProvider(
        client: _client,
        child: HistoryListScreen(),
      ),
    );
  }
}
