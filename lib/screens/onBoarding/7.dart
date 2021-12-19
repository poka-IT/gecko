// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generate_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/8.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepNine extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 6;

  OnboardingStepNine({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    CommonElements common = CommonElements();

    // _generateWalletProvider.generateMnemonic();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            common.onboardingProgressBar(
                context, 'Ma phrase de restauration', progress),
            common.bubbleSpeak(
              "C'est le moment de noter votre phrase !",
              textKey: const Key('step7'),
              long: 60,
            ),
            SizedBox(height: isTall ? 100 : 70),
            sentanceArray(context),
            SizedBox(height: isTall ? 20 : 15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return PrintWallet(
                        _generateWalletProvider.generatedMnemonic);
                  }),
                );
              },
              child: Image.asset(
                'assets/printer.png',
                height: 35,
              ),
            ),
            Expanded(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 400,
                      height: 62,
                      child: ElevatedButton(
                          key: const Key('generateMnemonic'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: const Color(0xffFFD58D),
                            onPrimary: Colors.black, // foreground
                          ),
                          onPressed: () {
                            _generateWalletProvider.reloadBuild();
                          },
                          child: const Text("Choisir une autre phrase",
                              style: TextStyle(fontSize: 20))),
                    ))),
            const SizedBox(height: 25),
            SizedBox(
              width: 400,
              height: 62,
              child: ElevatedButton(
                  key: const Key('goStep8'),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: orangeC,
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () {
                    _generateWalletProvider.nbrWord =
                        _generateWalletProvider.getRandomInt();
                    _generateWalletProvider.nbrWordAlpha =
                        _generateWalletProvider
                            .intToString(_generateWalletProvider.nbrWord + 1);

                    Navigator.push(
                      context,
                      FaderTransition(
                          page: OnboardingStepTen(
                              generatedMnemonic:
                                  _generateWalletProvider.generatedMnemonic),
                          isFast: true),
                    );
                  },
                  child: const Text("J'ai noté ma phrase",
                      style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(height: 80),
          ]),
        ));
  }
}

Widget sentanceArray(BuildContext context) {
  GenerateWalletsProvider _generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context);

  List formatedArray = _generateWalletProvider.generateWordList();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: Colors.grey[300],
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          )),
      // color: Colors.grey[300],
      padding: const EdgeInsets.all(20),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(children: <Widget>[
              arrayCell(formatedArray[0]),
              arrayCell(formatedArray[1]),
              arrayCell(formatedArray[2]),
              arrayCell(formatedArray[3]),
            ]),
            const SizedBox(height: 15),
            Row(children: <Widget>[
              arrayCell(formatedArray[4]),
              arrayCell(formatedArray[5]),
              arrayCell(formatedArray[6]),
              arrayCell(formatedArray[7]),
            ]),
            const SizedBox(height: 15),
            Row(children: <Widget>[
              arrayCell(formatedArray[8]),
              arrayCell(formatedArray[9]),
              arrayCell(formatedArray[10]),
              arrayCell(formatedArray[11]),
            ]),
          ]),
    ),
  );
}

Widget arrayCell(dataWord) {
  return SizedBox(
    width: 102,
    child: Column(children: <Widget>[
      Text(
        dataWord.split(':')[0],
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 2),
      Text(
        dataWord.split(':')[1],
        key: Key('word${dataWord.split(':')[0]}'),
        style: const TextStyle(fontSize: 19, color: Colors.black),
      ),
    ]),
  );
}

// ignore: must_be_immutable
class PrintWallet extends StatelessWidget {
  const PrintWallet(this.sentence, {Key key}) : super(key: key);

  final String sentence;

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const Text('Imprimer ce trousseau')),
        body: PdfPreview(
          build: (format) => _generateWalletProvider.printWallet(sentence),
        ),
      ),
    );
  }
}
