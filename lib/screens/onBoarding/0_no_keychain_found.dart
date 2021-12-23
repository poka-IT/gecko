// ignore_for_file: file_names
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/import_cesium_wallet.dart';
import 'package:gecko/screens/onBoarding/1.dart';

class NoKeyChainScreen extends StatelessWidget {
  const NoKeyChainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    CommonElements common = CommonElements();
    return Scaffold(
        extendBodyBehindAppBar: true,
        // backgroundColor: Colors.white,
        // appBar: GeckoSpeechAppBar('Mes portefeuilles'),
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar(context, 'Mes portefeuilles', 0),
            common.bubbleSpeak(
                "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.",
                textKey: const Key('textOnboarding')),
            const SizedBox(height: 90),
            Container(
              child: ClipOval(
                child: Material(
                  color: const Color(0xffFFD58D), // button color
                  child: InkWell(
                      key: const Key('goStep1'),
                      splashColor: orangeC, // inkwell color
                      child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Image(
                              image: AssetImage('assets/onBoarding/wallet.png'),
                              height: 90)),
                      onTap: () {
                        Navigator.push(
                            context,
                            FaderTransition(
                                page: OnboardingStepOne(), isFast: true));
                      }),
                ),
              ),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4.0,
                      offset: Offset(2.0, 2.5),
                      spreadRadius: 0.5)
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Créer un nouveau\nportefeuille",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 70),
            Container(
              child: ClipOval(
                child: Material(
                  color: const Color(0xffFFD58D), // button color
                  child: InkWell(
                      splashColor: orangeC, // inkwell color
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child:
                            // Image(
                            // image: AssetImage('assets/cesium_bw3.png'),
                            // height: 60),
                            SvgPicture.asset('assets/cesium_small.svg',
                                semanticsLabel: 'Cesium Logo', height: 48),
                      ),
                      onTap: () {
                        Navigator.push(context,
                            SlideLeftRoute(page: const ImportWalletScreen()));
                      }),
                ),
              ),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4.0,
                      offset: Offset(2.0, 2.5),
                      spreadRadius: 0.5)
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Importer un\nportefeuille Cesium",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 13),
            )
          ]),
        ));
  }
}
