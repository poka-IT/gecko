import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepFourteen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 92;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    CommonElements common = CommonElements();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar('Ma phrase de restauration', progress),
            common.bubbleSpeak(
                "Avez-vous bien mémorisé votre code secret ?\n\nVérifions ça ensemble !\n\nTapez votre code secret dans le champ ci-dessous (après c’est fini, promis-juré-gecko)."),
            SizedBox(height: 80),
            common.pinForm(context, 5, 1, 3)
          ]),
        ));
  }
}
