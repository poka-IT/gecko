import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/trm_data_provider.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';
import 'package:gecko/routes.dart';

class BalanceDisplay extends ConsumerWidget {
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
  String _formatNumber(double displayValue, CurrencyDisplayMode mode) {
    if (displayValue == 0) return '0';

    final double absValue = displayValue.abs();
    final bool isNegative = displayValue < 0;
    final String sign = isNegative ? '-' : '';

    String finalNumericValue;
    if (absValue >= 1e15) {
      // For very large numbers, use scientific notation
      finalNumericValue = _formatScientificNotation(displayValue);
    } else if (absValue >= 1e9) {
      // For billions, use G suffix
      finalNumericValue = (displayValue / 1000000000).toStringAsFixed(2);
      return '$sign${finalNumericValue}G';
    } else if (absValue >= 1e6) {
      // For millions, use M suffix
      finalNumericValue = (displayValue / 1000000).toStringAsFixed(2);
      return '$sign${finalNumericValue}M';
    } else {
      // For normal numbers, use different precision based on mode
      if (mode == CurrencyDisplayMode.du || mode == CurrencyDisplayMode.moneyOverMembers) {
        // For DU and M/N, round to 3 decimal places (0.001 precision)
        finalNumericValue = displayValue.toStringAsFixed(3);
        // Remove trailing zeros
        if (finalNumericValue.contains('.')) {
          finalNumericValue = finalNumericValue.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
        }
      } else {
        // For G1, use standard formatting
        finalNumericValue = displayValue.toString();
      }
      return finalNumericValue;
    }

    return finalNumericValue;
  }

  Widget _buildCurrencyDisplay(
    CurrencyDisplayMode displayMode,
    String formattedNumber,
    String currencySymbol,
    String valuePrefix,
  ) {
    Widget prefixWidget = const SizedBox.shrink();
    if (valuePrefix.isNotEmpty) {
      prefixWidget = Text(
        valuePrefix,
        style: TextStyle(fontSize: size, color: color == Colors.white ? color : Colors.red, fontWeight: fontWeight),
      );
    }

    // Get current route
    final container = ProviderScope.containerOf(homeContext);
    final currentRoute = container.read(currentRouteProvider);
    final isMyWallets = currentRoute == RouteNames.myWallets;

    final currencyTextColor = isMyWallets ? color : homeContext.colorScheme.outline;

    if (displayMode == CurrencyDisplayMode.du || displayMode == CurrencyDisplayMode.moneyOverMembers) {
      // DU and mM/N modes: display like "prefix + [unit] + symbol as superscript"
      String unitText = displayMode == CurrencyDisplayMode.du ? 'DU' : 'mM/N';

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (valuePrefix.isNotEmpty) ...[prefixWidget, const SizedBox(width: 0.5)],
          Flexible(
            child: Text(
              formattedNumber,
              style: scaledTextStyle(fontSize: size, color: color, fontWeight: fontWeight),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            unitText,
            style: scaledTextStyle(fontSize: size, color: currencyTextColor, fontWeight: fontWeight),
          ),
          const SizedBox(width: 1.0),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Durt.i.network.symbol,
                style: scaledTextStyle(fontSize: size * 0.6, fontWeight: fontWeight, color: currencyTextColor),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      );
    } else {
      // G1 mode: display like "formatted_number prefix + symbol"
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedNumber,
            style: scaledTextStyle(fontSize: size, color: color, fontWeight: fontWeight),
          ),
          const SizedBox(width: 6),
          if (valuePrefix.isNotEmpty) ...[prefixWidget, const SizedBox(width: 0.5)],
          Text(
            currencySymbol,
            style: scaledTextStyle(fontSize: size, color: currencyTextColor, fontWeight: fontWeight),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current display mode
    final displayMode = ref.watch(currencyDisplayModeProvider);

    // Get balance ratio using the provider
    final ratio = ref.watch(balanceRatioProvider);

    // If ratio is zero (DU data not yet loaded from blockchain), show placeholder
    if (ratio == BigInt.zero) {
      return Text(
        '—',
        style: scaledTextStyle(fontSize: size, color: color, fontWeight: fontWeight),
      );
    }

    // Calculate display value using the ratio
    final double displayValue = value.toDouble() / ratio.toDouble();

    // Get currency symbol
    final String currencySymbol = ref.watch(currencySymbolProvider);

    // Format the number and determine prefix
    final double absValue = displayValue.abs();
    String valuePrefix = "";
    String formattedNumber;

    // Special case for small DU and mM/N values (use scientific notation)
    if ((displayMode == CurrencyDisplayMode.du || displayMode == CurrencyDisplayMode.moneyOverMembers) &&
        absValue > 0 &&
        absValue < 0.01) {
      formattedNumber = _formatScientificNotation(displayValue);
    } else if (absValue >= 1e15) {
      // For very large numbers, use scientific notation
      formattedNumber = _formatScientificNotation(displayValue);
    } else if (absValue >= 1e9) {
      // For billions, use G suffix
      formattedNumber = (displayValue / 1000000000).toStringAsFixed(2);
      valuePrefix = "G";
    } else if (absValue >= 1e6) {
      // For millions, use M suffix
      formattedNumber = (displayValue / 1000000).toStringAsFixed(2);
      valuePrefix = "M";
    } else {
      formattedNumber = _formatNumber(displayValue, displayMode);
    }

    return _buildCurrencyDisplay(displayMode, formattedNumber, currencySymbol, valuePrefix);
  }
}
