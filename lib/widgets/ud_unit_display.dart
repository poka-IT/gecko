import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class UdUnitDisplay extends StatelessWidget {
  const UdUnitDisplay({
    super.key,
    required this.size,
    required this.color,
    this.fontWeight = FontWeight.normal,
  });

  final double size;
  final Color color;
  final FontWeight fontWeight;
  @override
  Widget build(BuildContext context) {
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    return isUdUnit
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'ud'.tr(args: ['']),
                style: TextStyle(fontSize: size, color: color, fontWeight: fontWeight),
              ),
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
          )
        : Text(currencyName, style: TextStyle(fontSize: size, color: color, fontWeight: fontWeight));
  }
}
