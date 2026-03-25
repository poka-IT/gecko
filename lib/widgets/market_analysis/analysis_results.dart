import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/market_analysis_provider.dart';
import 'package:gecko/services/market_analysis_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

/// Displays analysis results: progress indicator, aggregate summary card,
/// per-contact result cards, other-contacts section, and export button.
class AnalysisResults extends ConsumerWidget {
  const AnalysisResults({
    super.key,
    required this.state,
    required this.walletAddress,
    required this.walletName,
    required this.onExport,
  });

  /// Current market analysis state.
  final MarketAnalysisState state;

  /// Address of the wallet being analyzed.
  final String walletAddress;

  /// Display name of the wallet.
  final String walletName;

  /// Callback invoked when the export button is tapped.
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress indicator during analysis
        if (state.isAnalyzing) ...[
          ScaledSizedBox(height: 12),
          LinearProgressIndicator(
            value: state.totalContacts > 0 ? state.processedContacts / state.totalContacts : null,
          ),
          ScaledSizedBox(height: 4),
          Text(
            '${state.processedContacts} / ${state.totalContacts}',
            style: scaledTextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          ScaledSizedBox(height: 8),
        ],

        // Aggregate summary card
        if (state.hasResults) ...[_buildSummaryCard(context), ScaledSizedBox(height: 12)],

        // Per-contact result cards
        if (state.contactResults.isNotEmpty)
          ...state.contactResults.entries.map((entry) => _buildContactCard(context, entry.value, showAvatar: true)),

        // Other contacts section
        if (state.otherContactResults.isNotEmpty) ...[
          ScaledSizedBox(height: 16),
          Text('otherContacts'.tr(), style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ScaledSizedBox(height: 8),
          ...state.otherContactResults.entries.map(
            (entry) => _buildContactCard(context, entry.value, showAvatar: false),
          ),
        ],

        // Export button
        if (state.hasResults && !state.isAnalyzing) ...[
          ScaledSizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onExport,
            icon: Icon(Icons.copy, size: scaleSize(18)),
            label: Text('copyMarkdownReport'.tr(), style: scaledTextStyle(fontSize: 14)),
          ),
          ScaledSizedBox(height: 16),
        ],
      ],
    );
  }

  /// Builds the aggregate summary card showing total sent/received/count.
  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(scaleSize(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('totalSummary'.tr(), style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ScaledSizedBox(height: 12),
            _buildAmountRow(context, 'totalSent'.tr(), state.totalSent),
            ScaledSizedBox(height: 6),
            _buildAmountRow(context, 'totalReceived'.tr(), state.totalReceived),
            ScaledSizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('transactions'.tr(), style: scaledTextStyle(fontSize: 14)),
                Text(
                  '${state.totalTransactionCount}',
                  style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a row with a label and a BalanceDisplay amount.
  Widget _buildAmountRow(BuildContext context, String label, BigInt amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: scaledTextStyle(fontSize: 14)),
        BalanceDisplay(value: amount, size: 14),
      ],
    );
  }

  /// Builds a card for a single contact's analysis results.
  Widget _buildContactCard(BuildContext context, ContactAnalysisResult result, {required bool showAvatar}) {
    final displayName = result.username ?? getShortPubkey(result.address);

    return Card(
      margin: EdgeInsets.only(bottom: scaleSize(8)),
      child: Padding(
        padding: EdgeInsets.all(scaleSize(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact header
            Row(
              children: [
                if (showAvatar) ...[
                  SizedBox(
                    width: scaleSize(36),
                    height: scaleSize(36),
                    child: DatapodAvatar(address: result.address, size: scaleSize(36)),
                  ),
                  ScaledSizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result.username != null)
                        Text(
                          getShortPubkey(result.address),
                          style: scaledTextStyle(fontSize: 11, color: context.colorScheme.outline),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            ScaledSizedBox(height: 8),
            // Sent / Received / Count
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('sent'.tr(), style: scaledTextStyle(fontSize: 12, color: context.colorScheme.outline)),
                      BalanceDisplay(value: result.totalSent, size: 13),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('received'.tr(), style: scaledTextStyle(fontSize: 12, color: context.colorScheme.outline)),
                      BalanceDisplay(value: result.totalReceived, size: 13),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('transactions'.tr(), style: scaledTextStyle(fontSize: 12, color: context.colorScheme.outline)),
                    Text(
                      '${result.transactionCount}',
                      style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
