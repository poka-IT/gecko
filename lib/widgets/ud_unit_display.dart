import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class UdUnitDisplay extends StatelessWidget {
  const UdUnitDisplay({
    super.key,
    required this.size,
    required this.color,
    this.fontWeight = FontWeight.normal,
    this.valuePrefix = "",
  });

  final double size;
  final Color color;
  final FontWeight fontWeight;
  final String valuePrefix;

  @override
  Widget build(BuildContext context) {
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;

    Widget prefixWidget = const SizedBox.shrink();
    if (valuePrefix.isNotEmpty) {
      prefixWidget = Text(
        valuePrefix,
        style: TextStyle(
          fontSize: size,
          color: color == Colors.white ? color : Colors.red,
          fontWeight: fontWeight,
        ),
      );
    }

    if (isUdUnit) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (valuePrefix.isNotEmpty) ...[
            prefixWidget,
            const SizedBox(width: 0.5),
          ],
          Text(
            'ud'.tr(args: ['']),
            style: TextStyle(fontSize: size, color: color, fontWeight: fontWeight),
          ),
          const SizedBox(width: 2.0),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currencyName,
                style: TextStyle(fontSize: size * 0.65, fontWeight: fontWeight, color: color),
              ),
              const SizedBox(height: 15)
            ],
          )
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (valuePrefix.isNotEmpty) ...[
            prefixWidget,
            const SizedBox(width: 0.5),
          ],
          Text(currencyName, style: TextStyle(fontSize: size, color: color, fontWeight: fontWeight)),
        ],
      );
    }
  }
}
