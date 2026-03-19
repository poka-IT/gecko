import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/desktop/modals/keyboard_shortcuts_modal.dart';

class DesktopTotalBalanceCard extends ConsumerWidget {
  const DesktopTotalBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == d.ConnectionStatus.connected;
    final safeGroups = ref.watch(safeWalletGroupsProvider);

    // Sum balances across ALL safes
    var total = BigInt.zero;
    var anyLoading = false;
    var anyError = false;

    for (final group in safeGroups) {
      final safeData = ref.watch(safeOnChainDataProvider(group.safe.number));
      safeData.when(
        data: (data) {
          for (final balance in data.balances.values) {
            total += balance.transferableBalance;
          }
        },
        loading: () => anyLoading = true,
        error: (_, _) => anyError = true,
      );
    }

    final Widget content;
    if (anyLoading && total == BigInt.zero) {
      // All safes still loading, show placeholder
      content = Text(
        '\u2013',
        style: scaledTextStyle(
          fontSize: 20,
          color: context.colorScheme.onSurface.withValues(alpha: 0.3),
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (anyError && total == BigInt.zero) {
      content = Text(
        'errorLoadingWalletData'.tr(),
        style: scaledTextStyle(fontSize: 12, color: context.geckoColors.danger),
      );
    } else {
      // Don't show "0" balance when not connected -- it's misleading
      final showPlaceholder = !isConnected && total == BigInt.zero;
      content = showPlaceholder
          ? Text(
              '\u2013',
              style: scaledTextStyle(
                fontSize: 20,
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            )
          : BalanceDisplay(value: total, size: 20, color: context.colorScheme.onSurface, fontWeight: FontWeight.bold);
    }

    return buildDesktopGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'soldeTotal'.tr(),
            style: scaledTextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: content),
        ],
      ),
    );
  }
}

class DesktopNetworkStatusCard extends ConsumerWidget {
  const DesktopNetworkStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final squidStatus = ref.watch(squidConnectionStatusProvider);
    final isDuniterConnected = connectionStatus == d.ConnectionStatus.connected;
    final isSquidConnected = squidStatus == d.ConnectionStatus.connected;

    String duniterDisplay = '';
    String squidDisplay = '';
    if (isDuniterConnected) {
      try {
        duniterDisplay = d.Networks.duniterEndpoint.replaceFirst('wss://', '').replaceFirst('ws://', '');
      } catch (_) {}
    }
    if (isSquidConnected) {
      try {
        squidDisplay = d.Networks.squidEndpoint.replaceFirst('https://', '').replaceFirst('http://', '');
      } catch (_) {}
    }

    return buildDesktopGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Node info (left side)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Duniter node row
                Row(
                  children: [
                    _buildStatusDot(isDuniterConnected, context),
                    const SizedBox(width: 6),
                    Text(
                      'Duniter',
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isDuniterConnected ? duniterDisplay : 'connecting'.tr(),
                        style: scaledTextStyle(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Squid indexer row
                Row(
                  children: [
                    _buildStatusDot(isSquidConnected, context),
                    const SizedBox(width: 6),
                    Text(
                      'indexer'.tr(),
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isSquidConnected ? squidDisplay : 'connecting'.tr(),
                        style: scaledTextStyle(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Block height -- isolated Consumer to avoid rebuilding the entire left panel every ~6s
          if (isDuniterConnected)
            Consumer(
              builder: (context, ref, _) {
                final blockHeight = ref.watch(blockHeightProvider);
                if (blockHeight <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '#$blockHeight',
                    style: scaledTextStyle(
                      fontSize: 12,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Monospace',
                    ),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
          // Keyboard shortcuts hint
          Tooltip(
            message: 'keyboardShortcuts'.tr(),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showKeyboardShortcutsModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_rounded,
                      size: 13,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'H',
                      style: scaledTextStyle(
                        fontSize: 11,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(bool isConnected, BuildContext context) {
    final color = isConnected ? context.geckoColors.connectionOk : context.geckoColors.connectionWarn;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }
}
