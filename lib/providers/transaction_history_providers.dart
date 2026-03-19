import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/base_paginated_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/server_filtered_history_provider.dart';
import 'package:gecko/extensions.dart';

/// Notifier for managing transfers-only transaction history
class TransfersOnlyHistoryNotifier extends BasePaginatedNotifier<TransactionDisplayItem> {
  TransfersOnlyHistoryNotifier(this._address);
  final String _address;

  String get address => _address;

  @override
  String get persistKey => 'transfers_${_address}_${ref.read(durtProvider).network.name}';

  @override
  String get itemsJsonKey => 'transactions';

  @override
  bool get watchCacheBuster => true;

  @override
  bool get markLoadingOnDecode => true;

  @override
  Map<String, dynamic> itemToJson(TransactionDisplayItem item) => item.toJson();

  @override
  TransactionDisplayItem itemFromJson(Map<String, dynamic> json) => TransactionDisplayItem.fromJson(json);

  @override
  Stream<String?>? createSubscription() => d.SquidService.client.subscribeAccountActivity(_address);

  @override
  Future<PaginatedResult<TransactionDisplayItem>?> fetchPage({required int count, String? cursor}) async {
    final genesisTime = await ref.read(genesisTimeProvider.future);
    if (genesisTime == null) return null;

    final result = await d.SquidService.client.getAccountHistory(_address, number: count, cursor: cursor);
    if (result == null) return null;

    final items = result.edges
        .map((edge) => TransactionDisplayItem.fromGraphQLNode(edge.node, _address, genesisTime))
        .toList();

    return PaginatedResult(
      items: items,
      hasNextPage: result.pageInfo.hasNextPage,
      endCursor: result.pageInfo.endCursor,
    );
  }
}

/// Notifier for managing combined transaction history (transfers + UDs)
class CombinedHistoryNotifier extends BasePaginatedNotifier<TransactionDisplayItem> {
  CombinedHistoryNotifier(this._address);
  final String _address;

  String get address => _address;

  @override
  String get persistKey => 'combined_${_address}_${ref.read(durtProvider).network.name}';

  @override
  String get itemsJsonKey => 'transactions';

  @override
  bool get watchCacheBuster => true;

  @override
  bool get markLoadingOnDecode => true;

  @override
  Map<String, dynamic> itemToJson(TransactionDisplayItem item) => item.toJson();

  @override
  TransactionDisplayItem itemFromJson(Map<String, dynamic> json) => TransactionDisplayItem.fromJson(json);

  @override
  Stream<String?>? createSubscription() => d.SquidService.client.subscribeAccountActivity(_address);

  @override
  Future<PaginatedResult<TransactionDisplayItem>?> fetchPage({required int count, String? cursor}) async {
    final genesisTime = await ref.read(genesisTimeProvider.future);
    if (genesisTime == null) return null;

    // For loadMore with cursor, convert timestamp string to DateTime for pagination
    DateTime? beforeTimestamp;
    if (cursor != null) {
      try {
        beforeTimestamp = DateTime.parse(cursor.ensureUtcTimestamp());
      } catch (e) {
        log.e('Error parsing cursor timestamp: $cursor');
      }
    }

    // Fetch both transfers and UDs combined
    final result = await d.SquidService.client.getCombinedAccountHistory(
      _address,
      number: count,
      cursor: null,
      includeUniversalDividends: true,
      beforeTimestamp: beforeTimestamp,
    );

    if (result == null) return null;

    final items = result.items
        .map((item) {
          if (item is d.Query$GetAccountHistory$transfers$edges$node) {
            return TransactionDisplayItem.fromGraphQLNode(item, _address, genesisTime);
          } else if (item is d.Query$GetUdHistoryViaIdentity$identities$edges$node$udHistory$edges$node) {
            return TransactionDisplayItem.fromUdHistoryNode(item, _address, genesisTime);
          } else {
            log.e('Unknown item type in combined history: ${item.runtimeType}');
            return null;
          }
        })
        .whereType<TransactionDisplayItem>()
        .toList();

    return PaginatedResult(items: items, hasNextPage: result.hasNextPage, endCursor: result.endCursor);
  }
}

/// Provider for transfers-only transaction history
final transfersOnlyHistoryProvider =
    NotifierProvider.family<TransfersOnlyHistoryNotifier, PaginatedState<TransactionDisplayItem>, String>(
      (address) => TransfersOnlyHistoryNotifier(address),
    );

/// Provider for combined transaction history (transfers + UDs)
final combinedHistoryProvider =
    NotifierProvider.family<CombinedHistoryNotifier, PaginatedState<TransactionDisplayItem>, String>(
      (address) => CombinedHistoryNotifier(address),
    );

/// Conditional provider that switches between transfers-only and combined history based on toggle
final transactionHistoryProvider = Provider.family<PaginatedState<TransactionDisplayItem>, String>((ref, address) {
  final includeUD = ref.watch(universalDividendsToggleProvider);

  if (includeUD) {
    return ref.watch(combinedHistoryProvider(address));
  } else {
    return ref.watch(transfersOnlyHistoryProvider(address));
  }
});

/// Toggle universal dividends and switch providers accordingly
void toggleUniversalDividends(WidgetRef ref, String address) {
  ref.read(universalDividendsToggleProvider.notifier).toggle();
  // The conditional provider will automatically switch between providers

  // Trigger scroll to top
  ref.read(scrollToTopProvider.notifier).triggerScrollToTop();
}

/// Refresh transaction history (adaptive - uses server filtering when filters are active)
Future<void> refreshTransactionHistory(WidgetRef ref, String address) async {
  final filters = ref.read(transactionFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering refresh
    await ref.read(serverFilteredHistoryProvider(address).notifier).refresh();
  } else {
    // Use standard approach based on UD toggle
    final includeUD = ref.read(universalDividendsToggleProvider);
    if (includeUD) {
      await ref.read(combinedHistoryProvider(address).notifier).refresh();
    } else {
      await ref.read(transfersOnlyHistoryProvider(address).notifier).refresh();
    }
  }
}

/// Load more transactions (adaptive - uses server filtering when filters are active)
Future<void> loadMoreTransactions(WidgetRef ref, String address) async {
  final filters = ref.read(transactionFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering load more
    await ref.read(serverFilteredHistoryProvider(address).notifier).loadMore();
  } else {
    // Use standard approach based on UD toggle
    final includeUD = ref.read(universalDividendsToggleProvider);
    if (includeUD) {
      await ref.read(combinedHistoryProvider(address).notifier).loadMoreItems();
    } else {
      await ref.read(transfersOnlyHistoryProvider(address).notifier).loadMoreItems();
    }
  }
}

/// Simple notifier to trigger scroll to top events
class ScrollToTopNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void triggerScrollToTop() {
    state = state + 1; // Increment to trigger watchers
  }
}

/// Provider for scroll to top events
final scrollToTopProvider = NotifierProvider<ScrollToTopNotifier, int>(ScrollToTopNotifier.new);

/// Enhanced transaction history provider with adaptive server-side filtering
final filteredTransactionHistoryProvider = Provider.family<PaginatedState<TransactionDisplayItem>, String>((
  ref,
  address,
) {
  final filters = ref.watch(transactionFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use the new server-side filtering for better performance and completeness
    return ref.watch(serverFilteredHistoryProvider(address));
  } else {
    // No filters: use existing efficient approach
    return ref.watch(transactionHistoryProvider(address));
  }
});
