import 'dart:ui';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/14_stepFourteen.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepThirteen extends StatelessWidget {
  NewWallet generatedWallet;
  final int progress = 10;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    // MyWalletsProvider myWalletProvider =
    //     Provider.of<MyWalletsProvider>(context);
    CommonElements common = CommonElements();
    _generateWalletProvider.pin.text = '';

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            FutureBuilder(
                future: _generateWalletProvider.changePinCode(reload: false),
                // initialData: '...',
                builder: (context, snapshot) {
                  generatedWallet = snapshot.data;
                  return Visibility(visible: false, child: Text(''));
                }),
            common.onboardingProgressBar('Ma phrase de restauration', progress),
            common.bubbleSpeakRich(<TextSpan>[
              TextSpan(
                  text:
                      "Et voilà votre code secret !\n\nMémorisez-le ou notez-le, car il vous sera demandé "),
              TextSpan(
                  text: 'à chaque fois',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text:
                      " que vous voudrez effectuer un paiement sur cet appareil."),
            ]),
            SizedBox(height: 100),
            Container(
              child: Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                      enabled: false,
                      controller: _generateWalletProvider.pin,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(),
                      style: TextStyle(
                          letterSpacing: 5,
                          fontSize: 35.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.replay),
                    color: Color(0xffD28928),
                    onPressed: () async {
                      generatedWallet = await _generateWalletProvider
                          .changePinCode(reload: false);
                    },
                  ),
                ],
              ),
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
                            primary: Color(0xffFFD58D),
                            onPrimary: Colors.black, // foreground
                          ),
                          onPressed: () async {
                            generatedWallet = await _generateWalletProvider
                                .changePinCode(reload: false);
                          },
                          child: Text("Choisir un autre code secret",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 25),
            SizedBox(
              width: 400,
              height: 62,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: Color(0xffD28928),
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () async {
                    _generateWalletProvider.isAskedWordValid = false;
                    _generateWalletProvider.askedWordColor = Colors.black;
                    Navigator.push(
                      context,
                      SmoothTransition(
                          page: OnboardingStepFourteen(
                              generatedWallet: generatedWallet)),
                    );
                  },
                  child: Text("J'ai noté mon code secret",
                      style: TextStyle(fontSize: 20))),
            ),
            SizedBox(height: 80),
          ]),
        ));
  }
}
