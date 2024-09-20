import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final _homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: const GeckoAppBar('Template screen'),
        body: SafeArea(
          child: Column(children: <Widget>[
            ScaledSizedBox(height: 20),
            const Text('data'),
            ScaledSizedBox(height: 20),
          ]),
        ));
  }
}
