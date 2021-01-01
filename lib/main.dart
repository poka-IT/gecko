import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:flutter_html_view';
import 'home.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() => runApp(Gecko());

class Gecko extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _httpLink = HttpLink(
      'http://127.0.0.1:30901/gva',
      // defaultHeaders: <String, String>{
      //   'Content-Type': 'application/json',
      // },
    );

    final _client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(),
        link: _httpLink,
      ),
    );
    return MaterialApp(
      title: 'Ğecko',
      theme:
          ThemeData(primaryColor: Colors.blue[50], accentColor: Colors.black),
      home: GraphQLProvider(
        client: _client,
        child: HistoryListScreen(),
      ),
    );
  }
}
