import 'package:durt2/durt2.dart' show WalletEntity, Durt, BidouilleLang;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/security_providers.dart';
import 'package:gecko/providers_deprecated/bottom_app_bar_provider.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/buttons/primary_button.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/commons/mnemonic_display.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:pdf/widgets.dart' as pw;

class ShowSeed extends ConsumerWidget {
  const ShowSeed({Key? keyMyWallets, required this.walletName, required this.walletProvider})
    : super(key: keyMyWallets);
  final String walletName;
  final MyWalletsProvider walletProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

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
                // Use combined provider to load everything at once - no more double loading
                ref
                    .watch(seedDisplayProvider((address: defaultWallet.address, pin: walletProvider.pinCode)))
                    .when(
                      loading: () => Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 173),
                            Loading(stroke: 4, size: 40),
                            const SizedBox(height: 173),
                          ],
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 173),
                            Icon(Icons.error_outline, size: 48, color: context.colorScheme.error),
                            const SizedBox(height: 16),
                            Text(
                              'errorRetrievingSeed'.tr(),
                              style: scaledTextStyle(fontSize: 16, color: context.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Possible wrong PIN code',
                              style: scaledTextStyle(
                                fontSize: 14,
                                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 173),
                          ],
                        ),
                      ),
                      data: (seedData) {
                        final englishMnemonic = seedData.englishMnemonic;
                        final displayMnemonic = seedData.displayMnemonic;
                        // Validate that the mnemonic has exactly 12 words
                        final mnemonicWords = displayMnemonic.trim().split(RegExp(r'\s+'));
                        if (mnemonicWords.length != 12 || mnemonicWords.any((word) => word.isEmpty)) {
                          return Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 173),
                                Icon(Icons.error_outline, size: 48, color: context.colorScheme.error),
                                const SizedBox(height: 16),
                                Text(
                                  'invalidMnemonicFormat'.tr(),
                                  style: scaledTextStyle(fontSize: 16, color: context.colorScheme.error),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 173),
                              ],
                            ),
                          );
                        }

                        // Check if the safe language is not English to show export button
                        final safeLanguage = Durt.i.wallets.getSafeMnemonicLanguage(defaultWallet.safe.target?.number);
                        final isEnglish = safeLanguage == BidouilleLang.english;

                        return Column(
                          children: [
                            BuildText(text: 'keepYourMnemonicSecret'.tr(), size: 16),
                            ScaledSizedBox(height: 35),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(12)),
                              child: MnemonicDisplayWidget(
                                mnemonicWords: mnemonicWords,
                                isLoading: false,
                                useWordAsKey: true, // Use word as key for show_seed
                              ),
                            ),
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
                                      Clipboard.setData(ClipboardData(text: displayMnemonic));
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
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.printWallet,
                                      arguments: PrintWalletArguments(sentence: displayMnemonic),
                                    );
                                  },
                                  child: Image.asset(
                                    'assets/printer.png',
                                    height: scaleSize(38),
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            // Show English export button if safe language is not English
                            if (!isEnglish) ...[
                              ScaledSizedBox(height: 20),
                              ScaledSizedBox(
                                height: 39,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    backgroundColor: context.colorScheme.secondary,
                                    elevation: 1,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: englishMnemonic));

                                    // Calculate bottom margin based on bottom app bar visibility
                                    final bottomBarProvider = old_provider.Provider.of<BottomAppBarProvider>(
                                      context,
                                      listen: false,
                                    );
                                    final isBottomBarVisible = bottomBarProvider.isBottomBarActuallyVisible;
                                    final bottomMargin = isBottomBarVisible
                                        ? scaleSize(67) + 16.0
                                        : 16.0; // Bottom bar height + standard margin

                                    context.showDismissibleSnackBar(
                                      SnackBar(
                                        content: Text('englishMnemonicCopied'.tr()),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomMargin),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.translate, size: scaleSize(20), color: context.colorScheme.onSurface),
                                      ScaledSizedBox(width: 7),
                                      Text(
                                        'exportInEnglish'.tr(),
                                        style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                ScaledSizedBox(height: 50),
                PrimaryButton(
                  label: 'close'.tr(),
                  width: 240,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrintWallet extends StatelessWidget {
  const PrintWallet(this.sentence, {super.key});

  final String sentence;

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
        body: PdfPreview(canDebug: false, canChangeOrientation: false, build: (format) => printWallet(sentence)),
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
