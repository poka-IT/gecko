import 'dart:async';
import 'dart:convert';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/persist_storage_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/widgets/certs_list.dart';

/// State class for certification list
class CertificationListState {
  final List<CertDisplayItem> certifications;
  final bool isLoading;
  final bool hasError;
  final String? error;
  final String? lastActivityId;

  const CertificationListState({
    this.certifications = const [],
    this.isLoading = false,
    this.hasError = false,
    this.error,
    this.lastActivityId,
  });

  Map<String, dynamic> toJson() => {
    'certifications': certifications.map((c) => c.toJson()).toList(),
    'lastActivityId': lastActivityId,
  };

  factory CertificationListState.fromJson(Map<String, dynamic> json) => CertificationListState(
    certifications: (json['certifications'] as List)
        .map((c) => CertDisplayItem.fromJson(c as Map<String, dynamic>))
        .toList(),
    lastActivityId: json['lastActivityId'] as String?,
  );

  CertificationListState copyWith({
    required bool hasError,
    List<CertDisplayItem>? certifications,
    bool? isLoading,
    String? error,
    String? lastActivityId,
  }) {
    return CertificationListState(
      hasError: hasError,
      certifications: certifications ?? this.certifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastActivityId: lastActivityId ?? this.lastActivityId,
    );
  }
}

/// Notifier for managing certification lists
class CertificationListNotifier extends Notifier<CertificationListState> {
  CertificationListNotifier(this._params);
  final ({String address, CertDirection direction}) _params;

  StreamSubscription<String?>? _activitySubscription;

  @override
  CertificationListState build() {
    ref.onDispose(() => _activitySubscription?.cancel());

    // Persist state to local SQLite DB for instant display on app restart
    final network = ref.read(durtProvider).network.name;
    persist(
      ref.watch(persistStorageProvider.future),
      key: 'certList_${_params.address}_${_params.direction.name}_$network',
      encode: (state) => jsonEncode(state.toJson()),
      decode: (json) => CertificationListState.fromJson(jsonDecode(json) as Map<String, dynamic>),
    );

    // Start initial load asynchronously
    Future.microtask(() {
      loadCertifications();
      _subscribeToCertActivity();
    });

    // Start with isLoading: true to avoid flash of "no data" before loading starts
    return const CertificationListState(isLoading: true);
  }

  String get address => _params.address;
  CertDirection get direction => _params.direction;

  /// Subscribe to certification activity
  void _subscribeToCertActivity() {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot subscribe to cert activity: Squid not connected');
      return;
    }

    try {
      _activitySubscription = d.SquidService.client
          .subscribeCertActivity(address)
          .listen(
            (activityId) {
              if (activityId != null && activityId != state.lastActivityId) {
                log.d('🔔 New cert activity detected for $address: $activityId (previous: ${state.lastActivityId})');
                state = state.copyWith(hasError: false, lastActivityId: activityId);
                _onCertActivity();
              } else if (activityId != null) {
                log.d('Received known cert activity ID: $activityId');
              }
            },
            onError: (error) {
              log.e('Cert activity subscription error: $error');
            },
          );
    } catch (e) {
      log.e('Failed to setup cert activity subscription: $e');
    }
  }

  /// Handle certification activity by refreshing the list
  void _onCertActivity() async {
    try {
      // Don't refresh if we're already loading
      if (state.isLoading) {
        log.d('Skipping cert activity refresh: already loading');
        return;
      }

      await _refreshCertifications();
    } catch (e) {
      log.e('Error handling cert activity: $e');
    }
  }

  /// Load certifications from the server
  Future<void> loadCertifications() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      state = state.copyWith(hasError: true, error: 'No network connection');
      return;
    }

    state = state.copyWith(isLoading: true, hasError: false, error: null);

    try {
      final certs = await _fetchCertifications();

      state = state.copyWith(certifications: certs, isLoading: false, hasError: false);
    } catch (e) {
      log.e('Error loading certifications: $e');
      state = state.copyWith(isLoading: false, hasError: true, error: e.toString());
    }
  }

  /// Refresh certifications (used for activity-triggered updates)
  Future<void> _refreshCertifications() async {
    final squidConnectionStatus = ref.read(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      log.w('Cannot refresh: Squid not connected');
      return;
    }

    try {
      final newCerts = await _fetchCertifications();

      state = state.copyWith(certifications: newCerts, hasError: false);
    } catch (e) {
      log.e('Error refreshing certifications: $e');
      // Don't update error state if we have existing data
      if (state.certifications.isEmpty) {
        state = state.copyWith(hasError: true, error: e.toString());
      }
    }
  }

  /// Fetch certifications from the server
  Future<List<CertDisplayItem>> _fetchCertifications() async {
    List<CertDisplayItem> listCerts = [];

    try {
      // Get genesis time for block number conversion
      final genesisTime = await ref.read(genesisTimeProvider.future);
      if (genesisTime == null) {
        return []; // Storage not ready yet
      }

      if (direction == CertDirection.received) {
        final certConnection = await d.SquidService.client.getCertsReceived(address);
        if (certConnection == null) return [];

        for (final edge in certConnection.edges) {
          final cert = edge.node;
          if (!cert.isActive) continue;

          final String? personAddress = cert.issuer?.accountId;
          final String? personName = cert.issuer?.name;
          final String? timestampString = cert.updatedIn?.block?.timestamp;

          if (timestampString != null && personAddress != null) {
            // Parse the timestamp as UTC and convert to local time
            final timestamp = timestampString.parseBlockTimestamp();

            // Convert expiration block number to date
            final expireDate = d.Durt.i.storage.blocNumberToDate(cert.expireOn, genesisTime);

            if (!listCerts.any((existingCert) => existingCert.address == personAddress)) {
              listCerts.add(
                CertDisplayItem(
                  address: personAddress,
                  name: personName ?? '',
                  date: timestamp,
                  expireDate: expireDate,
                ),
              );
            }
          }
        }
      } else {
        final certConnection = await d.SquidService.client.getCertsSent(address);
        if (certConnection == null) return [];

        for (final edge in certConnection.edges) {
          final cert = edge.node;
          if (!cert.isActive) continue;

          final String? personAddress = cert.receiver?.accountId;
          final String? personName = cert.receiver?.name;
          final String? timestampString = cert.updatedIn?.block?.timestamp;

          if (personAddress != null && timestampString != null) {
            // Parse the timestamp as UTC and convert to local time
            final timestamp = timestampString.parseBlockTimestamp();

            // Convert expiration block number to date
            final expireDate = d.Durt.i.storage.blocNumberToDate(cert.expireOn, genesisTime);

            if (!listCerts.any((existingCert) => existingCert.address == personAddress)) {
              listCerts.add(
                CertDisplayItem(
                  address: personAddress,
                  name: personName ?? '',
                  date: timestamp,
                  expireDate: expireDate,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      log.e('Error fetching certifications: $e');
    }

    return listCerts;
  }

  /// Public method for manual refresh
  Future<void> refresh() async {
    state = CertificationListState(lastActivityId: state.lastActivityId);
    await loadCertifications();
  }
}

/// Provider for certification lists
final certificationListProvider =
    NotifierProvider.family<
      CertificationListNotifier,
      CertificationListState,
      ({String address, CertDirection direction})
    >((params) => CertificationListNotifier(params));
