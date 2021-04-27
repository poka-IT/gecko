import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/onBoarding/8.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepNine extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 6;

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
              textKey: Key('step7'),
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
                          onPressed: () {
                            _generateWalletProvider.reloadBuild();
                          },
                          child: Text("Choisir une autre phrase",
                              style: TextStyle(fontSize: 20))),
                    ))),
            SizedBox(height: 25),
            SizedBox(
              width: 400,
              height: 62,
              child: ElevatedButton(
                  key: Key('goStep8'),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: Color(0xffD28928),
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
                                  _generateWalletProvider.generatedMnemonic,
                              generatedWallet:
                                  _generateWalletProvider.actualWallet),
                          isFast: true),
                    );
                  },
                  child: Text("J'ai noté ma phrase",
                      style: TextStyle(fontSize: 20))),
            ),
            SizedBox(height: 80),
          ]),
        ));
  }
}

Widget sentanceArray(BuildContext context) {
  GenerateWalletsProvider _generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context);

  return FutureBuilder(
      future: _generateWalletProvider.generateWordList(),
      initialData: [
        '1:...',
        '2:...',
        '3:...',
        '4:...',
        '5:...',
        '6:...',
        '7:...',
        '8:...',
        '9:...',
        '10:...',
        '11:...',
        '12:...',
      ],
      builder: (context, formatedArray) {
        // print(formatedArray.data);
        return Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.all(
                      const Radius.circular(10),
                    )),
                // color: Colors.grey[300],
                padding: EdgeInsets.all(20),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(children: <Widget>[
                        arrayCell(formatedArray.data[0]),
                        arrayCell(formatedArray.data[1]),
                        arrayCell(formatedArray.data[2]),
                        arrayCell(formatedArray.data[3]),
                      ]),
                      SizedBox(height: 15),
                      Row(children: <Widget>[
                        arrayCell(formatedArray.data[4]),
                        arrayCell(formatedArray.data[5]),
                        arrayCell(formatedArray.data[6]),
                        arrayCell(formatedArray.data[7]),
                      ]),
                      SizedBox(height: 15),
                      Row(children: <Widget>[
                        arrayCell(formatedArray.data[8]),
                        arrayCell(formatedArray.data[9]),
                        arrayCell(formatedArray.data[10]),
                        arrayCell(formatedArray.data[11]),
                      ]),
                    ])));
      });
}

Widget arrayCell(dataWord) {
  return Container(
      width: 102,
      child: Column(children: <Widget>[
        Text(dataWord.split(':')[0], style: TextStyle(fontSize: 14)),
        SizedBox(height: 2),
        Text(dataWord.split(':')[1],
            key: Key('word${dataWord.split(':')[0]}'),
            style: TextStyle(fontSize: 19, color: Colors.black)),
      ]));
}

// ignore: must_be_immutable
class PrintWallet extends StatelessWidget {
  PrintWallet(this.sentence);

  final String sentence;

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Imprimer ce trousseau')),
        body: PdfPreview(
          build: (format) => _generateWalletProvider.printWallet(sentence),
        ),
      ),
    );
  }
}
