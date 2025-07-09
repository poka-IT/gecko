import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/widgets/certs_list.dart';

/// State class for certification list
class CertificationListState {
  final List<CertDisplayItem> certifications;
  final bool isLoading;
  final bool hasError;
  final String? error;

  const CertificationListState({
    this.certifications = const [],
    this.isLoading = false,
    this.hasError = false,
    this.error,
  });

  CertificationListState copyWith({
    List<CertDisplayItem>? certifications,
    bool? isLoading,
    bool? hasError,
    String? error,
  }) {
    return CertificationListState(
      certifications: certifications ?? this.certifications,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier for managing certification lists
class CertificationListNotifier extends StateNotifier<CertificationListState> {
  final Ref ref;
  final String address;
  final CertDirection direction;
  StreamSubscription<String?>? _activitySubscription;
  String? _lastSeenCertId;
  DateTime? _lastCertTimestamp;

  CertificationListNotifier(this.ref, this.address, this.direction) : super(const CertificationListState()) {
    loadCertifications();
    _subscribeToCertActivity();
  }

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
            (certId) {
              if (certId != null && certId != _lastSeenCertId) {
                log.i('New cert activity detected for $address: $certId (previous: $_lastSeenCertId)');
                _lastSeenCertId = certId;
                _onCertActivity();
              } else if (certId != null) {
                log.d('Received known cert ID: $certId');
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

      // Store the most recent certification timestamp for activity detection
      if (certs.isNotEmpty) {
        _lastSeenCertId = certs.first.address + certs.first.date.toString();
        // Extract timestamp from first certification
        _lastCertTimestamp = certs.first.date;
      }

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

      // Check if we actually have new certifications by comparing timestamps
      bool hasNewCerts = false;
      if (newCerts.isNotEmpty) {
        if (state.certifications.isEmpty) {
          hasNewCerts = true;
        } else {
          // Compare with the last known timestamp
          hasNewCerts =
              _lastCertTimestamp == null ||
              newCerts.first.date.isAfter(_lastCertTimestamp!) ||
              !state.certifications.any(
                (cert) => cert.address == newCerts.first.address && cert.date == newCerts.first.date,
              );

          if (hasNewCerts) {
            _lastCertTimestamp = newCerts.first.date;
          }
        }
      }

      if (hasNewCerts) {
        log.i('Found ${newCerts.length} certifications, with newer ones than before');
      }
      state = state.copyWith(certifications: newCerts, hasError: false);

      // Update last seen certification ID with the most recent one
      if (newCerts.isNotEmpty) {
        _lastSeenCertId = newCerts.first.address + newCerts.first.date.toString();
      }
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

    if (direction == CertDirection.received) {
      final certConnection = await d.SquidService.client.getCertsReceived(address);
      if (certConnection == null) return [];

      for (final edge in certConnection.edges) {
        final cert = edge.node;
        if (!cert.isActive) continue;

        final String? personAddress = cert.issuer?.accountId;
        final String? personName = cert.issuer?.name;
        final String? timestampString = cert.updatedIn?.block?.timestamp;

        if (timestampString != null) {
          // Parse the timestamp as UTC and convert to local time
          final timestamp =
              timestampString.endsWith('Z') || timestampString.contains('+') || timestampString.contains('-')
              ? DateTime.parse(timestampString)
                    .toLocal() // Already has timezone info
              : DateTime.parse('${timestampString}Z').toLocal(); // Assume UTC if no timezone info

          if (!listCerts.any((existingCert) => existingCert.address == personAddress)) {
            listCerts.add(CertDisplayItem(address: personAddress ?? '', name: personName ?? '', date: timestamp));
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
          final timestamp =
              timestampString.endsWith('Z') || timestampString.contains('+') || timestampString.contains('-')
              ? DateTime.parse(timestampString)
                    .toLocal() // Already has timezone info
              : DateTime.parse('${timestampString}Z').toLocal(); // Assume UTC if no timezone info

          if (!listCerts.any((existingCert) => existingCert.address == personAddress)) {
            listCerts.add(CertDisplayItem(address: personAddress, name: personName ?? '', date: timestamp));
          }
        }
      }
    }

    return listCerts;
  }

  /// Public method for manual refresh
  Future<void> refresh() async {
    state = const CertificationListState();
    await loadCertifications();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for certification lists
final certificationListProvider =
    StateNotifierProvider.family<
      CertificationListNotifier,
      CertificationListState,
      ({String address, CertDirection direction})
    >((ref, params) {
      return CertificationListNotifier(ref, params.address, params.direction);
    });
