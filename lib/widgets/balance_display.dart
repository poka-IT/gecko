import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/system.service.dart';
import 'package:gecko/widgets/ud_unit_display.dart';

class BalanceDisplay extends StatelessWidget {
  final BigInt value;
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

  String _toSuperscript(String numberStr) {
    const Map<String, String> superscriptMap = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '-': '⁻',
    };
    return numberStr.split('').map((char) => superscriptMap[char] ?? char).join('');
  }

  // Helper for scientific notation (used for both small and very large numbers)
  String _formatScientificNotation(double value) {
    String expStr = value.toStringAsExponential(2);
    int eIndex = expStr.indexOf('e');
    if (eIndex != -1) {
      String mantissa = expStr.substring(0, eIndex);
      String exponentValue = expStr.substring(eIndex + 1);
      if (exponentValue.startsWith('+')) {
        exponentValue = exponentValue.substring(1);
      }
      return '$mantissa×10${_toSuperscript(exponentValue)}';
    } else {
      // Fallback, though toStringAsExponential should always produce 'e' for non-zero finite numbers.
      return _removeDecimalZero(value).toString();
    }
  }

  // Helper to format a value into Billions, Millions, direct, or very large scientific.
  // Returns a map containing the final string value and the prefix (M or B).
  Map<String, String> _getStandardFormattedParts(double valueToFormat) {
    String finalNumericValue;
    String prefix = "";

    final double absValue = valueToFormat.abs();

    if (absValue >= 1.0e12) {
      // 1000 Billions or more -> scientific
      finalNumericValue = _formatScientificNotation(valueToFormat);
      // prefix remains ""
    } else {
      // For B, M, direct, we operate on the value after _removeDecimalZero
      final double displayValue = _removeDecimalZero(valueToFormat);
      final double absDisplayValue = displayValue.abs();

      if (absDisplayValue >= 1000000000) {
        // Billions
        finalNumericValue = (displayValue / 1000000000).toStringAsFixed(2);
        prefix = "B";
      } else if (absDisplayValue >= 1000000) {
        // Millions
        finalNumericValue = (displayValue / 1000000).toStringAsFixed(2);
        prefix = "M";
      } else {
        // Direct
        finalNumericValue = displayValue.toString();
        // prefix remains ""
      }
    }
    return {'value': finalNumericValue, 'prefix': prefix};
  }

  @override
  Widget build(BuildContext context) {
    final isUdUnit = configBox.get('isUdUnit') ?? false;
    final double rawValueInMainUnit = value / SystemService.balanceRatio;

    late String finalValue;
    String displayPrefix = "";

    if (isUdUnit) {
      final double absRawValueInDU = rawValueInMainUnit.abs();
      if (absRawValueInDU > 0 && absRawValueInDU < 0.01) {
        // Special case for small DU values
        finalValue = _formatScientificNotation(rawValueInMainUnit);
        // displayPrefix remains "", as scientific notation doesn't use M/B prefixes here
      } else {
        // Standard DU formatting (includes large scientific, B, M, or direct)
        Map<String, String> parts = _getStandardFormattedParts(rawValueInMainUnit);
        finalValue = parts['value']!;
        displayPrefix = parts['prefix']!;
      }
    } else {
      // Not isUdUnit: displaying in a subunit
      final double valueInSubUnit = rawValueInMainUnit / 100.0;
      Map<String, String> parts = _getStandardFormattedParts(valueInSubUnit);
      finalValue = parts['value']!;
      displayPrefix = parts['prefix']!;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          finalValue,
          style: scaledTextStyle(fontSize: size, color: color, fontWeight: fontWeight),
        ),
        ScaledSizedBox(width: 5),
        UdUnitDisplay(size: scaleSize(size), color: color, fontWeight: fontWeight, valuePrefix: displayPrefix),
      ],
    );
  }
}
