import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/widgets/certify/certify_button.dart';
import 'package:gecko/widgets/certify/wait_to_cert.dart';

class CertStateWidget extends ConsumerWidget {
  const CertStateWidget({super.key, required this.certState, required this.address});

  final CertState certState;
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      // Check if certification already exists to determine if it's a renewal
      final certExistsAsync = ref.watch(certificationExistsProvider(address));
      final idtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(address));

      return certExistsAsync.when(
        data: (certExists) {
          return idtyStatusAsync.when(
            data: (idtyStatus) => CertifyButton(address, isRenewal: certExists, idtyStatus: idtyStatus),
            loading: () => CertifyButton(address, isRenewal: certExists, idtyStatus: IdtyStatus.unknown),
            error: (_, _) => CertifyButton(address, isRenewal: certExists, idtyStatus: IdtyStatus.unknown),
          );
        },
        loading: () => CertifyButton(address, isRenewal: false, idtyStatus: IdtyStatus.unknown),
        error: (_, _) => CertifyButton(address, isRenewal: false, idtyStatus: IdtyStatus.unknown),
      );
    } else {
      return _buildDisabledButton(label);
    }
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
