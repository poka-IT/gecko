import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';

class MnemonicDisplayWidget extends StatelessWidget {
  const MnemonicDisplayWidget({
    super.key,
    required this.mnemonicWords,
    this.isLoading = false,
    this.useWordAsKey = false,
  });

  final List<String> mnemonicWords;
  final bool isLoading;
  final bool useWordAsKey; // If true, use word as key; if false, use index

  @override
  Widget build(BuildContext context) {
    // Validate that we have exactly 12 words
    if (mnemonicWords.length != 12) {
      return Container(
        constraints: BoxConstraints(maxWidth: scaleSize(360)),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: context.colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.all(scaleSize(14)),
        child: Center(
          child: Text(
            'Invalid mnemonic: expected 12 words, got ${mnemonicWords.length}',
            style: scaledTextStyle(fontSize: 15, color: Colors.red),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity, // Make container fully adaptive
      constraints: BoxConstraints(
        maxWidth: scaleSize(450), // Increased max width to accommodate larger text
        minWidth: scaleSize(320), // Minimum width for small screens
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: context.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding: EdgeInsets.all(scaleSize(14)),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // First row: words 1-4
              Row(
                children: <Widget>[
                  _arrayCell(context, 1, mnemonicWords[0]),
                  _arrayCell(context, 2, mnemonicWords[1]),
                  _arrayCell(context, 3, mnemonicWords[2]),
                  _arrayCell(context, 4, mnemonicWords[3]),
                ],
              ),
              ScaledSizedBox(height: 15),
              // Second row: words 5-8
              Row(
                children: <Widget>[
                  _arrayCell(context, 5, mnemonicWords[4]),
                  _arrayCell(context, 6, mnemonicWords[5]),
                  _arrayCell(context, 7, mnemonicWords[6]),
                  _arrayCell(context, 8, mnemonicWords[7]),
                ],
              ),
              ScaledSizedBox(height: 15),
              // Third row: words 9-12
              Row(
                children: <Widget>[
                  _arrayCell(context, 9, mnemonicWords[8]),
                  _arrayCell(context, 10, mnemonicWords[9]),
                  _arrayCell(context, 11, mnemonicWords[10]),
                  _arrayCell(context, 12, mnemonicWords[11]),
                ],
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: const Color(0xffeeeedd).withValues(alpha: 0.7),
              child: Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _arrayCell(BuildContext context, int index, String dataWord) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(4)), // Add horizontal padding for spacing
        child: Column(
          children: <Widget>[
            Text(index.toString(), style: scaledTextStyle(fontSize: 10, color: const Color(0xff6b6b52))),
            ScaledSizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                dataWord,
                key: useWordAsKey ? keyMnemonicWord(dataWord) : keyMnemonicWord(index.toString()),
                style: scaledTextStyle(fontSize: 15, color: context.colorScheme.onSurface),
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
