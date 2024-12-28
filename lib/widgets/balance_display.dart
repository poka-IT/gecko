import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/ud_unit_display.dart';

class BalanceDisplay extends StatelessWidget {
  final int value;
  final double size;
  final Color color;
  final FontWeight fontWeight;

  const BalanceDisplay({
    super.key,
    required this.value,
    this.size = 16,
    this.color = Colors.black,
    this.fontWeight = FontWeight.normal,
  });

  double _removeDecimalZero(double n) {
    String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 3);
    return double.parse(result);
  }

  @override
  Widget build(BuildContext context) {
    final isUdUnit = configBox.get('isUdUnit') ?? false;
    final unitRatio = isUdUnit ? 1 : 100;
    final valueRatio = _removeDecimalZero((value / balanceRatio) / unitRatio);

    late String finalValue;
    if (valueRatio >= 1000000) {
      finalValue = '${(valueRatio / 1000000).toStringAsFixed(2)}M';
    } else {
      finalValue = valueRatio.toString();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          finalValue,
          style: scaledTextStyle(fontSize: size, color: color, fontWeight: fontWeight),
        ),
        ScaledSizedBox(width: 5),
        UdUnitDisplay(size: scaleSize(size), color: color, fontWeight: fontWeight),
      ],
    );
  }
}
