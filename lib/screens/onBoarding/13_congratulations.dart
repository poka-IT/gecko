import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/myWallets/walletsHome.dart';

// ignore: must_be_immutable
class OnboardingStepFiveteen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 12;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar(context, 'Ma phrase de restauration', progress),
            common.bubbleSpeak(
              "Top !\n\nVotre trousseau de clef et votre portefeuille ont été créés avec un immense succès.\n\nFélicitations !",
            ),
            SizedBox(height: isTall ? 20 : 10),
            Image.asset(
              'assets/onBoarding/gecko-clin.gif',
              height: isTall ? 400 : 300,
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: Color(0xffD28928),
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName('/'),
                            );
                            Navigator.push(
                              context,
                              SmoothTransition(page: WalletsHome()),
                            );
                          },
                          child: Text("Accéder à mes portefeuilles",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 80),
          ]),
        ));
  }
}
