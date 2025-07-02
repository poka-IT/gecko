import 'package:durt2/durt2.dart' show WalletEntity, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ShowSeed extends StatelessWidget {
  const ShowSeed({Key? keyMyWallets, required this.walletName, required this.walletProvider})
    : super(key: keyMyWallets);
  final String? walletName;
  final MyWalletsProvider walletProvider;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    WalletEntity defaultWallet = myWalletProvider.getDefaultWallet();

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('myMnemonic'.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
            child: Column(
              children: <Widget>[
                FutureBuilder(
                  future: Durt.i.wallets.getSeed(address: defaultWallet.address, pin: walletProvider.pinCode),
                  builder: (BuildContext context, AsyncSnapshot<String?> seed) {
                    if (seed.connectionState != ConnectionState.done || seed.hasError) {
                      return ScaledSizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2),
                      );
                    } else if (!seed.hasData) {
                      return const Text('');
                    }

                    return Column(
                      children: [
                        BuildText(text: 'keepYourMnemonicSecret'.tr(), size: 16),
                        ScaledSizedBox(height: 35),
                        sentanceArray(context, seed.data!.split(' ')),
                        ScaledSizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaledSizedBox(
                              height: 39,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  backgroundColor: context.colorScheme.primary,
                                  elevation: 1,
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: seed.data!));
                                  snackCopySeed(context);
                                },
                                child: Row(
                                  children: <Widget>[
                                    Image.asset('assets/walletOptions/copy-white.png', height: scaleSize(24)),
                                    ScaledSizedBox(width: 7),
                                    Text('copy'.tr(), style: scaledTextStyle(fontSize: 13, color: Colors.grey[50])),
                                  ],
                                ),
                              ),
                            ),
                            ScaledSizedBox(width: 50),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return PrintWallet(seed.data);
                                    },
                                  ),
                                );
                              },
                              child: Image.asset('assets/printer.png', height: scaleSize(38)),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                ScaledSizedBox(height: 50),
                ScaledSizedBox(
                  width: 240,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: context.colorScheme.primary,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'close'.tr(),
                      style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sentanceArray(BuildContext context, List mnemonic) {
    return Container(
      constraints: BoxConstraints(maxWidth: scaleSize(360)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: const Color(0xffeeeedd),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: EdgeInsets.all(scaleSize(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              arrayCell(mnemonic[0], 1),
              arrayCell(mnemonic[1], 2),
              arrayCell(mnemonic[2], 3),
              arrayCell(mnemonic[3], 4),
            ],
          ),
          ScaledSizedBox(height: 15),
          Row(
            children: <Widget>[
              arrayCell(mnemonic[4], 5),
              arrayCell(mnemonic[5], 6),
              arrayCell(mnemonic[6], 7),
              arrayCell(mnemonic[7], 8),
            ],
          ),
          ScaledSizedBox(height: 15),
          Row(
            children: <Widget>[
              arrayCell(mnemonic[8], 9),
              arrayCell(mnemonic[9], 10),
              arrayCell(mnemonic[10], 11),
              arrayCell(mnemonic[11], 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget arrayCell(String dataWord, int nbr) {
    return ScaledSizedBox(
      width: 82,
      child: Column(
        children: <Widget>[
          Text(nbr.toString(), style: scaledTextStyle(fontSize: 10, color: const Color(0xff6b6b52))),
          Text(
            dataWord,
            key: keyMnemonicWord(dataWord),
            style: scaledTextStyle(fontSize: 15, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class PrintWallet extends StatelessWidget {
  const PrintWallet(this.sentence, {super.key});

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
            },
          ),
          backgroundColor: context.colorScheme.secondary,
          foregroundColor: Colors.black,
          toolbarHeight: scaleSize(57),
          title: Text('printMyMnemonic'.tr(), style: scaledTextStyle(fontWeight: FontWeight.w600)),
        ),
        body: PdfPreview(canDebug: false, canChangeOrientation: false, build: (format) => printWallet(sentence!)),
      ),
    );
  }

  Future<Uint8List> printWallet(String seed) async {
    final ByteData fontData = await rootBundle.load("assets/OpenSans-Regular.ttf");
    final pw.Font ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final pdf = pw.Document();

    final seedList = seed.split(' ');

    const imageProvider = AssetImage('assets/icon/gecko_final.png');
    final geckoLogo = await flutterImageProvider(imageProvider);

    pw.Widget arrayCell(int number, String dataWord) {
      return pw.SizedBox(
        width: 120,
        height: 70,
        child: pw.Column(
          children: <pw.Widget>[
            pw.Text(
              number.toString(),
              style: pw.TextStyle(fontSize: 14, color: const PdfColor(0.5, 0, 0), font: ttf),
            ),
            pw.Text(
              dataWord,
              style: pw.TextStyle(fontSize: 19, color: const PdfColor(0, 0, 0), font: ttf),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Stack(
            children: <pw.Widget>[
              pw.Positioned(top: 217, child: pw.Text('-'.padRight(130, '-'))),
              pw.Positioned(bottom: 217, child: pw.Text('-'.padRight(130, '-'))),
              pw.Column(
                // mainAxisAlignment: pw.MainAxisAlignment.center,
                // mainAxisSize: pw.MainAxisSize.max,
                // crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: <pw.Widget>[
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: <pw.Widget>[
                      arrayCell(1, seedList[0]),
                      arrayCell(2, seedList[1]),
                      arrayCell(3, seedList[2]),
                      arrayCell(4, seedList[3]),
                    ],
                  ),
                  pw.Row(
                    children: <pw.Widget>[
                      arrayCell(5, seedList[4]),
                      arrayCell(6, seedList[5]),
                      arrayCell(7, seedList[6]),
                      arrayCell(8, seedList[7]),
                    ],
                  ),
                  pw.Row(
                    children: <pw.Widget>[
                      arrayCell(9, seedList[8]),
                      arrayCell(10, seedList[9]),
                      arrayCell(11, seedList[10]),
                      arrayCell(12, seedList[11]),
                    ],
                  ),
                  pw.SizedBox(height: 105),
                  pw.Image(geckoLogo, height: 80),
                  pw.SizedBox(height: 205),
                  pw.Text(
                    "keepThisPaperSafe".tr(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 14, font: ttf),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
