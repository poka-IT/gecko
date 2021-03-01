import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/myWallets/importWallet.dart';
import 'package:gecko/screens/onBoarding/2_stepOne.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class NoKeyChainScreen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

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
            common.onboardingProgressBar('Mes portefeuilles', 0),
            common.bubbleSpeak(
              "Je ne connais pour l’instant aucun de vos portefeuilles.\n\nVous pouvez en créer un nouveau, ou bien importer un portefeuille Cesium existant.",
            ),
            SizedBox(height: 90),
            Container(
              child: ClipOval(
                child: Material(
                  color: Color(0xffFFD58D), // button color
                  child: InkWell(
                      splashColor: Color(0xffD28928), // inkwell color
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Image(
                              image: AssetImage('assets/onBoarding/wallet.png'),
                              height: 90)),
                      onTap: () {
                        Navigator.push(
                            context, SlideLeftRoute(page: OnboardingStepOne()));
                      }),
                ),
              ),
              decoration: BoxDecoration(
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
            SizedBox(height: 15),
            Text(
              "Créer un nouveau\nportefeuille",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 70),
            Container(
              child: ClipOval(
                child: Material(
                  color: Color(0xffFFD58D), // button color
                  child: InkWell(
                      splashColor: Color(0xffD28928), // inkwell color
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child:
                            // Image(
                            // image: AssetImage('assets/cesium_bw3.png'),
                            // height: 60),
                            SvgPicture.asset('assets/cesium_small.svg',
                                semanticsLabel: 'Cesium Logo', height: 48),
                      ),
                      onTap: () {
                        Navigator.push(context,
                            SlideLeftRoute(page: ImportWalletScreen()));
                      }),
                ),
              ),
              decoration: BoxDecoration(
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
            SizedBox(height: 10),
            Text(
              "Importer un\nportefeuille Cesium",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 13),
            )
          ]),
        ));
  }
}
