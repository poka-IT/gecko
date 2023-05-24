import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final _homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Template screen'),
            )),
        body: const SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 20),
            Text('data'),
            SizedBox(height: 20),
          ]),
        ));
  }
}
