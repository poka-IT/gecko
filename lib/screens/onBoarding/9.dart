// ignore_for_file: file_names
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/10.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepNine extends StatelessWidget {
  const OnboardingStepNine({Key? key, this.scanDerivation = false})
      : super(key: key);
  final bool scanDerivation;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    // MyWalletsProvider myWalletProvider =
    //     Provider.of<MyWalletsProvider>(context);
    CommonElements common = CommonElements();

    _generateWalletProvider.pin.text = debugPin // kDebugMode &&
        ? 'AAAAA'
        : _generateWalletProvider.changePinCode(reload: false).toUpperCase();

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text(
              'Mon code secret',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: isTall ? 40 : 20),
            common.buildProgressBar(8),
            SizedBox(height: isTall ? 40 : 20),
            common.buildText(
              <TextSpan>[
                const TextSpan(
                    text:
                        "Et voilà votre code secret !\n\nMémorisez-le ou notez-le, car il vous sera demandé "),
                const TextSpan(
                    text: 'à chaque fois',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(
                    text:
                        " que vous voudrez effectuer un paiement sur cet appareil."),
              ],
            ),
            const SizedBox(height: 100),
            Stack(
              alignment: Alignment.centerRight,
              children: <Widget>[
                TextField(
                    key: const Key('generatedPin'),
                    enabled: false,
                    controller: _generateWalletProvider.pin,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(),
                    style: const TextStyle(
                        letterSpacing: 5,
                        fontSize: 35.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.replay),
                  color: orangeC,
                  onPressed: () {
                    _generateWalletProvider.changePinCode(reload: true);
                  },
                ),
              ],
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 380 * ratio,
                      height: 60 * ratio,
                      child: ElevatedButton(
                          key: const Key('changeSecretCode'),
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            primary: const Color(0xffFFD58D),
                            onPrimary: Colors.black, // foreground
                          ),
                          onPressed: () {
                            _generateWalletProvider.changePinCode(reload: true);
                          },
                          child: Text("Choisir un autre code secret",
                              style: TextStyle(
                                  fontSize: 22 * ratio,
                                  fontWeight: FontWeight.w600))),
                    ))),
            SizedBox(height: 22 * ratio),
            common.nextButton(context, "J'ai noté mon code secret",
                OnboardingStepTen(scanDerivation: scanDerivation), false),
            SizedBox(height: 35 * ratio),
          ]),
        ));
  }
}
