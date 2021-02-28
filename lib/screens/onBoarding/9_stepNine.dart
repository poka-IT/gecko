import 'package:bubble/bubble.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class OnboardingStepNine extends StatelessWidget {
  TextEditingController tplController = TextEditingController();
  final int progress = 50;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    // _generateWalletProvider.generateMnemonic();

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(children: <Widget>[
            Stack(children: [
              Container(height: 100),
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GeckoSpeechAppBar('Ma phrase de restauration')),
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  'assets/onBoarding/gecko_bar.png',
                ),
              ),
              Positioned(
                top: 70,
                left: 50,
                child: Image.asset(
                  'assets/onBoarding/progress_bar/total.png',
                ),
              ),
              Positioned(
                top: 70,
                left: 50,
                child: Image.asset(
                  'assets/onBoarding/progress_bar/$progress.png',
                ),
              ),
              Positioned(
                top: 66,
                right: 45,
                child: Text('$progress%',
                    style: TextStyle(fontSize: 12, color: Colors.black)),
              ),
            ]),
            Bubble(
              padding: BubbleEdges.fromLTRB(40, 15, 40, 15),
              elevation: 5,
              color: Colors.white,
              margin: BubbleEdges.fromLTRB(10, 0, 20, 10),
              // nip: BubbleNip.leftTop,
              child: Text(
                "C’est le moment de noter votre phrase !",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 50),
            // TextField(
            //     enabled: false,
            //     controller: _generateWalletProvider.mnemonicController,
            //     maxLines: 3,
            //     textAlign: TextAlign.center,
            //     decoration: InputDecoration(
            //       contentPadding: EdgeInsets.all(15.0),
            //     ),
            //     style: TextStyle(
            //         fontSize: 22.0,
            //         color: Colors.black,
            //         fontWeight: FontWeight.w400)),
            sentanceArray(context),
            SizedBox(height: 15),
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
                      width: 350,
                      height: 55,
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
              width: 350,
              height: 55,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: Color(0xffD28928),
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   SmoothTransition(page: OnboardingStepNince()),
                    // );
                  },
                  child: Text("J'ai noté ma phrase",
                      style: TextStyle(fontSize: 20))),
            ),
            SizedBox(height: 80),
          ]),
        ));
  }
}

class GeckoSpeechAppBar extends StatelessWidget with PreferredSizeWidget {
  @override
  final Size preferredSize;
  final String title;

  GeckoSpeechAppBar(
    this.title, {
    Key key,
  })  : preferredSize = Size.fromHeight(105.4),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        leading: IconButton(
          icon: Container(
              height: 30,
              child: Image.asset('assets/onBoarding/gecko_bar.png')),
          onPressed: () => Navigator.popUntil(
            context,
            ModalRoute.withName('/'),
          ),
        ),
        title: SizedBox(
          height: 25,
          child: Text(title),
        ));
  }
}

// _generateWalletProvider

Widget sentanceArray(BuildContext context) {
  GenerateWalletsProvider _generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context);

  return FutureBuilder(
      future: _generateWalletProvider.generateWordList(),
      initialData: '::::::::::::',
      builder: (context, formatedArray) {
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
      width: 80,
      child: Column(children: <Widget>[
        Text(dataWord.split(':')[0], style: TextStyle(fontSize: 12)),
        SizedBox(height: 2),
        Text(dataWord.split(':')[1],
            style: TextStyle(fontSize: 16, color: Colors.black)),
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
