import 'package:bubble/bubble.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/generate_wallets.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/onBoarding/11.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

class RestoreChest extends StatelessWidget {
  const RestoreChest({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);

    generateWalletProvider.actualWallet = null;

    return WillPopScope(
      onWillPop: () {
        generateWalletProvider.resetImportView();
        return Future<bool>.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  generateWalletProvider.resetImportView();
                  Navigator.of(context).pop();
                }),
            title: const SizedBox(
              height: 22,
              child: Text('Restaurer un coffre'),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: isTall ? 30 : 15),
            bubbleSpeak(
                'Pour restaurer vos portefeuilles Gecko, rentrez dans les champs ci-dessous les 12 mots qui constituent votre phrase de restauration :'),
            SizedBox(height: isTall ? 30 : 15),
            Column(children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    arrayCell(context, generateWalletProvider.cellController0),
                    arrayCell(context, generateWalletProvider.cellController1),
                    arrayCell(context, generateWalletProvider.cellController2),
                    arrayCell(context, generateWalletProvider.cellController3),
                  ]),
              const SizedBox(height: 15),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    arrayCell(context, generateWalletProvider.cellController4),
                    arrayCell(context, generateWalletProvider.cellController5),
                    arrayCell(context, generateWalletProvider.cellController6),
                    arrayCell(context, generateWalletProvider.cellController7),
                  ]),
              const SizedBox(height: 15),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    arrayCell(context, generateWalletProvider.cellController8),
                    arrayCell(context, generateWalletProvider.cellController9),
                    arrayCell(context, generateWalletProvider.cellController10),
                    arrayCell(context, generateWalletProvider.cellController11),
                  ]),
            ]),
            // const Spacer(),
            if (generateWalletProvider.isSentenceComplete(context))
              Expanded(
                  child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 410,
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      primary: orangeC, // background
                      onPrimary: Colors.white, // foreground
                    ),
                    onPressed: () async {
                      if (await generateWalletProvider.isSentenceValid()) {
                        generateWalletProvider.resetImportView();
                        await Navigator.push(
                          context,
                          FaderTransition(
                              page: OnboardingStepThirteen(), isFast: true),
                        );
                      } else {
                        await badMnemonicPopup(context);
                      }
                    },
                    child: const Text(
                      'Restaurer ce coffre',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // SizedBox(height: isTall ? 80 : 80),
              ))
          ]),
        ),
      ),
    );
  }

  Widget bubbleSpeak(String text) {
    return Bubble(
      margin: const BubbleEdges.symmetric(horizontal: 20),
      padding: BubbleEdges.all(isTall ? 25 : 15),
      borderWidth: 1,
      borderColor: Colors.black,
      radius: Radius.zero,
      color: Colors.white,
      child: Text(
        text,
        key: const Key('importText'),
        textAlign: TextAlign.justify,
        style: const TextStyle(
            color: Colors.black, fontSize: 19, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget arrayCell(BuildContext context, TextEditingController cellCtl) {
    GenerateWalletsProvider generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);

    return Container(
      width: 102,
      height: 40 * ratio,
      child: TextField(
        autofocus: true,
        controller: cellCtl,
        textInputAction: TextInputAction.next,
        onChanged: (v) {
          bool isValid = generateWalletProvider.isBipWord(v);

          if (isValid && generateWalletProvider.cellController11.text.isEmpty) {
            FocusScope.of(context).nextFocus();
          }
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Future<bool> badMnemonicPopup(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Phrase incorrecte'),
          content: const Text(
              'Votre phrase de restauration semble incorrecte, veuillez la corriger.'),
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
