import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/providers/certification_filters_provider.dart';
import 'package:gecko/models/certification_filters.dart';

/// State for network certification activity
class NetworkCertificationsState {
  final List<CertificationDisplayItem> certifications;
  final bool isLoading;
  final bool hasNextPage;
  final String? cursor;
  final String? error;
  final bool hasActiveFilters;
  final d.CertificationFilters? appliedServerFilters;

  const NetworkCertificationsState({
    this.certifications = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.cursor,
    this.error,
    this.hasActiveFilters = false,
    this.appliedServerFilters,
  });

  NetworkCertificationsState copyWith({
    List<CertificationDisplayItem>? certifications,
    bool? isLoading,
    bool? hasNextPage,
    String? cursor,
    String? error,
    bool? hasActiveFilters,
    d.CertificationFilters? appliedServerFilters,
  }) {
    return NetworkCertificationsState(
      certifications: certifications ?? this.certifications,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
      appliedServerFilters: appliedServerFilters ?? this.appliedServerFilters,
    );
  }
}

/// Notifier for managing network-wide certification activity
class NetworkCertificationsNotifier extends Notifier<NetworkCertificationsState> {
  StreamSubscription<String?>? _networkCertificationsSubscription;
  String? _lastSeenCertificationId;

  @override
  NetworkCertificationsState build() {
    ref.onDispose(() => _networkCertificationsSubscription?.cancel());

    // Start initial load asynchronously
    Future.microtask(() {
      loadCertifications();
      _subscribeToNetworkCertifications();
    });

    // Start with isLoading: true to avoid flash of "no data" before loading starts
    return const NetworkCertificationsState(isLoading: true);
  }

  /// Subscribe to network-wide certification activity (triggers refreshes when new certifications are issued)
  void _subscribeToNetworkCertifications() {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe to network certifications: Squid not connected');
      return;
    }

