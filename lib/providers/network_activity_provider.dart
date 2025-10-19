// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/squid_cache_buster.dart';

/// State for network activity history
class NetworkActivityState {
  final List<TransactionDisplayItem> transactions;
  final bool isLoading;
  final bool hasNextPage;
  final String? cursor;
  final String? error;
  final bool hasActiveFilters;
  final d.TransactionFilters? appliedServerFilters;

  const NetworkActivityState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.cursor,
    this.error,
    this.hasActiveFilters = false,
    this.appliedServerFilters,
  });

  NetworkActivityState copyWith({
    List<TransactionDisplayItem>? transactions,
    bool? isLoading,
    bool? hasNextPage,
    String? cursor,
    String? error,
    bool? hasActiveFilters,
    d.TransactionFilters? appliedServerFilters,
  }) {
    return NetworkActivityState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
      appliedServerFilters: appliedServerFilters ?? this.appliedServerFilters,
    );
  }
}

/// StateNotifier for managing network-wide transaction history with UD support
class NetworkActivityNotifier extends StateNotifier<NetworkActivityState> {
  final Ref ref;
  StreamSubscription<String?>? _networkActivitySubscription;
  String? _lastSeenTransactionId;

  NetworkActivityNotifier(this.ref) : super(const NetworkActivityState()) {
    // Watch the cache buster to force refresh when Squid endpoint changes
    ref.listen(squidCacheBusterProvider, (previous, next) {
      log.i('🔥 Cache buster changed ($previous → $next) - reloading network activity');
      loadTransactions();
    });

    loadTransactions();
    _subscribeToNetworkActivity();
  }

  /// Subscribe to network-wide activity (triggers refreshes when new transactions occur)
  void _subscribeToNetworkActivity() {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe to network activity: Squid not connected');
      return;
    }

