import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';

/// Widget to indicate the start of history, either filtered or complete
class HistoryEndIndicator extends StatelessWidget {
  const HistoryEndIndicator({super.key, this.isFiltered = false});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ScaledSizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.blur_on_outlined, size: scaleSize(31)),
            Text(
              isFiltered ? "filteredHistoryStart".tr() : "historyStart".tr(),
              textAlign: TextAlign.center,
              style: scaledTextStyle(fontSize: 19, fontWeight: FontWeight.w300),
            ),
            Icon(Icons.blur_on_outlined, size: scaleSize(31)),
          ],
        ),
        ScaledSizedBox(height: 30),
      ],
    );
  }
}
