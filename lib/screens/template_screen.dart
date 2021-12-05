import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class TemplateScreen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

  TemplateScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Template screen'),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 20),
            TextField(
                enabled: true,
                controller: tplController,
                maxLines: 1,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(15.0),
                ),
                style: const TextStyle(
                    fontSize: 22.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 20),
          ]),
        ));
  }
}
