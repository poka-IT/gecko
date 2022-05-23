// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';

// ignore: must_be_immutable
class OnboardingStepFiveteen extends StatelessWidget {
  const OnboardingStepFiveteen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text(
              'C’est tout bon !',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 40),
            common.buildText(<TextSpan>[
              const TextSpan(
                text:
                    "Top !\n\nVotre coffre votre premier portefeuille ont été créés avec un immense succès.\n\nFélicitations !",
              )
            ]),
            SizedBox(height: isTall ? 20 : 10),
            Image.asset(
              'assets/onBoarding/gecko-clin.gif',
              height: isTall ? 400 : 300,
            ),
            Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: finishButton(context)),
            ),
            const SizedBox(height: 40),
          ]),
        ));
  }
}

Widget finishButton(BuildContext context) {
  return SizedBox(
    width: 410,
    height: 70,
    child: ElevatedButton(
        key: const Key('goWalletHome'),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          primary: orangeC,
          onPrimary: Colors.white, // foreground
        ),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) {
              return const WalletsHome();
            }),
            ModalRoute.withName('/'),
          );
        },
        child: const Text("Accéder à mon coffre",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600))),
  );
}