    try {
      _networkCertificationsSubscription = d.SquidService.client.subscribeNetworkCertifications().listen(
        (certificationId) {
          if (certificationId != null && certificationId != _lastSeenCertificationId) {
            _lastSeenCertificationId = certificationId;
            _onNetworkCertificationActivity();
          } else if (certificationId != null) {
            log.d('Received known certification ID: $certificationId');
          }
        },
        onError: (error) {
          log.e('Network certification subscription error: $error');
        },
      );
    } catch (e) {
      log.e('Failed to setup network certification subscription: $e');
    }
  }

  /// Handle network certification activity by refreshing the certification history
  void _onNetworkCertificationActivity() async {
    try {
      // Don't refresh if we're already loading
      if (state.isLoading) {
        log.d('Skipping network certification refresh: already loading');
        return;
      }

      // Refresh the complete certification history
      await _refreshNetworkCertifications();
    } catch (e) {
      log.e('Error handling network certification activity: $e');
    }
  }

  /// Refresh network certifications (used for activity-triggered updates)
  Future<void> _refreshNetworkCertifications() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot refresh: Squid not connected');
      return;
    }

    try {
      // Fetch fresh network-wide certifications
      final result = await d.SquidService.client.getNetworkCertifications(number: 20, cursor: null);

      if (result != null) {
        final certificationResults = await Future.wait(
          result.edges.map((edge) => CertificationDisplayItem.fromNetworkCertificationNode(edge.node, ref)),
        );
        final newCertifications = certificationResults.whereType<CertificationDisplayItem>().toList();

        // Check if we actually have new certifications by comparing with current state
        final hasNewCertifications =
            newCertifications.isNotEmpty &&
            (state.certifications.isEmpty ||
                (newCertifications.first.timestamp.isAfter(state.certifications.first.timestamp)));

        if (hasNewCertifications) {
          log.i('Found ${newCertifications.length} new network certifications');
        }

        state = state.copyWith(
          certifications: newCertifications,
          hasNextPage: result.pageInfo.hasNextPage,
          cursor: result.pageInfo.endCursor,
        );

        // Update last seen certification ID with the most recent one
        if (newCertifications.isNotEmpty) {
          _lastSeenCertificationId = _generateCertificationId(newCertifications.first);
        }
      } else {
        log.w('Received null result from getNetworkCertifications');
      }
    } catch (e) {
      log.e('Error refreshing network certifications: $e');
    }
  }

  /// Generate a consistent certification ID from certification data
  String _generateCertificationId(CertificationDisplayItem certification) {
    return '${certification.id}_${certification.timestamp.millisecondsSinceEpoch}_${certification.isActive}';
  }

  /// Load the first page of network certifications
  Future<void> loadCertifications() async {
    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch network-wide certifications
      final result = await d.SquidService.client.getNetworkCertifications(number: 20, cursor: null);

      if (result == null) {
        state = state.copyWith(certifications: [], isLoading: false, hasNextPage: false, cursor: null);
        return;
      }

      final certificationResults = await Future.wait(
        result.edges.map((edge) => CertificationDisplayItem.fromNetworkCertificationNode(edge.node, ref)),
      );
      final certifications = certificationResults.whereType<CertificationDisplayItem>().toList();

      state = state.copyWith(
        certifications: certifications,
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );

      // Store the most recent certification ID for activity detection
      if (certifications.isNotEmpty) {
        _lastSeenCertificationId = _generateCertificationId(certifications.first);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the next page of network certifications
  Future<void> loadMoreCertifications() async {
    if (state.isLoading || !state.hasNextPage) return;

    // Check if we have Squid connection
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Fetch more network certifications using cursor pagination
      final result = await d.SquidService.client.getNetworkCertifications(number: 20, cursor: state.cursor);

      if (result == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final certificationResults = await Future.wait(
        result.edges.map((edge) => CertificationDisplayItem.fromNetworkCertificationNode(edge.node, ref)),
      );
      final newCertifications = certificationResults.whereType<CertificationDisplayItem>().toList();

      state = state.copyWith(
        certifications: [...state.certifications, ...newCertifications],
        isLoading: false,
        hasNextPage: result.pageInfo.hasNextPage,
        cursor: result.pageInfo.endCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh the network certifications (public method for manual refresh)
  Future<void> refresh() async {
    state = const NetworkCertificationsState();
    await loadCertifications();
  }
}

/// Server-side filtered network certifications notifier
class ServerFilteredNetworkCertificationsNotifier extends Notifier<NetworkCertificationsState> {
  Timer? _debounceTimer;

  @override
  NetworkCertificationsState build() {
    ref.onDispose(() => _debounceTimer?.cancel());

    // Listen to filter changes
    ref.listen(certificationFiltersProvider, (previous, next) {
      if (previous != next) {
        _debounceFilterUpdate();
      }
    });

    // Initial load asynchronously
    Future.microtask(() => _loadNetworkCertificationsWithFilters());

    // Start with isLoading: true to avoid flash of "no data" before loading starts
    return const NetworkCertificationsState(isLoading: true);
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
    final serverFilters = d.CertificationFilters(
      issuerNameSearch: geckoFilters.issuerSearch,
      receiverNameSearch: geckoFilters.receiverSearch,
      startDate: geckoFilters.dateRange.startDate,
      endDate: geckoFilters.dateRange.endDate,
      isActive: geckoFilters.showActiveOnly,
      exactMatchIssuer: geckoFilters.exactMatchIssuer,
      exactMatchReceiver: geckoFilters.exactMatchReceiver,
    );

    return serverFilters;
  }

  /// Load network certifications with current filters
  Future<void> _loadNetworkCertificationsWithFilters() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.e('❌ [CERTIFICATION DEBUG] No network connection');
      state = state.copyWith(error: 'No network connection');
      return;
    }

    final geckoFilters = ref.read(certificationFiltersProvider);
    final hasFilters = geckoFilters.hasActiveFilters;

    // Reset state when switching filter modes to avoid cursor conflicts
    state = state.copyWith(
      isLoading: true,
      error: null,
      hasActiveFilters: hasFilters,
      certifications: [], // Clear existing certifications when filters change
      cursor: null, // Reset cursor to avoid conflicts
    );

    try {
      if (hasFilters) {
        // Use server-side filtering via Durt2 (always start fresh, no cursor)
        final serverFilters = _convertToServerFilters(geckoFilters);
        final result = await d.SquidService.client.getNetworkCertificationsFiltered(
          number: 20,
          cursor: null, // Always start fresh to avoid cursor conflicts
          filters: serverFilters,
        );

        if (result != null) {
          final itemResults = await Future.wait(
            result.items.map((node) => CertificationDisplayItem.fromFilteredNetworkCertificationNode(node, ref)),
          );
          final displayItems = itemResults.whereType<CertificationDisplayItem>().toList();

          state = state.copyWith(
            certifications: displayItems,
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
            appliedServerFilters: serverFilters,
          );
        } else {
          state = state.copyWith(
            certifications: [],
            isLoading: false,
            hasNextPage: false,
            error: 'Failed to load filtered network certifications',
          );
        }
      } else {
        // No filters: use standard efficient approach
        final baseState = ref.read(networkCertificationsProvider);
        state = state.copyWith(
          certifications: baseState.certifications,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
          appliedServerFilters: null, // No server filters applied
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
      if (state.hasActiveFilters && state.appliedServerFilters != null) {
        // Load more with server filters (use only server-generated cursors)
        final result = await d.SquidService.client.getNetworkCertificationsFiltered(
          number: 20,
          cursor: state.cursor, // Use the cursor from server filtering results
          filters: state.appliedServerFilters!,
        );

        if (result != null) {
          final itemResults = await Future.wait(
            result.items.map((node) => CertificationDisplayItem.fromFilteredNetworkCertificationNode(node, ref)),
          );
          final newItems = itemResults.whereType<CertificationDisplayItem>().toList();

          state = state.copyWith(
            certifications: [...state.certifications, ...newItems],
            isLoading: false,
            hasNextPage: result.hasNextPage,
            cursor: result.endCursor,
          );
        }
      } else {
        // Load more without filters (delegate to existing provider)
        await ref.read(networkCertificationsProvider.notifier).loadMoreCertifications();
        final baseState = ref.read(networkCertificationsProvider);
        state = state.copyWith(
          certifications: baseState.certifications,
          isLoading: false,
          hasNextPage: baseState.hasNextPage,
          cursor: baseState.cursor,
        );
      }
    } catch (e) {
      log.e('❌ Error loading more network certifications: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh network certifications
  Future<void> refresh() async {
    state = const NetworkCertificationsState();
    await _loadNetworkCertificationsWithFilters();
  }
}

/// Provider for network certifications
final networkCertificationsProvider = NotifierProvider<NetworkCertificationsNotifier, NetworkCertificationsState>(
  NetworkCertificationsNotifier.new,
);

/// Provider for server-filtered network certifications
final serverFilteredNetworkCertificationsProvider =
    NotifierProvider<ServerFilteredNetworkCertificationsNotifier, NetworkCertificationsState>(
      ServerFilteredNetworkCertificationsNotifier.new,
    );

/// Adaptive network certifications provider that chooses between server and client filtering
final adaptiveFilteredNetworkCertificationsProvider = Provider<NetworkCertificationsState>((ref) {
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
    await ref.read(networkCertificationsProvider.notifier).loadMoreCertifications();
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
