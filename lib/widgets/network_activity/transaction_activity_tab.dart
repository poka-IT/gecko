import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/widgets/network_activity/base_activity_tab.dart';
import 'package:gecko/widgets/transaction_filters.dart';
import 'package:gecko/widgets/transaction_tile.dart';

class TransactionActivityTab extends ConsumerWidget {
  const TransactionActivityTab({
    super.key,
    required this.scrollController,
    required this.filterTranslationY,
    this.onNewActivityDetected,
  });

  final ScrollController scrollController;
  final double filterTranslationY;
  final VoidCallback? onNewActivityDetected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseActivityTab<NetworkActivityState>(
      scrollController: scrollController,
      filterTranslationY: filterTranslationY,
      onNewActivityDetected: onNewActivityDetected,
      activityProvider: adaptiveFilteredNetworkActivityProvider,
      filtersProvider: networkFiltersProvider,
      filterPanelExpandedProvider: filterPanelExpandedProvider,
      filterWidget: TransactionFilters(mode: FilterMode.network),
      itemBuilder: (transaction, keyID) => TransactionTile(
        key: Key("transaction$keyID"),
        keyID: keyID,
        avatarSize: scaleSize(40),
        transaction: transaction,
        context: context,
      ),
      refreshCallback: refreshNetworkActivity,
      loadMoreCallback: loadMoreNetworkTransactions,
      emptyStateIcon: Icons.history,
      emptyStateMessage: 'noNetworkActivity',
      getItems: (state) => state.transactions,
      getLatestTimestamp: (state) => state.transactions.isNotEmpty ? state.transactions.first.timestamp : null,
      getDateDelimiter: (transaction) => transaction.dateDelimiter,
      hasActiveFilters: (filters) => filters.hasActiveFilters,
      useRefreshIndicator: false,
      usePagination: true,
    );
  }
}
