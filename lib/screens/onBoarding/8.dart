// ignore_for_file: file_names
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generate_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepTen extends StatelessWidget {
  OnboardingStepTen({
    Key? validationKey,
    required this.generatedMnemonic,
  }) : super(key: validationKey);

  String? generatedMnemonic;
  TextEditingController tplController = TextEditingController();
  TextEditingController wordController = TextEditingController();
  final TextEditingController _mnemonicController = TextEditingController();

  final int progress = 7;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    CommonElements common = CommonElements();
    _mnemonicController.text = generatedMnemonic!;

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
                common.onboardingProgressBar(
                    context, 'Valider ma phrase de restauration', progress),
                common.bubbleSpeakRich(
                  <TextSpan>[
                    TextSpan(
                        text:
                            "Avez-vous bien noté votre phrase de restauration ?\n\nPour en être sûr, veuillez taper dans le champ ci-dessous le ",
                        style: TextStyle(fontSize: 16 * ratio)),
                    TextSpan(
                        text: '${_generateWalletProvider.nbrWord + 1}ème mot',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16 * ratio)),
                    TextSpan(
                        text: " de votre phrase de restauration :",
                        style: TextStyle(fontSize: 16 * ratio)),
                  ],
                  textKey: const Key('step8'),
                ),
                SizedBox(height: isTall ? 70 : 10),
                Text('${_generateWalletProvider.nbrWord + 1}',
                    key: const Key('askedWord'),
                    style: TextStyle(
                        fontSize: isTall ? 17 : 10,
                        color: orangeC,
                        fontWeight: FontWeight.w400)),
                SizedBox(height: isTall ? 10 : 0),
                Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: Colors.grey[600]!,
                          width: 3,
                        )),
                    width: 430,
                    child: TextFormField(
                        key: const Key('inputWord'),
                        autofocus: true,
                        enabled: !_generateWalletProvider.isAskedWordValid,
                        controller: wordController,
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
                          contentPadding: const EdgeInsets.all(12),
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
                                  key: const Key('goStep9'),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 5,
                                    primary: orangeC,
                                    onPrimary: Colors.white, // foreground
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      FaderTransition(
                                          page: OnboardingStepEleven(),
                                          isFast: true),
                                    );
                                  },
                                  child: const Text("Continuer",
                                      style: TextStyle(fontSize: 20))),
                            )))),
                const SizedBox(height: 80),
              ]),
            )));
  }
}
