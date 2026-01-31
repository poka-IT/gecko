/// Tests pour la logique de certification dans TransactionInProgressScreen
///
/// Ces tests vérifient que les callbacks de certification sont appelés correctement:
/// - inProgress → finalized → markCompleted()
/// - inProgress → error → removeCertification()
///
/// Note: Ces tests utilisent un widget minimal pour éviter les dépendances
/// complexes (Hive, avatars, etc.) tout en testant la logique critique.
library;

import 'dart:async';

import 'package:durt2/durt2.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/stream_providers.dart';

void main() {
  const issuerAddress = '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY';
  const targetAddress = '5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty';

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize durt2 test mode
    final mockStorage = d.MockDuniterStorageService();
    final mockWallets = d.MockWalletService();
    await d.DurtTestMode.init(
      config: d.DurtTestConfig(mockStorage: mockStorage, mockWallets: mockWallets),
    );
  });

  tearDownAll(() => d.DurtTestMode.reset());

  /// Crée un container avec les providers minimaux pour tester la logique de certification
  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        storageStateProvider.overrideWith(() => _MockStorageStateNotifier(StorageState.onlineMode)),
        certStateProvider(
          targetAddress,
        ).overrideWith(() => _MockCertStateNotifier(d.CertState(status: d.CertStatus.canCert))),
        smartIdtyStatusStreamProvider(
          targetAddress,
        ).overrideWith((ref) => const AsyncValue.data(d.IdtyStatus.validated)),
        certificationExistsProvider(targetAddress).overrideWith((ref) async => false),
        certificationQueueProvider(
          issuerAddress,
        ).overrideWith(() => _MockCertificationQueueNotifier(d.CertificationQueueState.empty(issuerAddress))),
      ],
    );
  }

  /// Widget minimal qui simule UNIQUEMENT la logique de TransactionInProgressScreen
  /// sans toutes les dépendances UI (avatars, traductions, etc.)
  Widget createMinimalTestWidget({
    required Stream<d.TransactionStatus> transactionStatus,
    required ProviderContainer container,
    required String fromAddress,
    required String toAddress,
    String transType = 'cert',
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: _MinimalTransactionWidget(
          transactionStatus: transactionStatus,
          transType: transType,
          fromAddress: fromAddress,
          toAddress: toAddress,
        ),
      ),
    );
  }

  group('Certification Flow - Logique du cache', () {
    testWidgets('SUCCESS: inProgress → inBlock → markCompleted() appelé', (tester) async {
      final container = createContainer();
      final streamController = StreamController<d.TransactionStatus>();

      // 1. Marquer la certification comme "en cours"
      container.read(recentCertificationsProvider.notifier).markInProgress(issuerAddress, targetAddress);
      expect(container.read(recentCertificationsProvider.notifier).isInProgress(issuerAddress, targetAddress), isTrue);

      // 2. Construire le widget
      await tester.pumpWidget(
        createMinimalTestWidget(
          transactionStatus: streamController.stream,
          container: container,
          fromAddress: issuerAddress,
          toAddress: targetAddress,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // 3. Simuler "inBlock" (transaction validée)
      streamController.add(d.TransactionStatus(state: d.TransactionState.inBlock));
      await tester.pump(const Duration(milliseconds: 50));
      // Pump again to execute addPostFrameCallback
      await tester.pump();

      // 4. Vérifier que markCompleted() a été appelé
      expect(
        container.read(recentCertificationsProvider.notifier).isInProgress(issuerAddress, targetAddress),
        isFalse,
        reason: 'Ne devrait plus être inProgress après inBlock',
      );
      expect(
        container.read(recentCertificationsProvider.notifier).wasCertifiedRecently(issuerAddress, targetAddress),
        isTrue,
        reason: 'Devrait être "récemment certifié" après succès',
      );

      await streamController.close();
      container.dispose();
    });

    testWidgets('SUCCESS: inProgress → finalized → markCompleted() appelé', (tester) async {
      final container = createContainer();
      final streamController = StreamController<d.TransactionStatus>();

      container.read(recentCertificationsProvider.notifier).markInProgress(issuerAddress, targetAddress);

      await tester.pumpWidget(
        createMinimalTestWidget(
          transactionStatus: streamController.stream,
          container: container,
          fromAddress: issuerAddress,
          toAddress: targetAddress,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      streamController.add(d.TransactionStatus(state: d.TransactionState.finalized));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(); // Execute addPostFrameCallback

      expect(container.read(recentCertificationsProvider.notifier).isInProgress(issuerAddress, targetAddress), isFalse);
      expect(
        container.read(recentCertificationsProvider.notifier).wasCertifiedRecently(issuerAddress, targetAddress),
        isTrue,
      );

      await streamController.close();
      container.dispose();
    });

    testWidgets('ERROR: inProgress → error → removeCertification() appelé', (tester) async {
      final container = createContainer();
      final streamController = StreamController<d.TransactionStatus>();

      container.read(recentCertificationsProvider.notifier).markInProgress(issuerAddress, targetAddress);
      expect(container.read(recentCertificationsProvider.notifier).isInProgress(issuerAddress, targetAddress), isTrue);

      await tester.pumpWidget(
        createMinimalTestWidget(
          transactionStatus: streamController.stream,
          container: container,
          fromAddress: issuerAddress,
          toAddress: targetAddress,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Simuler une erreur
      streamController.add(
        d.TransactionStatus(state: d.TransactionState.error, errorMessage: 'identity.CanNotRevokeUnvalidated'),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(); // Execute addPostFrameCallback

      // Vérifier que removeCertification() a été appelé
      expect(
        container.read(recentCertificationsProvider.notifier).isInProgress(issuerAddress, targetAddress),
        isFalse,
        reason: 'Ne devrait plus être inProgress après erreur',
      );
      expect(
        container.read(recentCertificationsProvider.notifier).wasCertifiedRecently(issuerAddress, targetAddress),
        isFalse,
        reason: 'Ne devrait PAS être "récemment certifié" après erreur',
      );

      await streamController.close();
      container.dispose();
    });

    testWidgets('TIMEOUT: reste inProgress (comportement actuel)', (tester) async {
      final container = createContainer();
      final streamController = StreamController<d.TransactionStatus>();

      container.read(recentCertificationsProvider.notifier).markInProgress(issuerAddress, targetAddress);

      await tester.pumpWidget(
        createMinimalTestWidget(
          transactionStatus: streamController.stream,
          container: container,
          fromAddress: issuerAddress,
          toAddress: targetAddress,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      streamController.add(d.TransactionStatus(state: d.TransactionState.timeout));
      await tester.pump(const Duration(milliseconds: 50));

      // Note: Le timeout n'est pas traité comme une erreur actuellement
      // Ce test documente le comportement actuel
      expect(
        container.read(recentCertificationsProvider.notifier).isInProgress(issuerAddress, targetAddress),
        isTrue,
        reason: 'timeout ne retire pas du cache (comportement actuel)',
      );

      await streamController.close();
      container.dispose();
    });

    testWidgets('NON-CERT: transType=pay ne modifie pas le cache', (tester) async {
      final container = createContainer();
      final streamController = StreamController<d.TransactionStatus>();

      await tester.pumpWidget(
        createMinimalTestWidget(
          transactionStatus: streamController.stream,
          container: container,
          fromAddress: issuerAddress,
          toAddress: targetAddress,
          transType: 'pay',
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      streamController.add(d.TransactionStatus(state: d.TransactionState.finalized));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        container.read(recentCertificationsProvider.notifier).wasCertifiedRecently(issuerAddress, targetAddress),
        isFalse,
        reason: 'Transaction pay ne devrait pas affecter le cache de certification',
      );

      await streamController.close();
      container.dispose();
    });
  });

  // Note: Les tests d'intégration avec certButtonStateProvider sont dans
  // test/providers/cert_button_state_test.dart car ils nécessitent plus de setup
}

// =============================================================================
// Widget de test minimal qui réplique SEULEMENT la logique de certification
// =============================================================================

class _MinimalTransactionWidget extends ConsumerStatefulWidget {
  final Stream<d.TransactionStatus> transactionStatus;
  final String transType;
  final String fromAddress;
  final String toAddress;

  const _MinimalTransactionWidget({
    required this.transactionStatus,
    required this.transType,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  ConsumerState<_MinimalTransactionWidget> createState() => _MinimalTransactionWidgetState();
}

class _MinimalTransactionWidgetState extends ConsumerState<_MinimalTransactionWidget> {
  bool _hasInvalidatedProviders = false;
  bool _hasHandledFailure = false;

  /// Exactement la même logique que TransactionInProgressScreen._handleFailedCertification()
  void _handleFailedCertification() {
    if (_hasHandledFailure) return;
    _hasHandledFailure = true;

    if (widget.transType == 'cert' && widget.toAddress.isNotEmpty && widget.fromAddress.isNotEmpty) {
      ref.read(recentCertificationsProvider.notifier).removeCertification(widget.fromAddress, widget.toAddress);
      ref.invalidate(certButtonStateProvider((issuerAddress: widget.fromAddress, targetAddress: widget.toAddress)));
    }
  }

  /// Exactement la même logique que TransactionInProgressScreen._invalidateCertificationProviders()
  void _invalidateCertificationProviders() {
    if (_hasInvalidatedProviders) return;
    _hasInvalidatedProviders = true;

    if (widget.transType == 'cert' && widget.toAddress.isNotEmpty && widget.fromAddress.isNotEmpty) {
      ref.read(recentCertificationsProvider.notifier).markCompleted(widget.fromAddress, widget.toAddress);
      ref.invalidate(certificationExistsProvider(widget.toAddress));
      ref.invalidate(certStateProvider(widget.toAddress));
      ref.invalidate(smartIdtyStatusStreamProvider(widget.toAddress));
      ref.invalidate(certButtonStateProvider((issuerAddress: widget.fromAddress, targetAddress: widget.toAddress)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<d.TransactionStatus>(
      stream: widget.transactionStatus,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final txStatus = snapshot.data!;

          // Exactement la même logique que TransactionInProgressScreen
          // Use Future.microtask to avoid modifying providers during build
          if (txStatus.state == d.TransactionState.finalized || txStatus.state == d.TransactionState.inBlock) {
            if (!_hasInvalidatedProviders) {
              Future.microtask(() {
                _invalidateCertificationProviders();
              });
            }
          }

          if (txStatus.state == d.TransactionState.error) {
            if (!_hasHandledFailure) {
              Future.microtask(() {
                _handleFailedCertification();
              });
            }
          }

          return Text('Status: ${txStatus.state}');
        }
        return const Text('Loading...');
      },
    );
  }
}

// =============================================================================
// Mock Notifiers
// =============================================================================

class _MockStorageStateNotifier extends StorageStateNotifier {
  final StorageState _state;
  _MockStorageStateNotifier(this._state);
  @override
  StorageState build() => _state;
}

class _MockCertStateNotifier extends CertStateNotifier {
  final d.CertState? _value;
  _MockCertStateNotifier(this._value) : super('mock');
  @override
  Future<d.CertState?> build() async => _value;
}

class _MockCertificationQueueNotifier extends CertificationQueueNotifier {
  final d.CertificationQueueState _value;
  _MockCertificationQueueNotifier(this._value) : super('mock');
  @override
  Future<d.CertificationQueueState?> build() async => _value;
}
