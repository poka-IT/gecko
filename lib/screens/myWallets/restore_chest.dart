// ignore_for_file: use_build_context_synchronously

import 'package:bubble/bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/onBoarding/7.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

class RestoreChest extends StatelessWidget {
  const RestoreChest({Key? key, this.skipIntro = false}) : super(key: key);
  final bool skipIntro;

  @override
  Widget build(BuildContext context) {
    final genW = Provider.of<GenerateWalletsProvider>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    if (genW.isSentenceComplete(context)) {
      genW.generatedMnemonic =
          '${genW.cellController0.text} ${genW.cellController1.text} ${genW.cellController2.text} ${genW.cellController3.text} ${genW.cellController4.text} ${genW.cellController5.text} ${genW.cellController6.text} ${genW.cellController7.text} ${genW.cellController8.text} ${genW.cellController9.text} ${genW.cellController10.text} ${genW.cellController11.text}';
    }

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        genW.resetImportView();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: GeckoAppBar('restoreAChest'.tr()),
        body: SafeArea(
          child: Stack(children: [
            Column(children: <Widget>[
              ScaledSizedBox(height: isTall ? 20 : 3),
              bubbleSpeak('toRestoreEnterMnemonic'.tr()),
              ScaledSizedBox(height: isTall ? 20 : 5),
              Column(children: <Widget>[
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      arrayCell(context, genW.cellController0),
                      arrayCell(context, genW.cellController1),
                      arrayCell(context, genW.cellController2),
                      arrayCell(context, genW.cellController3),
                    ]),
                ScaledSizedBox(height: isTall ? 10 : 3),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      arrayCell(context, genW.cellController4),
                      arrayCell(context, genW.cellController5),
                      arrayCell(context, genW.cellController6),
                      arrayCell(context, genW.cellController7),
                    ]),
                ScaledSizedBox(height: isTall ? 10 : 3),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      arrayCell(context, genW.cellController8),
                      arrayCell(context, genW.cellController9),
                      arrayCell(context, genW.cellController10),
                      arrayCell(context, genW.cellController11),
                    ]),
              ]),
              // const Spacer(),
              if (genW.isSentenceComplete(context))
                Expanded(
                    child: Align(
                  alignment: Alignment.center,
                  child: ScaledSizedBox(
                    width: 340,
                    height: 55,
                    child: ElevatedButton(
                      key: keyGoNext,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        elevation: 4,
                        backgroundColor: orangeC,
                      ),
                      onPressed: () async {
                        if (await sub
                            .isMnemonicValid(genW.generatedMnemonic!)) {
                          genW.resetImportView();
                          await Navigator.push(
                            context,
                            FaderTransition(
                                page: skipIntro
                                    ? const OnboardingStepNine(
                                        scanDerivation: true)
                                    : const OnboardingStepSeven(
                                        scanDerivation: true),
                                isFast: true),
                          );
                        } else {
                          await badMnemonicPopup(context);
                        }
                      },
                      child: Text(
                        'restoreThisChest'.tr(),
                        style: scaledTextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  // SizedBox(height: isTall ? 80 : 80),
                ))
              else
                Column(children: [
                  ScaledSizedBox(height: 20),
                  ScaledSizedBox(
                    width: 210,
                    height: 55,
                    child: ElevatedButton(
                        key: keyPastMnemonic,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          elevation: 4,
                          backgroundColor: yellowC,
                        ),
                        onPressed: () {
                          genW.pasteMnemonic(context);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Icon(
                              Icons.content_paste_go,
                              size: scaleSize(28),
                            ),
                            Text(
                              'pasteFromClipboard'.tr(),
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w400),
                            ),
                          ],
                        )),
                  )
                ])
            ]),
            const OfflineInfo(),
          ]),
        ),
      ),
    );
  }

  Widget bubbleSpeak(String text) {
    return Bubble(
      margin: const BubbleEdges.symmetric(horizontal: 20),
      padding: BubbleEdges.all(scaleSize(15)),
      borderWidth: 1,
      borderColor: Colors.black,
      radius: Radius.zero,
      color: Colors.white,
      child: Text(
        text,
        key: keyBubbleSpeak,
        textAlign: TextAlign.justify,
        style: scaledTextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget arrayCell(BuildContext context, final cellCtl) {
    final generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);

    return Container(
      width: scaleSize(87),
      height: scaleSize(37),
      // ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      // child: RawKeyboardListener(
      //   focusNode: FocusNode(), // or FocusNode()
      //   onKey: (event) {
      //     if (event.logicalKey == LogicalKeyboardKey.space) {
      //       FocusScope.of(context).nextFocus();
      //     }
      //   },

      child: TextField(
        autofocus: true,
        controller: cellCtl,
        textInputAction: TextInputAction.next,
        onChanged: (v) {
          if (v.contains(' ')) {
            cellCtl.text = cellCtl.text.replaceAll(' ', '');
            FocusScope.of(context).nextFocus();
          }
          bool isValid = generateWalletProvider.isBipWord(v);
          if (isValid) cellCtl.text = cellCtl.text.toLowerCase();
          if (isValid && generateWalletProvider.cellController11.text.isEmpty) {
            FocusScope.of(context).nextFocus();
          }
        },
        textAlign: TextAlign.center,
        style: scaledTextStyle(fontSize: 16),
      ),
    );
  }

  Future<bool?> badMnemonicPopup(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Phrase incorrecte'),
          content: const Text(
              'Votre phrase de restauration semble incorrecte, les mots ne sont pas dans le bon ordre.\nVeuillez la corriger.'),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
