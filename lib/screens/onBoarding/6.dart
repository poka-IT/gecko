// ignore_for_file: file_names
// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/7.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:provider/provider.dart';

class OnboardingStepSix extends StatelessWidget {
  OnboardingStepSix(
      {Key? key, required this.skipIntro, required this.generatedMnemonic})
      : super(key: key);

  final bool skipIntro;
  String? generatedMnemonic;
  TextEditingController wordController = TextEditingController();
  final TextEditingController _mnemonicController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: true);

    CommonElements common = CommonElements();
    _mnemonicController.text = generatedMnemonic!;

    return WillPopScope(
      onWillPop: () {
        generateWalletProvider.isAskedWordValid = false;
        generateWalletProvider.askedWordColor = Colors.black;
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
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
        body: SafeArea(
          child: Stack(children: [
            Align(
              alignment: Alignment.topCenter,
              child: Column(children: [
                SizedBox(height: isTall ? 40 : 20),
                common.buildProgressBar(5),
                SizedBox(height: isTall ? 40 : 20),
                common.buildText(
                    "didYouNoteMnemonicToBeSureTypeWord".tr(args: [
                      (generateWalletProvider.nbrWord + 1).toString()
                    ]),
                    20,
                    true),
                SizedBox(height: isTall ? 70 : 20),
                Text('${generateWalletProvider.nbrWord + 1}',
                    key: keyAskedWord,
                    style: TextStyle(
                        fontSize: isTall ? 17 : 15,
                        color: orangeC,
                        fontWeight: FontWeight.w400)),
                const SizedBox(height: 10),
                Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: Colors.grey[600]!,
                          width: 3,
                        )),
                    width: 430,
                    child: TextFormField(
                        key: keyInputWord,
                        autofocus: true,
                        enabled: !generateWalletProvider.isAskedWordValid,
                        controller: wordController,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          generateWalletProvider.checkAskedWord(
                              value, _mnemonicController.text);
                        },
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelStyle: TextStyle(
                              fontSize: 22.0,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500),
                          labelText: generateWalletProvider.isAskedWordValid
                              ? "itsTheGoodWord".tr()
                              : "${generateWalletProvider.nbrWordAlpha} ${"nthMnemonicWord".tr()}",
                          fillColor: const Color(0xffeeeedd),
                          filled: true,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: TextStyle(
                            fontSize: 40.0,
                            color: generateWalletProvider.askedWordColor,
                            fontWeight: FontWeight.w500))),
                Visibility(
                  visible: generateWalletProvider.isAskedWordValid,
                  child: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: nextButton(
                          context,
                          'continue'.tr(),
                          skipIntro
                              ? const OnboardingStepNine()
                              : const OnboardingStepSeven(),
                          false),
                    ),
                  ),
                ),
                // Visibility(
                //   visible: !_generateWalletProvider.isAskedWordValid,
                //   child: const Expanded(
                //     child: Align(
                //       alignment: Alignment.bottomCenter,
                //       child: Text(''),
                //     ),
                //   ),
                // ),
                SizedBox(height: 35 * ratio),
              ]),
            ),
            CommonElements().offlineInfo(context),
          ]),
        ),
      ),
    );
  }
}

Widget sentanceArray(BuildContext context) {
  GenerateWalletsProvider generateWalletProvider =
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
          future: generateWalletProvider.generateWordList(context),
          builder: (BuildContext context, AsyncSnapshot<List> data) {
            if (!data.hasData) {
              return const Text('');
            } else {
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
        style: const TextStyle(fontSize: 15, color: Color(0xff6b6b52)),
      ),
      Text(
        dataWord.split(':')[1],
        key: keyMnemonicWord(dataWord.split(':')[0]),
        style: const TextStyle(fontSize: 20, color: Colors.black),
      ),
    ]),
  );
}

Widget nextButton(BuildContext context, String text, nextScreen, bool isFast) {
  GenerateWalletsProvider generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context, listen: false);

  generateWalletProvider.isAskedWordValid = false;
  generateWalletProvider.askedWordColor = Colors.black;

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
        Navigator.push(
            context, FaderTransition(page: nextScreen, isFast: isFast));
      },
      child: Text(
        text,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