    try {
      _networkActivitySubscription = d.SquidService.client.subscribeNetworkActivity().listen(
        (transactionId) {
          if (transactionId != null && transactionId != _lastSeenTransactionId) {
            print('New network activity detected: $transactionId (previous: $_lastSeenTransactionId)');
            _lastSeenTransactionId = transactionId;
            _onNetworkActivity();
          } else if (transactionId != null) {
            log.d('Received known transaction ID: $transactionId');
          }
        },
        onError: (error) {
          log.e('Network activity subscription error: $error');
        },
      );
    } catch (e) {
      log.e('Failed to setup network activity subscription: $e');
    }
  }

  /// Handle network activity by refreshing the transaction history
  void _onNetworkActivity() async {
    try {
      // Don't refresh if we're already loading
      if (state.isLoading) {
        log.d('Skipping network activity refresh: already loading');
        return;
      }

      // Refresh the complete transaction history
      await _refreshNetworkActivity();
    } catch (e) {
      log.e('Error handling network activity: $e');
    }
  }

  /// Refresh network activity (used for activity-triggered updates)
  Future<void> _refreshNetworkActivity() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot refresh: Squid not connected');
      return;
    }

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      // Fetch fresh network-wide transactions
      final result = await d.SquidService.client.getNetworkActivity(number: 20, cursor: null);

      if (result != null) {
        final newTransactions = result.edges
            .map((edge) => TransactionDisplayItem.fromNetworkActivityNode(edge.node, genesisTime))
            .toList();

        // Check if we actually have new transactions by comparing with current state
        final hasNewTransactions =
            newTransactions.isNotEmpty &&
            (state.transactions.isEmpty ||
                (newTransactions.first.timestamp.isAfter(state.transactions.first.timestamp)));

        if (hasNewTransactions) {
          log.i('Found ${newTransactions.length} new network transactions');
        }

        state = state.copyWith(
          transactions: newTransactions,
          hasNextPage: result.pageInfo.hasNextPage,
          cursor: result.pageInfo.endCursor,
        );

        // Update last seen transaction ID with the most recent one
        if (newTransactions.isNotEmpty) {
          _lastSeenTransactionId = _generateTransactionId(newTransactions.first);
        }
      } else {
        log.w('Received null result from getNetworkActivity');
      }
    } catch (e) {
      log.e('Error refreshing network activity: $e');
    }
  }

  /// Generate a consistent transaction ID from transaction data
  String _generateTransactionId(TransactionDisplayItem transaction) {
    return '${transaction.timestamp.millisecondsSinceEpoch}_${transaction.amount}_${transaction.isReceived}_${transaction.type.name}';
  }

  /// Load the first page of network transactions
  Future<void> loadTransactions() async {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);
      final includeUDs = ref.read(networkUniversalDividendsToggleProvider);

      List<TransactionDisplayItem> allTransactions = [];

      // Fetch network-wide transfers
      final transferResult = await d.SquidService.client.getNetworkActivity(number: 20, cursor: null);

      if (transferResult != null) {
        final transferTransactions = transferResult.edges
            .map((edge) => TransactionDisplayItem.fromNetworkActivityNode(edge.node, genesisTime))
            .toList();
        allTransactions.addAll(transferTransactions);
      }

      // Fetch Universal Dividends if enabled (network-wide)
      if (includeUDs) {
        // Note: This would require a new GraphQL query for network-wide UDs
        // For now, we'll add a placeholder for future implementation
        final networkUDs = await _fetchNetworkUniversalDividends(genesisTime);
        allTransactions.addAll(networkUDs);
      }

      // Sort all transactions by timestamp (newest first)
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (transferResult == null) {
        print('🔴 Network activity result is null');
        state = state.copyWith(transactions: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      state = state.copyWith(
        transactions: allTransactions,
        isLoading: false,
        hasNextPage: transferResult.pageInfo.hasNextPage,
        cursor: transferResult.pageInfo.endCursor,
      );

      // Store the most recent transaction ID for activity detection
      if (allTransactions.isNotEmpty) {
        _lastSeenTransactionId = _generateTransactionId(allTransactions.first);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fetch network-wide Universal Dividends
  Future<List<TransactionDisplayItem>> _fetchNetworkUniversalDividends(DateTime genesisTime) async {
    try {
      final result = await d.SquidService.client.getNetworkUdHistory(number: 20);

      if (result == null) {
        return [];
      }

      return result.edges.map((edge) {
        final node = edge.node;
        final timestamp = DateTime.parse(
          node.timestamp.endsWith('Z') || node.timestamp.contains('+') || node.timestamp.contains('-')
              ? node.timestamp
              : '${node.timestamp}Z',
        );

        return TransactionDisplayItem(
          address: '', // Network view, no specific address
          amount: BigInt.parse(node.amount),
          timestamp: timestamp,
          transactionTime: timestamp,
          dateDelimiter: '',
          isMigrationTime: false,
          comment: null,
          isReceived: false, // Network view, not account-specific
          type: TransactionType.universalDividend,
          fromAddress: '', // UDs don't have a from address
          toAddress: '', // UDs don't have a specific recipient in network view
          fromUsername: null,
          toUsername: null,
        );
      }).toList();
    } catch (e) {
      log.e('Failed to fetch network UDs: $e');
      return [];
    }
  }

  /// Load the next page of network transactions
  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasNextPage) return;

    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);
      final includeUDs = ref.read(networkUniversalDividendsToggleProvider);

      // Fetch more network transactions using cursor pagination
      final result = await d.SquidService.client.getNetworkActivity(number: 20, cursor: state.cursor);

      if (result == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final newTransferTransactions = result.edges
          .map((edge) => TransactionDisplayItem.fromNetworkActivityNode(edge.node, genesisTime))
          .toList();

      List<TransactionDisplayItem> allNewTransactions = [...newTransferTransactions];

      // Add UDs if enabled (for pagination, this is more complex as we'd need cursor-based UD pagination)
      if (includeUDs) {
        // For now, we don't paginate UDs in network view
        // In a full implementation, this would need proper pagination coordination
      }

      // Sort new transactions by timestamp
      allNewTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      state = state.copyWith(
        transactions: [...state.transactions, ...allNewTransactions],
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh the network activity (public method for manual refresh)
  Future<void> refresh() async {
    state = const NetworkActivityState();
    await loadTransactions();
  }

  @override
  void dispose() {
    _networkActivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for network activity
final networkActivityProvider = StateNotifierProvider<NetworkActivityNotifier, NetworkActivityState>((ref) {
  return NetworkActivityNotifier(ref);
});

/// Provider for Universal Dividends toggle in network view
final networkUniversalDividendsToggleProvider = StateNotifierProvider<UniversalDividendsToggleNotifier, bool>((ref) {
  return UniversalDividendsToggleNotifier();
});

/// Server-side filtered network activity notifier
class ServerFilteredNetworkActivityNotifier extends StateNotifier<NetworkActivityState> {
  final Ref ref;
  Timer? _debounceTimer;

  ServerFilteredNetworkActivityNotifier(this.ref) : super(const NetworkActivityState()) {
    // Listen to filter changes
    ref.listen(networkFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // Initial load
    _loadNetworkActivityWithFilters();
  }

  /// Debounce filter updates to avoid excessive API calls
  void _debounceFilterUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadNetworkActivityWithFilters();
    });
  }

  /// Convert Gecko filters to Durt2 filters
  d.TransactionFilters _convertToServerFilters(TransactionFilterCriteria geckoFilters) {
    final serverFilters = d.TransactionFilters(
      fromAddress: geckoFilters.directionFilter?.fromAddress,
      toAddress: geckoFilters.directionFilter?.toAddress,
      commentSearch: geckoFilters.commentSearch,
      startDate: geckoFilters.dateRange.startDate,
      endDate: geckoFilters.dateRange.endDate,
      minAmount: geckoFilters.amountRange.minAmount,
      maxAmount: geckoFilters.amountRange.maxAmount,
      exactMatchAddress: geckoFilters.exactMatchAddress,
      exactMatchComment: geckoFilters.exactMatchComment,
      exactMatchDirection: geckoFilters.exactMatchDirection,
    );

    return serverFilters;
  }

  /// Load network activity with current filters
  Future<void> _loadNetworkActivityWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      print('❌ [NETWORK DEBUG] No network connection');
      state = state.copyWith(error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(networkFiltersProvider);
    final hasFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts (like account history does)
    state = state.copyWith(
      isLoading: true,
      error: null,
      hasActiveFilters: hasFilters,
      transactions: [], // Clear existing transactions when filters change
      cursor: null, // Reset cursor to avoid conflicts
    );

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      if (hasFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        final serverFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getNetworkActivityFiltered(
          number: 20,
          cursor: null, // Always start fresh to avoid cursor conflicts
          filters: serverFilters,
        );

        if (result != null) {
          final displayItems = result.items
              .map((node) => TransactionDisplayItem.fromNetworkActivityNode(node, genesisTime))
              .toList();

          state = state.copyWith(
            transactions: displayItems,
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
            appliedServerFilters: serverFilters,
          );
        } else {
          state = state.copyWith(
            transactions: [],
            isLoading: false,
            hasNextPage: false,
            error: 'Failed to load filtered network activity',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(networkActivityProvider);
        state = state.copyWith(
          transactions: baseState.transactions,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
          appliedServerFilters: null, // No server filters applied
        );
      }
    } catch (e) {
      log.e('Error loading filtered network activity: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more network activity (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasNextPage) {
      return;
    }

    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final genesisTime = await ref.read(genesisTimeProvider.future);

      if (state.hasActiveFilters && state.appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getNetworkActivityFiltered(
          number: 20,
          cursor: state.cursor, // Use the cursor from server filtering results
          filters: state.appliedServerFilters!,
        );

        if (result != null) {
          final newItems = result.items
              .map((node) => TransactionDisplayItem.fromNetworkActivityNode(node, genesisTime))
              .toList();

          state = state.copyWith(
            transactions: [...state.transactions, ...newItems],
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        }
      } else {
        // Load more without filters (delegate to existing provider)
        await ref.read(networkActivityProvider.notifier).loadMoreTransactions();
        final baseState = ref.read(networkActivityProvider);
        state = state.copyWith(
          transactions: baseState.transactions,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      print('❌ [NETWORK DEBUG] Error in loadMore: $e');
      log.e('Error loading more network activity: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh network activity
  Future<void> refresh() async {
    state = const NetworkActivityState();
    await _loadNetworkActivityWithFilters();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for server-filtered network activity
final serverFilteredNetworkActivityProvider =
    StateNotifierProvider<ServerFilteredNetworkActivityNotifier, NetworkActivityState>((ref) {
      return ServerFilteredNetworkActivityNotifier(ref);
    });

/// Adaptive network activity provider that chooses between server and client filtering
final adaptiveFilteredNetworkActivityProvider = Provider<NetworkActivityState>((ref) {
  final filters = ref.watch(networkFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering for complex filters
    return ref.watch(serverFilteredNetworkActivityProvider);
  } else {
    // Use existing efficient client-side provider for no filters
    return ref.watch(networkActivityProvider);
  }
});

/// Load more network transactions (adaptive)
Future<void> loadMoreNetworkTransactions(WidgetRef ref) async {
  final filters = ref.read(networkFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkActivityProvider.notifier).loadMore();
  } else {
    await ref.read(networkActivityProvider.notifier).loadMoreTransactions();
  }
}

/// Refresh network activity (adaptive)
Future<void> refreshNetworkActivity(WidgetRef ref) async {
  final filters = ref.read(networkFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkActivityProvider.notifier).refresh();
  } else {
    await ref.read(networkActivityProvider.notifier).refresh();
  }
}
