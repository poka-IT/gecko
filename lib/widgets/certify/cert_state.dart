import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/widgets/certify/add_to_queue_button.dart';
import 'package:gecko/widgets/certify/certify_button.dart';
import 'package:gecko/widgets/certify/execute_queued_button.dart';
import 'package:gecko/widgets/certify/in_queue_button.dart';
import 'package:gecko/widgets/certify/wait_to_cert.dart';

class CertStateWidget extends ConsumerWidget {
  const CertStateWidget({super.key, required this.certState, required this.address});

  final CertState certState;
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the effective certification wallet (issuer)
    final issuerWalletAsync = ref.watch(effectiveCertificationWalletProvider);

    // Keep last known data to avoid flicker during provider refresh
    final issuerWallet = issuerWalletAsync.asData?.value;
    if (issuerWallet == null) {
      return _buildLegacyWidget(context, ref);
    }

    final issuerAddress = issuerWallet.address;
    final buttonStateAsync = ref.watch(certButtonStateProvider((issuerAddress: issuerAddress, targetAddress: address)));

    final buttonState = buttonStateAsync.asData?.value;
    if (buttonState == null) {
      return _buildLegacyWidget(context, ref);
    }

    return _buildFromButtonState(context, ref, buttonState, issuerAddress);
  }

  Widget _buildFromButtonState(BuildContext context, WidgetRef ref, CertButtonState buttonState, String issuerAddress) {
    // Use certState from buttonState if available, otherwise fallback to widget's certState
    final effectiveCertState = buttonState.certState ?? certState;

    switch (buttonState.action) {
      case CertButtonAction.none:
        return const SizedBox.shrink();

      case CertButtonAction.certifyNow:
        return _buildCertifyButton(ref);

      case CertButtonAction.addToQueue:
        return AddToQueueButton(address: address, certState: effectiveCertState, issuerAddress: issuerAddress);

      case CertButtonAction.inQueue:
        return InQueueButton(pendingCert: buttonState.pendingCert!, issuerAddress: issuerAddress);

      case CertButtonAction.executeQueued:
        return ExecuteQueuedButton(
          address: address,
          pendingCert: buttonState.pendingCert!,
          issuerAddress: issuerAddress,
        );

      case CertButtonAction.inProgress:
        return WaitToCertWidget(label: 'certificationInProgress'.tr(), duration: '', showSpinner: true);

      case CertButtonAction.disabled:
        // Use effectiveCertState for up-to-date duration
        return _buildDisabledButtonFromState(effectiveCertState, buttonState.disabledReason);
    }
  }

  Widget _buildDisabledButtonFromState(CertState state, String? reason) {
    final label = switch (reason ?? state.status.name) {
      'canRenewCertInX' => 'canRenewCertInX'.tr(args: [formatDuration(state.duration ?? Duration.zero)]),
      'mustWaitXBeforeCertify' => 'mustWaitXBeforeCertify'.tr(args: [formatDuration(state.duration ?? Duration.zero)]),
      'justCertified' => 'justCertified'.tr(),
      'migratedAccountCannotBeCertified' => 'migratedAccountCannotBeCertified'.tr(),
      _ => _getLabelFromStatus(state),
    };
    return WaitToCertWidget(
      label: label,
      duration: formatDuration(state.duration ?? Duration.zero),
      isSuccess: reason == 'justCertified',
    );
  }

  String _getLabelFromStatus(CertState state) {
    return switch (state.status) {
      CertStatus.canRenewIn => 'canRenewCertInX'.tr(args: [formatDuration(state.duration!)]),
      CertStatus.mustWaitBeforeCert => 'mustWaitXBeforeCertify'.tr(args: [formatDuration(state.duration!)]),
      CertStatus.mustConfirmIdentity => 'mustConfirmHisIdentity'.tr(),
      CertStatus.emptyWallet => 'emptyWalletCannotBeCertified'.tr(),
      CertStatus.revoked => 'revokedAccountCannotBeCertified'.tr(),
      _ => '',
    };
  }

  /// Fallback to legacy widget building when button state is loading/error
  Widget _buildLegacyWidget(BuildContext context, WidgetRef ref) {
    String label;
    bool canCertify = false;

    switch (certState.status) {
      case CertStatus.canCert:
        label = 'certify'.tr();
        canCertify = true;
        break;
      case CertStatus.canRenewIn:
        label = 'canRenewCertInX'.tr(args: [formatDuration(certState.duration!)]);
        break;
      case CertStatus.mustWaitBeforeCert:
        label = 'mustWaitXBeforeCertify'.tr(args: [formatDuration(certState.duration!)]);
        break;
      case CertStatus.mustConfirmIdentity:
        label = 'mustConfirmHisIdentity'.tr();
        break;
      case CertStatus.emptyWallet:
        label = 'emptyWalletCannotBeCertified'.tr();
        break;
      case CertStatus.revoked:
        label = 'revokedAccountCannotBeCertified'.tr();
        break;
      case CertStatus.none:
        return const SizedBox.shrink();
    }

    if (canCertify) {
      return _buildCertifyButton(ref);
    } else {
      return _buildDisabledButton(label);
    }
  }

  Widget _buildCertifyButton(WidgetRef ref) {
    // Check if certification already exists to determine if it's a renewal
    final certExistsAsync = ref.watch(certificationExistsProvider(address));
    final idtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(address));

    // Use last known values to avoid flicker during refresh
    final certExists = certExistsAsync.asData?.value ?? false;
    final idtyStatus = idtyStatusAsync.asData?.value ?? IdtyStatus.unknown;

    return CertifyButton(address, isRenewal: certExists, idtyStatus: idtyStatus);
  }

  String formatDuration(Duration duration) {
    return switch (duration) {
      <= Duration.zero => 'seconds'.tr(args: ['0']),
      <= const Duration(minutes: 1) => 'seconds'.tr(args: [duration.inSeconds.toString()]),
      <= const Duration(hours: 1) => 'minutes'.tr(args: [duration.inMinutes.toString()]),
      <= const Duration(days: 1) => () {
        final minutesPart = duration - Duration(hours: duration.inHours);
        final showMinutes = minutesPart.inMinutes > 0 ? 'minutes'.tr(args: [minutesPart.inMinutes.toString()]) : '';
        return 'hours'.tr(args: [duration.inHours.toString(), showMinutes]);
      }(),
      <= const Duration(days: 30) => 'days'.tr(args: [duration.inDays.toString()]),
      _ => () {
        final months = (duration.inDays / 30).round();
        return 'months'.tr(args: [months.toString()]);
      }(),
    };
  }

  Widget _buildDisabledButton(String label) {
    return WaitToCertWidget(label: label, duration: formatDuration(certState.duration ?? Duration.zero));
  }
}
