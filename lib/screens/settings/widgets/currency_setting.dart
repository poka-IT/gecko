import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/trm_data_provider.dart';

/// Currency display-mode selector (G1 / DU / M/N).
class CurrencySetting extends ConsumerWidget {
  const CurrencySetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calculate_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Text(
              'currencyDisplayMode'.tr(),
              style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
        ScaledSizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final currentMode = ref.watch(currencyDisplayModeProvider);
            final trmData = ref.watch(trmDataProvider);

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SegmentedButton<CurrencyDisplayMode>(
                        segments: <ButtonSegment<CurrencyDisplayMode>>[
                          ButtonSegment(
                            value: CurrencyDisplayMode.g1,
                            label: Text(Durt.i.network.symbol),
                            icon: const Icon(Icons.straighten),
                          ),
                          ButtonSegment(
                            value: CurrencyDisplayMode.du,
                            label: Text('DU'),
                            icon: const Icon(Icons.water_drop_rounded),
                          ),
                          ButtonSegment(
                            value: CurrencyDisplayMode.moneyOverMembers,
                            label: Text('M/N'),
                            icon: const Icon(Icons.trending_up_rounded),
                          ),
                        ],
                        selected: {currentMode},
                        onSelectionChanged: (Set<CurrencyDisplayMode> newSelection) {
                          ref.read(currencyDisplayModeProvider.notifier).setDisplayMode(newSelection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                          selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                ScaledSizedBox(height: 8),
                // Display current mode description
                Text(
                  _getDisplayModeDescription(currentMode, trmData),
                  style: scaledTextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _getDisplayModeDescription(CurrencyDisplayMode mode, AsyncValue<TrmData> trmData) {
    switch (mode) {
      case CurrencyDisplayMode.g1:
        return 'displayG1Description'.tr();
      case CurrencyDisplayMode.du:
        return 'displayDUDescription'.tr();
      case CurrencyDisplayMode.moneyOverMembers:
        return trmData.when(
          data: (data) => 'displayMNDescription'.tr(),
          loading: () => 'displayMNDescription'.tr(),
          error: (_, _) => 'displayMNDescriptionError'.tr(),
        );
    }
  }
}
