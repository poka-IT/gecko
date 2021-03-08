import 'dart:ui';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepTen extends StatelessWidget {
  OnboardingStepTen({
    Key validationKey,
    @required this.generatedMnemonic,
    @required this.generatedWallet,
  }) : super(key: validationKey);

  String generatedMnemonic;
  NewWallet generatedWallet;

  TextEditingController tplController = TextEditingController();
  TextEditingController wordController = TextEditingController();
  TextEditingController _mnemonicController = TextEditingController();

  final int progress = 7;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    CommonElements common = CommonElements();
    this._mnemonicController.text = generatedMnemonic;

    return WillPopScope(
        onWillPop: () {
          _generateWalletProvider.isAskedWordValid = false;
          _generateWalletProvider.askedWordColor = Colors.black;
          return Future<bool>.value(true);
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            extendBodyBehindAppBar: true,
            body: SafeArea(
              child: Column(children: <Widget>[
                common.onboardingProgressBar(context, 
                    'Valider ma phrase de restauration', progress),
                common.bubbleSpeakRich(<TextSpan>[
                  TextSpan(
                      text:
                          "Avez-vous bien noté votre phrase de restauration ?\n\nPour en être sûr, veuillez taper dans le champ ci-dessous le ",
                      style: TextStyle(fontSize: 16 * ratio)),
                  TextSpan(
                      text: '${_generateWalletProvider.nbrWord + 1}ème mot',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * ratio)),
                  TextSpan(
                      text: " de votre phrase de restauration :",
                      style: TextStyle(fontSize: 16 * ratio)),
                ]),

                // LayoutBuilder(builder: (builder, constraints) {
                //   // 2
                //   var hasDetailPage = constraints.maxWidth > 480;

                //   if (hasDetailPage) {
                //     // 3
                //     return Row(
                //       children: [
                //         // 4
                //         SizedBox(
                //           width: 250,
                //           height: 500,
                //           child: Text('GRAND'),
                //         ),
                //         // 5
                //         Expanded(
                //           child: Text('GRAND 2'),
                //         ),
                //       ],
                //     );
                //   } else {
                //     // 6
                //     return Text('PETIT');
                //   }
                // }),

                // Expanded(
                //   child:
                //       //ScreenTypeLayout with custom breakpoints supplied
                //       ScreenTypeLayout(
                //     breakpoints: ScreenBreakpoints(
                //       tablet: 600,
                //       desktop: 950,
                //       watch: 480,
                //     ),
                //     mobile: Container(color: Colors.blue),
                //     tablet: Container(color: Colors.yellow),
                //     desktop: Container(color: Colors.red),
                //     watch: Container(color: Colors.purple),
                //   ),
                // ),

                SizedBox(height: isTall ? 70 : 10),
                if (isTall)
                  Text('${_generateWalletProvider.nbrWord + 1}',
                      style: TextStyle(
                          fontSize: 17,
                          color: Color(0xffD28928),
                          fontWeight: FontWeight.w400)),
                SizedBox(height: isTall ? 10 : 0),
                Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: Colors.grey[600],
                          width: 3,
                        )),
                    width: 430,
                    child: TextFormField(
                        autofocus: true,
                        enabled: !_generateWalletProvider.isAskedWordValid,
                        controller: this.wordController,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          _generateWalletProvider.checkAskedWord(
                              value, _mnemonicController.text);
                        },
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelStyle: TextStyle(
                              fontSize: 22.0,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500),
                          labelText: _generateWalletProvider.isAskedWordValid
                              ? "C'est le bon mot !"
                              : "${_generateWalletProvider.nbrWordAlpha} mot de votre phrase de restauration",
                          fillColor: Colors.grey[300],
                          filled: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: TextStyle(
                            fontSize: 40.0,
                            color: _generateWalletProvider.askedWordColor,
                            fontWeight: FontWeight.w500))),
                Visibility(
                    visible: _generateWalletProvider.isAskedWordValid,
                    child: Expanded(
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
                                    Navigator.push(
                                      context,
                                      FaderTransition(
                                          page: OnboardingStepEleven(), isFast: true),
                                    );
                                  },
                                  child: Text("Continuer",
                                      style: TextStyle(fontSize: 20))),
                            )))),
                SizedBox(height: 80),
              ]),
            )));
  }
}
