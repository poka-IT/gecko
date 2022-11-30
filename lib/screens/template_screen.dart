import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Template screen'),
            )),
        body: SafeArea(
          child: Column(children: const <Widget>[
            SizedBox(height: 20),
            Text('data'),
            SizedBox(height: 20),
          ]),
        ));
  }
}
