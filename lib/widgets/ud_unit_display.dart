import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class UdUnitDisplay extends StatelessWidget {
  const UdUnitDisplay({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    return isUdUnit
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'ud'.tr(args: ['']),
                style: TextStyle(fontSize: size, color: color),
              ),
              Column(
                children: [
                  Text(
                    currencyName,
                    style: TextStyle(
                        fontSize: size * 0.7,
                        fontWeight: FontWeight.w500,
                        color: color),
                  ),
                  const SizedBox(height: 15)
                ],
              )
            ],
          )
        : Text(currencyName, style: TextStyle(fontSize: size, color: color));
  }
}
