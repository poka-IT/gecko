// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/6.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

AsyncSnapshot<List>? mnemoList;

class OnboardingStepFive extends StatefulWidget {
  const OnboardingStepFive({Key? key, this.skipIntro = false})
      : super(key: key);
  final bool skipIntro;

  @override
  State<StatefulWidget> createState() {
    return _ChooseChestState();
  }
}

// ignore: unused_element
class _ChooseChestState extends State<OnboardingStepFive> {
  @override
  Widget build(BuildContext context) {
    final generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);

    final CommonElements common = CommonElements();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        title: SizedBox(
          height: 22,
          child: Text(
            'yourMnemonic'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            SizedBox(height: isTall ? 40 : 20),
            common.buildProgressBar(4),
            SizedBox(height: isTall ? 40 : 20),
            common.buildText('geckoGeneratedYourMnemonicKeepItSecret'.tr()),
            SizedBox(height: 35 * ratio),
            sentanceArray(context),
            SizedBox(height: 17 * ratio),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return PrintWallet(
                        generateWalletProvider.generatedMnemonic);
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
                      key: keyGenerateMnemonic,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, elevation: 4,
                        backgroundColor: const Color(0xffFFD58D), // foreground
                      ),
                      onPressed: () {
                        // _generateWalletProvider.reloadBuild();
                        setState(() {});
                      },
                      child: Text("chooseAnotherMnemonic".tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22 * ratio,
                              fontWeight: FontWeight.w600))),
                ),
              ),
            ),
            SizedBox(height: 22 * ratio),
            nextButton(
                context, "iNotedMyMnemonic".tr(), false, widget.skipIntro),
            const Spacer(),
            // SizedBox(height: 35 * ratio),
          ]),
          CommonElements().offlineInfo(context),
        ]),
      ),
    );
  }
}

Widget sentanceArray(BuildContext context) {
  final generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context, listen: false);

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
          future: generateWalletProvider.generateWordList(context),
          builder: (BuildContext context, AsyncSnapshot<List> data) {
            if (!data.hasData) {
              return const Text('');
            } else {
              mnemoList = data;
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(children: <Widget>[
                      arrayCell(data.data![0]),
                      arrayCell(data.data![1]),
                      arrayCell(data.data![2]),
                      arrayCell(data.data![3]),
                    ]),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      arrayCell(data.data![4]),
                      arrayCell(data.data![5]),
                      arrayCell(data.data![6]),
                      arrayCell(data.data![7]),
                    ]),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      arrayCell(data.data![8]),
                      arrayCell(data.data![9]),
                      arrayCell(data.data![10]),
                      arrayCell(data.data![11]),
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
        key: keyMnemonicWord(dataWord.split(':')[0]),
        style: TextStyle(fontSize: 17 * ratio, color: Colors.black),
      ),
    ]),
  );
}

class PrintWallet extends StatelessWidget {
  const PrintWallet(this.sentence, {Key? key}) : super(key: key);

  final String? sentence;

  @override
  Widget build(BuildContext context) {
    final generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);
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
              'printMyMnemonic',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        body: PdfPreview(
          canDebug: false,
          canChangeOrientation: false,
          build: (format) => generateWalletProvider.printWallet(mnemoList),
        ),
      ),
    );
  }
}

Widget nextButton(
    BuildContext context, String text, bool isFast, bool skipIntro) {
  final generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context, listen: false);
  final myWalletProvider =
      Provider.of<MyWalletsProvider>(context, listen: false);
  return SizedBox(
    width: 380 * ratio,
    height: 60 * ratio,
    child: ElevatedButton(
      key: keyGoNext,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, elevation: 4,
        backgroundColor: orangeC, // foreground
      ),
      onPressed: () {
        generateWalletProvider.nbrWord = generateWalletProvider.getRandomInt();
        generateWalletProvider.nbrWordAlpha = generateWalletProvider
            .intToString(generateWalletProvider.nbrWord + 1);
        myWalletProvider.mnemonic = generateWalletProvider.generatedMnemonic!;

        Navigator.push(
          context,
          FaderTransition(
              page: OnboardingStepSix(
                  generatedMnemonic: generateWalletProvider.generatedMnemonic,
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
