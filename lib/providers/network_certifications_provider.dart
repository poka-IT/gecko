import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/base_paginated_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/providers/certification_filters_provider.dart';
import 'package:gecko/models/certification_filters.dart';

/// Notifier for managing network-wide certification activity
class NetworkCertificationsNotifier extends BasePaginatedNotifier<CertificationDisplayItem> {
  @override
  String get persistKey => 'networkCertifications_${ref.read(durtProvider).network.name}';

  @override
  String get itemsJsonKey => 'certifications';

  @override
  Map<String, dynamic> itemToJson(CertificationDisplayItem item) => item.toJson();

  @override
  CertificationDisplayItem itemFromJson(Map<String, dynamic> json) => CertificationDisplayItem.fromJson(json);

  @override
  Stream<String?>? createSubscription() => d.SquidService.client.subscribeNetworkCertifications();

  @override
  Future<PaginatedResult<CertificationDisplayItem>?> fetchPage({required int count, String? cursor}) async {
    final result = await d.SquidService.client.getNetworkCertifications(number: count, cursor: cursor);
    if (result == null) return null;

    final certificationResults = await Future.wait(
      result.edges.map((edge) => CertificationDisplayItem.fromNetworkCertificationNode(edge.node, ref)),
    );
    final items = certificationResults.whereType<CertificationDisplayItem>().toList();

    return PaginatedResult(
      items: items,
      hasNextPage: result.pageInfo.hasNextPage,
      endCursor: result.pageInfo.endCursor,
    );
  }
}

/// Server-side filtered network certifications notifier
class ServerFilteredNetworkCertificationsNotifier extends Notifier<PaginatedState<CertificationDisplayItem>> {
  Timer? _debounceTimer;
  bool _hasActiveFilters = false;
  d.CertificationFilters? _appliedServerFilters;

  @override
  PaginatedState<CertificationDisplayItem> build() {
    ref.onDispose(() => _debounceTimer?.cancel());

    // Listen to filter changes
    ref.listen(certificationFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // React to Squid connection changes: reload when connected
    ref.listen(squidConnectionStatusProvider, (previous, next) {
      if (previous != d.ConnectionStatus.connected && next == d.ConnectionStatus.connected) {
        log.i('Squid connected - loading filtered network certifications');
        _loadNetworkCertificationsWithFilters();
      }
    });

    // Initial load asynchronously
    Future.microtask(() => _loadNetworkCertificationsWithFilters());

    return const PaginatedState(isLoading: true);
  }

  /// Debounce filter updates to avoid excessive API calls
  void _debounceFilterUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadNetworkCertificationsWithFilters();
    });
  }

  /// Convert Gecko filters to Durt2 filters
  d.CertificationFilters _convertToServerFilters(CertificationFilterCriteria geckoFilters) {
    return d.CertificationFilters(
      issuerNameSearch: geckoFilters.issuerSearch,
      receiverNameSearch: geckoFilters.receiverSearch,
      startDate: geckoFilters.dateRange.startDate,
      endDate: geckoFilters.dateRange.endDate,
      isActive: geckoFilters.showActiveOnly,
      exactMatchIssuer: geckoFilters.exactMatchIssuer,
      exactMatchReceiver: geckoFilters.exactMatchReceiver,
    );
  }

  /// Load network certifications with current filters
  Future<void> _loadNetworkCertificationsWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.e('No network connection for filtered certifications');
      state = state.copyWith(error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(certificationFiltersProvider);
    _hasActiveFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts
    state = state.copyWith(isLoading: true, error: null, items: [], cursor: null);

    try {
      if (_hasActiveFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        _appliedServerFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getNetworkCertificationsFiltered(
          number: 20,
          cursor: null,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final itemResults = await Future.wait(
            result.items.map((node) => CertificationDisplayItem.fromFilteredNetworkCertificationNode(node, ref)),
          );
          final displayItems = itemResults.whereType<CertificationDisplayItem>().toList();

          state = state.copyWith(
            items: displayItems,
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        } else {
          state = state.copyWith(
            items: [],
            isLoading: false,
            hasNextPage: false,
            error: 'Failed to load filtered network certifications',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(networkCertificationsProvider);
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('Error loading filtered network certifications: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more network certifications (pagination)
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
      if (_hasActiveFilters && _appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getNetworkCertificationsFiltered(
          number: 20,
          cursor: state.cursor,
          filters: _appliedServerFilters!,
        );

        if (result != null) {
          final itemResults = await Future.wait(
            result.items.map((node) => CertificationDisplayItem.fromFilteredNetworkCertificationNode(node, ref)),
          );
          final newItems = itemResults.whereType<CertificationDisplayItem>().toList();

          state = state.copyWith(
            items: [...state.items, ...newItems],
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        }
      } else {
        // Load more without filters (delegate to existing provider)
        await ref.read(networkCertificationsProvider.notifier).loadMoreItems();
        final baseState = ref.read(networkCertificationsProvider);
        state = state.copyWith(
          items: baseState.items,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('Error loading more network certifications: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh network certifications
  Future<void> refresh() async {
    state = const PaginatedState();
    await _loadNetworkCertificationsWithFilters();
  }
}

/// Provider for network certifications
final networkCertificationsProvider =
    NotifierProvider<NetworkCertificationsNotifier, PaginatedState<CertificationDisplayItem>>(
      NetworkCertificationsNotifier.new,
    );

/// Provider for server-filtered network certifications
final serverFilteredNetworkCertificationsProvider =
    NotifierProvider<ServerFilteredNetworkCertificationsNotifier, PaginatedState<CertificationDisplayItem>>(
      ServerFilteredNetworkCertificationsNotifier.new,
    );

/// Adaptive network certifications provider that chooses between server and client filtering
final adaptiveFilteredNetworkCertificationsProvider = Provider<PaginatedState<CertificationDisplayItem>>((ref) {
  final filters = ref.watch(certificationFiltersProvider);

  if (filters.hasActiveFilters) {
    // Use server-side filtering for complex filters
    return ref.watch(serverFilteredNetworkCertificationsProvider);
  } else {
    // Use existing efficient client-side provider for no filters
    return ref.watch(networkCertificationsProvider);
  }
});

/// Load more network certifications (adaptive)
Future<void> loadMoreNetworkCertifications(WidgetRef ref) async {
  final filters = ref.read(certificationFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkCertificationsProvider.notifier).loadMore();
  } else {
    await ref.read(networkCertificationsProvider.notifier).loadMoreItems();
  }
}

/// Refresh network certifications (adaptive)
Future<void> refreshNetworkCertifications(WidgetRef ref) async {
  final filters = ref.read(certificationFiltersProvider);

  if (filters.hasActiveFilters) {
    await ref.read(serverFilteredNetworkCertificationsProvider.notifier).refresh();
  } else {
    await ref.read(networkCertificationsProvider.notifier).refresh();
  }
}
