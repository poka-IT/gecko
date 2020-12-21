import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:flutter_html_view';
import 'home.dart';

void main() {
  runApp(Gecko());
}

class Gecko extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ğecko',
      theme: ThemeData(primaryColor: Colors.white, accentColor: Colors.black),
      home: HistoryListScreen(),
    );
  }
}
