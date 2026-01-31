/// Tests exhaustifs pour certButtonStateProvider
///
/// Ce provider détermine l'action du bouton de certification basé sur :
/// - L'état du storage (initialisé ou non)
/// - Le cache de certifications récentes (évite les actions avant propagation blockchain)
/// - L'état de certification (CertStatus) entre issuer et target
/// - L'état de la file d'attente de certifications
/// - L'existence d'une certification sur la blockchain
/// - Le statut d'identité de la cible
///
/// Actions possibles : none, certifyNow, addToQueue, inQueue, executeQueued, disabled
library;

import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/providers/certification_queue_provider.dart'
    show
        CertButtonAction,
        CertificationQueueNotifier,
        RecentCertData,
        RecentCertState,
        RecentCertificationsNotifier,
        certButtonStateProvider,
        certificationQueueProvider,
        recentCertificationsProvider;
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/stream_providers.dart';

void main() {
  const issuerAddress = '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY';
  const targetAddress = '5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty';

  late d.MockDuniterStorageService mockStorage;
  late d.MockWalletService mockWallets;

  setUpAll(() async {
    mockStorage = d.MockDuniterStorageService();
    mockWallets = d.MockWalletService();
    await d.DurtTestMode.init(
      config: d.DurtTestConfig(mockStorage: mockStorage, mockWallets: mockWallets),
    );
  });

  tearDownAll(() => d.DurtTestMode.reset());

  // ============================================================================
  // Helper pour créer un container de test
  // ============================================================================

  Future<ProviderContainer> createContainer({
    d.CertState? certState,
    d.IdtyStatus targetIdtyStatus = d.IdtyStatus.none,
    bool certificationExists = false,
    d.CertificationQueueState? queueState,
    Map<String, RecentCertData>? recentCertifications,
    StorageState storageState = StorageState.onlineMode,
  }) async {
    final effectiveQueueState = queueState ?? d.CertificationQueueState.empty(issuerAddress);

    final container = ProviderContainer(
      overrides: [
        storageStateProvider.overrideWith(() => _MockStorageStateNotifier(storageState)),
        certStateProvider(targetAddress).overrideWith(() => _MockCertStateNotifier(certState)),
        smartIdtyStatusStreamProvider(targetAddress).overrideWith((ref) => AsyncValue.data(targetIdtyStatus)),
        certificationExistsProvider(targetAddress).overrideWith((ref) async => certificationExists),
        certificationQueueProvider(
          issuerAddress,
        ).overrideWith(() => _MockCertificationQueueNotifier(effectiveQueueState)),
        recentCertificationsProvider.overrideWith(() => _MockRecentCertsNotifier(recentCertifications ?? {})),
      ],
    );

    // Prime les providers async pour éviter les blocages
    if (storageState == StorageState.onlineMode) {
      await container.read(certStateProvider(targetAddress).future);
      await container.read(certificationQueueProvider(issuerAddress).future);
    }

    return container;
  }

  d.CertificationQueueState createQueueWithTarget({bool isReady = false}) {
    return d.CertificationQueueState(
      issuerAddress: issuerAddress,
      pendingCertifications: [
        d.PendingCertification(
          id: 'test-cert',
          receiverAddress: targetAddress,
          addedAt: DateTime.now(),
          position: 1,
          certType: d.CertificationType.certification,
          expectedAvailableBlock: isReady ? 1 : 999999,
          expectedAvailableDate: isReady
              ? DateTime.now().subtract(const Duration(hours: 1))
              : DateTime.now().add(const Duration(days: 5)),
        ),
      ],
      lastUpdated: DateTime.now(),
      isSynced: true,
    );
  }

  // ============================================================================
  // 1. EARLY RETURNS - Vérifications avant la logique principale
  // ============================================================================

  group('Early returns', () {
    test('storageState.notInitialized → none', () async {
      final container = await createContainer(storageState: StorageState.notInitialized);
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.none);
      container.dispose();
    });

    test('wasCertifiedRecently (completed) → disabled (mustWaitXBeforeCertify)', () async {
      final container = await createContainer(
        certState: d.CertState(status: d.CertStatus.canCert),
        recentCertifications: {
          '$issuerAddress:$targetAddress': RecentCertData(
            timestamp: DateTime.now(),
            certState: RecentCertState.completed,
          ),
        },
      );
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.disabled);
      expect(result.disabledReason, 'mustWaitXBeforeCertify');
      container.dispose();
    });

    test('wasCertifiedRecently expiré → ne bloque plus', () async {
      final container = await createContainer(
        certState: d.CertState(status: d.CertStatus.canCert),
        recentCertifications: {
          '$issuerAddress:$targetAddress': RecentCertData(
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            certState: RecentCertState.completed,
          ),
        },
      );
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.certifyNow);
      container.dispose();
    });

    test('certState null && pas en file → none', () async {
      final container = await createContainer(certState: null);
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.none);
      container.dispose();
    });

    test('certState null && en file → inQueue', () async {
      final container = await createContainer(certState: null, queueState: createQueueWithTarget());
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.inQueue);
      expect(result.pendingCert, isNotNull);
      container.dispose();
    });
  });

  // ============================================================================
  // 2. CertStatus.none
  // ============================================================================

  group('CertStatus.none', () {
    test('→ none', () async {
      final container = await createContainer(certState: d.CertState(status: d.CertStatus.none));
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.none);
      container.dispose();
    });
  });

  // ============================================================================
  // 3. CertStatus.canCert
  // ============================================================================

  group('CertStatus.canCert', () {
    test('pas en file → certifyNow', () async {
      final container = await createContainer(certState: d.CertState(status: d.CertStatus.canCert));
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.certifyNow);
      container.dispose();
    });

    test('en file && prêt → executeQueued', () async {
      final container = await createContainer(
        certState: d.CertState(status: d.CertStatus.canCert),
        queueState: createQueueWithTarget(isReady: true),
      );
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.executeQueued);
      container.dispose();
    });

    test('en file && pas prêt → inQueue', () async {
      final container = await createContainer(
        certState: d.CertState(status: d.CertStatus.canCert),
        queueState: createQueueWithTarget(isReady: false),
      );
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.inQueue);
      container.dispose();
    });
  });

  // ============================================================================
  // 4. CertStatus.canRenewIn
  // ============================================================================

  // ============================================================================
  // 4 & 5. CertStatus.canRenewIn / mustWaitBeforeCert
  // Both involve waiting → always propose the queue (addToQueue)
  // ============================================================================

  for (final status in [d.CertStatus.canRenewIn, d.CertStatus.mustWaitBeforeCert]) {
    group('CertStatus.${status.name}', () {
      test('pas en file → addToQueue (planifier pour plus tard)', () async {
        final container = await createContainer(
          certState: d.CertState(status: status, duration: const Duration(days: 3)),
        );
        final result = await container.read(
          certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
        );
        expect(result.action, CertButtonAction.addToQueue);
        container.dispose();
      });

      test('en file && prêt → executeQueued', () async {
        final container = await createContainer(
          certState: d.CertState(status: status, duration: const Duration(days: 3)),
          queueState: createQueueWithTarget(isReady: true),
        );
        final result = await container.read(
          certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
        );
        expect(result.action, CertButtonAction.executeQueued);
        container.dispose();
      });

      test('en file && pas prêt → inQueue', () async {
        final container = await createContainer(
          certState: d.CertState(status: status, duration: const Duration(days: 3)),
          queueState: createQueueWithTarget(isReady: false),
        );
        final result = await container.read(
          certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
        );
        expect(result.action, CertButtonAction.inQueue);
        container.dispose();
      });
    });
  }

  // ============================================================================
  // 6. Autres CertStatus - États terminaux
  // ============================================================================

  group('Autres CertStatus', () {
    test('mustConfirmIdentity → disabled (mustConfirmHisIdentity)', () async {
      final container = await createContainer(certState: d.CertState(status: d.CertStatus.mustConfirmIdentity));
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.disabled);
      expect(result.disabledReason, 'mustConfirmHisIdentity');
      container.dispose();
    });

    test('emptyWallet → disabled (emptyWalletCannotBeCertified)', () async {
      final container = await createContainer(certState: d.CertState(status: d.CertStatus.emptyWallet));
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.disabled);
      expect(result.disabledReason, 'emptyWalletCannotBeCertified');
      container.dispose();
    });

    test('revoked → disabled (revokedAccountCannotBeCertified)', () async {
      final container = await createContainer(certState: d.CertState(status: d.CertStatus.revoked));
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.disabled);
      expect(result.disabledReason, 'revokedAccountCannotBeCertified');
      container.dispose();
    });
  });

  // ============================================================================
  // 7. Régressions - Bugs corrigés
  // ============================================================================

  group('Régressions', () {
    test('mustWaitBeforeCert → addToQueue (planifier pour plus tard)', () async {
      // Même avec un status unknown, l'utilisateur peut planifier la certification
      final container = await createContainer(certState: d.CertState(status: d.CertStatus.mustWaitBeforeCert));
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.addToQueue);
      container.dispose();
    });

    test('Bug: recentCert (completed) doit primer sur certState.canCert', () async {
      // Évite les doubles certifications avant propagation blockchain
      final container = await createContainer(
        certState: d.CertState(status: d.CertStatus.canCert),
        recentCertifications: {
          '$issuerAddress:$targetAddress': RecentCertData(
            timestamp: DateTime.now(),
            certState: RecentCertState.completed,
          ),
        },
      );
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.disabled);
      container.dispose();
    });

    test('Bug: certification en cours doit afficher "inProgress" et non "disabled"', () async {
      // Reproduit le bug où pendant une certification en cours, le bouton affiche
      // "Vous devez attendre 5 jours" au lieu de "Certification en cours"

      final container = ProviderContainer(
        overrides: [
          storageStateProvider.overrideWith(() => _MockStorageStateNotifier(StorageState.onlineMode)),
          certStateProvider(
            targetAddress,
          ).overrideWith(() => _MockCertStateNotifier(d.CertState(status: d.CertStatus.canCert))),
          smartIdtyStatusStreamProvider(targetAddress).overrideWith((ref) => AsyncValue.data(d.IdtyStatus.validated)),
          certificationExistsProvider(targetAddress).overrideWith((ref) async => false),
          certificationQueueProvider(
            issuerAddress,
          ).overrideWith(() => _MockCertificationQueueNotifier(d.CertificationQueueState.empty(issuerAddress))),
        ],
      );

      // Prime les providers
      await container.read(certStateProvider(targetAddress).future);
      await container.read(certificationQueueProvider(issuerAddress).future);

      // Simule le début d'une certification (transaction en cours)
      container.read(recentCertificationsProvider.notifier).markInProgress(issuerAddress, targetAddress);

      // Invalide pour forcer le recalcul
      container.invalidate(certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)));

      // Le bouton devrait être "inProgress" et NON "disabled"
      final result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(
        result.action,
        CertButtonAction.inProgress,
        reason: 'Devrait afficher "Certification en cours" pendant la transaction',
      );
      expect(result.disabledReason, isNull, reason: 'Pas de raison de désactivation, juste en cours');

      container.dispose();
    });

    test('Bug: certification échouée doit retirer du cache et permettre de recertifier', () async {
      // Reproduit le bug où une certification échouée maintient le bouton en état disabled
      // pendant 5 jours car la certification reste dans le cache malgré l'échec

      final container = ProviderContainer(
        overrides: [
          storageStateProvider.overrideWith(() => _MockStorageStateNotifier(StorageState.onlineMode)),
          certStateProvider(
            targetAddress,
          ).overrideWith(() => _MockCertStateNotifier(d.CertState(status: d.CertStatus.canCert))),
          smartIdtyStatusStreamProvider(targetAddress).overrideWith((ref) => AsyncValue.data(d.IdtyStatus.validated)),
          certificationExistsProvider(targetAddress).overrideWith((ref) async => false),
          certificationQueueProvider(
            issuerAddress,
          ).overrideWith(() => _MockCertificationQueueNotifier(d.CertificationQueueState.empty(issuerAddress))),
        ],
      );

      // Prime les providers
      await container.read(certStateProvider(targetAddress).future);
      await container.read(certificationQueueProvider(issuerAddress).future);

      // Simule le début d'une certification (markInProgress comme fait par certify_button.dart)
      container.read(recentCertificationsProvider.notifier).markInProgress(issuerAddress, targetAddress);

      // Le bouton devrait être "inProgress" car la transaction est en cours
      var result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.inProgress, reason: 'Devrait être inProgress car transaction en cours');

      // Simule l'échec de la transaction - on retire du cache
      container.read(recentCertificationsProvider.notifier).removeCertification(issuerAddress, targetAddress);

      // Invalide le provider pour forcer le recalcul
      container.invalidate(certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)));

      // Le bouton devrait revenir à certifyNow car la certification a échoué
      result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.certifyNow, reason: 'Devrait permettre de recertifier après échec');

      container.dispose();
    });

    test('Bug: certification réussie doit passer de inProgress à disabled', () async {
      // Vérifie que quand une certification réussit, le bouton passe de "en cours" à "disabled"

      final container = ProviderContainer(
        overrides: [
          storageStateProvider.overrideWith(() => _MockStorageStateNotifier(StorageState.onlineMode)),
          certStateProvider(
            targetAddress,
          ).overrideWith(() => _MockCertStateNotifier(d.CertState(status: d.CertStatus.canCert))),
          smartIdtyStatusStreamProvider(targetAddress).overrideWith((ref) => AsyncValue.data(d.IdtyStatus.validated)),
          certificationExistsProvider(targetAddress).overrideWith((ref) async => false),
          certificationQueueProvider(
            issuerAddress,
          ).overrideWith(() => _MockCertificationQueueNotifier(d.CertificationQueueState.empty(issuerAddress))),
        ],
      );

      // Prime les providers
      await container.read(certStateProvider(targetAddress).future);
      await container.read(certificationQueueProvider(issuerAddress).future);

      // Simule le début d'une certification
      container.read(recentCertificationsProvider.notifier).markInProgress(issuerAddress, targetAddress);

      // Le bouton devrait être "inProgress"
      var result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.inProgress, reason: 'Devrait être inProgress');

      // Simule le succès de la transaction
      container.read(recentCertificationsProvider.notifier).markCompleted(issuerAddress, targetAddress);

      // Invalide le provider pour forcer le recalcul
      container.invalidate(certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)));

      // Le bouton devrait être "disabled" car certification récente complétée
      result = await container.read(
        certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: targetAddress)).future,
      );
      expect(result.action, CertButtonAction.disabled, reason: 'Devrait être disabled après certification réussie');
      expect(result.disabledReason, 'mustWaitXBeforeCertify');

      container.dispose();
    });
  });
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

class _MockRecentCertsNotifier extends RecentCertificationsNotifier {
  final Map<String, RecentCertData> _initialState;
  _MockRecentCertsNotifier(this._initialState);
  @override
  Map<String, RecentCertData> build() => _initialState;
}
