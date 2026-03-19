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
          border: Border.all(color: context.geckoColors.danger),
          color: context.colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.all(scaleSize(14)),
        child: Center(
          child: Text(
            'Invalid mnemonic: expected 12 words, got ${mnemonicWords.length}',
            style: scaledTextStyle(fontSize: 15, color: context.geckoColors.danger),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final int cols = constraints.maxWidth >= 600 ? 6 : 4;
              final rows = <Widget>[];
              for (int i = 0; i < 12; i += cols) {
                if (i > 0) rows.add(ScaledSizedBox(height: 15));
                rows.add(
                  Row(
                    children: <Widget>[
                      for (int j = i; j < i + cols && j < 12; j++) _arrayCell(context, j + 1, mnemonicWords[j]),
                    ],
                  ),
                );
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: rows,
              );
            },
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
