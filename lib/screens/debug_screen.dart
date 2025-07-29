import 'package:durt2/durt2.dart' hide Provider;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart' as old_provider;

import 'package:gecko/providers_deprecated/block_height_provider.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('Debug'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaledSizedBox(height: isSmallScreen ? 16 : 24),

                // Section Nœud
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 12 : 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dns_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
                            ScaledSizedBox(width: 12),
                            Text(
                              'currencyNode'.tr(),
                              style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSecondaryContainer),
                            ),
                          ],
                        ),
                        ScaledSizedBox(height: 12),
                        Text(
                          'node: ${Networks.duniterEndpoint}',
                          style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                        ),
                        ScaledSizedBox(height: 8),
                        old_provider.Consumer<BlockHeightProvider>(
                          builder: (context, blockHeightProvider, child) {
                            return Text(
                              'blockN'.tr(args: [blockHeightProvider.blockHeight.toString()]),
                              style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSecondaryContainer),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 16 : 24),

                // Section Actions
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 12 : 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.build_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
                            ScaledSizedBox(width: 12),
                            Text(
                              'Actions',
                              style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSecondaryContainer),
                            ),
                          ],
                        ),
                        ScaledSizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: context.colorScheme.primary,
                              padding: EdgeInsets.symmetric(vertical: scaleSize(12)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              await ref.read(duniterServiceProvider).spawnBlock();
                            },
                            child: Text(
                              'Spawn a bloc',
                              style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
