// ignore_for_file: file_names

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/6.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

AsyncSnapshot<List>? mnemoList;

class OnboardingStepFive extends StatelessWidget {
  const OnboardingStepFive({Key? key, this.skipIntro = false})
      : super(key: key);
  final bool skipIntro;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);

    CommonElements common = CommonElements();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        title: const SizedBox(
          height: 22,
          child: Text(
            'Votre phrase de restauration',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(children: [
          SizedBox(height: isTall ? 40 : 20),
          common.buildProgressBar(4),
          SizedBox(height: isTall ? 40 : 20),
          common.buildText(
            <TextSpan>[
              const TextSpan(
                  text:
                      'Gecko a généré votre phrase de restauration ! Tâchez de la garder bien secrète, car elle permet à quiconque la connaît d’accéder à tous vos portefeuilles.'),
            ],
          ),
          SizedBox(height: 35 * ratio),
          sentanceArray(context),
          SizedBox(height: 17 * ratio),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return PrintWallet(_generateWalletProvider.generatedMnemonic);
                }),
              );
            },
            child: Image.asset(
              'assets/printer.png',
              height: 42 * ratio,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 380 * ratio,
                height: 60 * ratio,
                child: ElevatedButton(
                    key: const Key('generateMnemonic'),
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      primary: const Color(0xffFFD58D),
                      onPrimary: Colors.black, // foreground
                    ),
                    onPressed: () {
                      _generateWalletProvider.reloadBuild();
                      // setState(() {});
                    },
                    child: Text("Choisir une autre phrase",
                        style: TextStyle(
                            fontSize: 22 * ratio,
                            fontWeight: FontWeight.w600))),
              ),
            ),
          ),
          SizedBox(height: 22 * ratio),
          nextButton(context, "J'ai noté ma phrase", false, skipIntro),
          SizedBox(height: 35 * ratio),
        ]),
      ),
    );
  }
}

Widget sentanceArray(BuildContext context) {
  GenerateWalletsProvider _generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: const Color(0xffeeeedd),
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          )),
      padding: const EdgeInsets.all(20),
      child: FutureBuilder(
          future: _generateWalletProvider.generateWordList(context),
          builder: (BuildContext context, AsyncSnapshot<List> _data) {
            if (!_data.hasData) {
              return const Text('');
            } else {
              mnemoList = _data;
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(children: <Widget>[
                      arrayCell(_data.data![0]),
                      arrayCell(_data.data![1]),
                      arrayCell(_data.data![2]),
                      arrayCell(_data.data![3]),
                    ]),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      arrayCell(_data.data![4]),
                      arrayCell(_data.data![5]),
                      arrayCell(_data.data![6]),
                      arrayCell(_data.data![7]),
                    ]),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      arrayCell(_data.data![8]),
                      arrayCell(_data.data![9]),
                      arrayCell(_data.data![10]),
                      arrayCell(_data.data![11]),
                    ]),
                  ]);
            }
          }),
    ),
  );
}

Widget arrayCell(dataWord) {
  return SizedBox(
    width: 100,
    child: Column(children: <Widget>[
      Text(
        dataWord.split(':')[0],
        style: TextStyle(fontSize: 13 * ratio, color: const Color(0xff6b6b52)),
      ),
      Text(
        dataWord.split(':')[1],
        key: Key('word${dataWord.split(':')[0]}'),
        style: TextStyle(fontSize: 17 * ratio, color: Colors.black),
      ),
    ]),
  );
}

// ignore: must_be_immutable
class PrintWallet extends StatelessWidget {
  const PrintWallet(this.sentence, {Key? key}) : super(key: key);

  final String? sentence;

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              }),
          backgroundColor: yellowC,
          foregroundColor: Colors.black,
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text(
              'Imprimer ma phrase de restauration',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        body: PdfPreview(
          canDebug: false,
          canChangeOrientation: false,
          build: (format) => _generateWalletProvider.printWallet(mnemoList),
        ),
      ),
    );
  }
}

Widget nextButton(
    BuildContext context, String text, bool isFast, bool skipIntro) {
  GenerateWalletsProvider _generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context, listen: false);
  MyWalletsProvider _myWalletProvider =
      Provider.of<MyWalletsProvider>(context, listen: false);
  return SizedBox(
    width: 380 * ratio,
    height: 60 * ratio,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        primary: orangeC, // background
        onPrimary: Colors.white, // foreground
      ),
      onPressed: () {
        _generateWalletProvider.nbrWord =
            _generateWalletProvider.getRandomInt();
        _generateWalletProvider.nbrWordAlpha = _generateWalletProvider
            .intToString(_generateWalletProvider.nbrWord + 1);
        _myWalletProvider.mnemonic = _generateWalletProvider.generatedMnemonic!;

        Navigator.push(
          context,
          FaderTransition(
              page: OnboardingStepSix(
                  generatedMnemonic: _generateWalletProvider.generatedMnemonic,
                  skipIntro: skipIntro),
              isFast: true),
        );
      },
      child: Text(
        text,
        style: TextStyle(fontSize: 22 * ratio, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
