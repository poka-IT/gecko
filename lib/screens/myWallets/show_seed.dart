import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ShowSeed extends StatelessWidget {
  const ShowSeed(
      {Key? keyMyWallets,
      required this.walletName,
      required this.walletProvider})
      : super(key: keyMyWallets);
  final String? walletName;
  final MyWalletsProvider walletProvider;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    CommonElements common = CommonElements();

    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = myWalletProvider.getDefaultWallet();

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: SizedBox(
              height: 22,
              child: Text('myMnemonic'.tr()),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            const Spacer(flex: 1),
            FutureBuilder(
                future:
                    sub.getSeed(defaultWallet.address!, walletProvider.pinCode),
                builder: (BuildContext context, AsyncSnapshot<String?> seed) {
                  if (seed.connectionState != ConnectionState.done ||
                      seed.hasError) {
                    return SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        color: orangeC,
                        strokeWidth: 2,
                      ),
                    );
                  } else if (!seed.hasData) {
                    return const Text('');
                  }

                  return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(children: [
                          common.buildText('keepYourMnemonicSecret'.tr()),
                          SizedBox(height: 35 * ratio),
                          sentanceArray(context, seed.data!.split(' ')),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 1,
                                primary: orangeC, // background
                                onPrimary: Colors.black, // foreground
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: seed.data));
                                snackCopyKey(context);
                              },
                              child: Row(children: <Widget>[
                                Image.asset(
                                  'assets/walletOptions/copy-white.png',
                                  height: 25,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'copy'.tr(),
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.grey[50]),
                                )
                              ]),
                            ),
                          ),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return PrintWallet(seed.data);
                                }),
                              );
                            },
                            child: Image.asset(
                              'assets/printer.png',
                              height: 42 * ratio,
                            ),
                          ),
                        ]),
                      ]);
                }),
            const Spacer(flex: 2),
            SizedBox(
              width: 380 * ratio,
              height: 60 * ratio,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  primary: orangeC, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'close'.tr(),
                  style: TextStyle(
                      fontSize: 23 * ratio, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Spacer(flex: 2),
          ]),
        ));
  }

  snackCopyKey(context) {
    const snackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text(
            "Votre phrase de restauration a été copié dans votre presse-papier.",
            style: TextStyle(fontSize: 16)),
        duration: Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget sentanceArray(BuildContext context, List mnemonic) {
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
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(children: <Widget>[
                  arrayCell(mnemonic[0], 1),
                  arrayCell(mnemonic[1], 2),
                  arrayCell(mnemonic[2], 3),
                  arrayCell(mnemonic[3], 4),
                ]),
                const SizedBox(height: 15),
                Row(children: <Widget>[
                  arrayCell(mnemonic[4], 5),
                  arrayCell(mnemonic[5], 6),
                  arrayCell(mnemonic[6], 7),
                  arrayCell(mnemonic[7], 8),
                ]),
                const SizedBox(height: 15),
                Row(children: <Widget>[
                  arrayCell(mnemonic[8], 9),
                  arrayCell(mnemonic[9], 10),
                  arrayCell(mnemonic[10], 11),
                  arrayCell(mnemonic[11], 12),
                ]),
              ])),
    );
  }

  Widget arrayCell(dataWord, int nbr) {
    log.d(nbr);

    return SizedBox(
      width: 100,
      child: Column(children: <Widget>[
        Text(
          nbr.toString(),
          style:
              TextStyle(fontSize: 13 * ratio, color: const Color(0xff6b6b52)),
        ),
        Text(
          dataWord,
          key: keyMnemonicWord(dataWord),
          style: TextStyle(fontSize: 17 * ratio, color: Colors.black),
        ),
      ]),
    );
  }
}

class PrintWallet extends StatelessWidget {
  const PrintWallet(this.sentence, {Key? key}) : super(key: key);

  final String? sentence;

  @override
  Widget build(BuildContext context) {
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
          title: SizedBox(
            height: 22,
            child: Text(
              'printMyMnemonic'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        body: PdfPreview(
          canDebug: false,
          canChangeOrientation: false,
          build: (format) => printWallet(sentence!),
        ),
      ),
    );
  }

  Future<Uint8List> printWallet(String seed) async {
    final ByteData fontData =
        await rootBundle.load("assets/OpenSans-Regular.ttf");
    final pw.Font ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final pdf = pw.Document();
    int nbr = 1;

    final seedList = seed.split(' ');

    // const imageProvider = AssetImage('assets/icon/gecko_final.png');
    // final geckoLogo = await flutterImageProvider(imageProvider);

    pw.Widget arrayCell(String dataWord, int nbr) {
      nbr++;

      return pw.SizedBox(
        width: 120,
        child: pw.Column(children: <pw.Widget>[
          pw.Text(
            nbr.toString(),
            style: pw.TextStyle(
                fontSize: 15, color: const PdfColor(0.5, 0, 0), font: ttf),
          ),
          pw.Text(
            dataWord,
            style: pw.TextStyle(
                fontSize: 20, color: const PdfColor(0, 0, 0), font: ttf),
          ),
          pw.SizedBox(height: 10)
        ]),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            // mainAxisAlignment: pw.MainAxisAlignment.center,
            // mainAxisSize: pw.MainAxisSize.max,
            // crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: <pw.Widget>[
              pw.Row(children: <pw.Widget>[
                arrayCell(seedList[0], nbr),
                arrayCell(seedList[1], nbr),
                arrayCell(seedList[2], nbr),
                arrayCell(seedList[3], nbr),
              ]),
              pw.Row(children: <pw.Widget>[
                arrayCell(seedList[4], nbr),
                arrayCell(seedList[5], nbr),
                arrayCell(seedList[6], nbr),
                arrayCell(seedList[7], nbr),
              ]),
              pw.Row(children: <pw.Widget>[
                arrayCell(seedList[8], nbr),
                arrayCell(seedList[9], nbr),
                arrayCell(seedList[10], nbr),
                arrayCell(seedList[11], nbr)
              ]),
              pw.Expanded(
                  child: pw.Align(
                      alignment: pw.Alignment.bottomCenter,
                      child: pw.Text(
                        "Gardez cette feuille préciseusement, à l’abri des lézards indiscrets.",
                        style: pw.TextStyle(fontSize: 15, font: ttf),
                      )))
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
