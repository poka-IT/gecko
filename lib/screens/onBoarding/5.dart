// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/show_seed.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/screens/onBoarding/6.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('yourMnemonic'.tr()),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            ScaledSizedBox(height: isTall ? 25 : 5),
            const BuildProgressBar(pagePosition: 4),
            ScaledSizedBox(height: isTall ? 25 : 5),
            BuildText(text: 'geckoGeneratedYourMnemonicKeepItSecret'.tr()),
            ScaledSizedBox(height: isTall ? 15 : 5),
            sentanceArray(context),
            ScaledSizedBox(height: isTall ? 17 : 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaledSizedBox(
                  height: 40,
                  width: 132,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: orangeC,
                      elevation: 1,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: generateWalletProvider.generatedMnemonic!));
                      snackCopySeed(context);
                    },
                    child: Row(children: <Widget>[
                      Image.asset(
                        'assets/walletOptions/copy-white.png',
                        height: scaleSize(23),
                      ),
                      const Spacer(),
                      Text(
                        'copy'.tr(),
                        style: scaledTextStyle(
                            fontSize: 14, color: Colors.grey[50]),
                      ),
                      const Spacer(),
                    ]),
                  ),
                ),
                ScaledSizedBox(width: 70),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return PrintWallet(
                            generateWalletProvider.generatedMnemonic!);
                      }),
                    );
                  },
                  child: Image.asset(
                    'assets/printer.png',
                    height: scaleSize(42),
                  ),
                ),
              ],
            ),
            ScaledSizedBox(height: isTall ? 17 : 5),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ScaledSizedBox(
                  width: 350,
                  height: 55,
                  child: ElevatedButton(
                      key: keyGenerateMnemonic,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        elevation: 4,
                        backgroundColor: const Color(0xffFFD58D),
                      ),
                      onPressed: () {
                        setState(() {});
                      },
                      child: Text("chooseAnotherMnemonic".tr(),
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(
                              fontSize: 21, fontWeight: FontWeight.w600))),
                ),
              ),
            ),
            ScaledSizedBox(height: isTall ? 20 : 10),
            nextButton(
                context, "iNotedMyMnemonic".tr(), false, widget.skipIntro),
            isTall ? const Spacer() : const SizedBox(height: 5),
          ]),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}

Widget sentanceArray(BuildContext context) {
  final generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context, listen: false);

  return Container(
    constraints: BoxConstraints(maxWidth: scaleSize(isTall ? 355 : 340)),
    decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: const Color(0xffeeeedd),
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        )),
    padding: EdgeInsets.all(scaleSize(11)),
    child: FutureBuilder(
        future: generateWalletProvider.generateWordList(context),
        builder: (BuildContext context, AsyncSnapshot<List> mnemoListData) {
          if (!mnemoListData.hasData) {
            return const Text('');
          } else {
            final mnemoList = mnemoListData.data!;
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(children: <Widget>[
                    arrayCell(mnemoList[0]),
                    arrayCell(mnemoList[1]),
                    arrayCell(mnemoList[2]),
                    arrayCell(mnemoList[3]),
                  ]),
                  ScaledSizedBox(height: 12),
                  Row(children: <Widget>[
                    arrayCell(mnemoList[4]),
                    arrayCell(mnemoList[5]),
                    arrayCell(mnemoList[6]),
                    arrayCell(mnemoList[7]),
                  ]),
                  ScaledSizedBox(height: 12),
                  Row(children: <Widget>[
                    arrayCell(mnemoList[8]),
                    arrayCell(mnemoList[9]),
                    arrayCell(mnemoList[10]),
                    arrayCell(mnemoList[11]),
                  ]),
                ]);
          }
        }),
  );
}

Widget arrayCell(dataWord) {
  return ScaledSizedBox(
    width: scaleSize(isTall ? 78 : 91),
    child: Column(children: <Widget>[
      Text(
        dataWord.split(':')[0],
        style: scaledTextStyle(fontSize: 11, color: const Color(0xff6b6b52)),
      ),
      Text(
        dataWord.split(':')[1],
        key: keyMnemonicWord(dataWord.split(':')[0]),
        style: scaledTextStyle(fontSize: 15, color: Colors.black),
      ),
    ]),
  );
}

Widget nextButton(
    BuildContext context, String text, bool isFast, bool skipIntro) {
  final generateWalletProvider =
      Provider.of<GenerateWalletsProvider>(context, listen: false);
  final myWalletProvider =
      Provider.of<MyWalletsProvider>(context, listen: false);
  return ScaledSizedBox(
    width: 350,
    height: 55,
    child: ElevatedButton(
      key: keyGoNext,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        elevation: 4,
        backgroundColor: orangeC,
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
        style: scaledTextStyle(
            fontSize: 21, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}
