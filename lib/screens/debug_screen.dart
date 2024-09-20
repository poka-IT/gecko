import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: scaleSize(57), title: const Text('Debug screen')),
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    'node: ${sub.getConnectedEndpoint()}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'blockN'.tr(args: [
                      sub.blocNumber.toString()
                    ]), //'bloc N°${sub.blocNumber}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    width: 210,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        elevation: 4,
                        backgroundColor: orangeC,
                      ),
                      onPressed: () async => await sub.spawnBlock(),
                      child: const Text(
                        'Spawn a bloc',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ));
  }
}
