import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/widgets/certify/certify_button.dart';
import 'package:gecko/widgets/certify/wait_to_cert.dart';

class CertStateWidget extends StatelessWidget {
  const CertStateWidget({super.key, required this.certState, required this.address});

  final CertState certState;
  final String address;

  @override
  Widget build(BuildContext context) {
    final duration = certState.duration ?? Duration.zero;
    return switch (certState.status) {
      CertStatus.canCert => CertifyButton(address),
      CertStatus.mustConfirmIdentity => WaitToCertWidget(messageKey: 'mustConfirmHisIdentity', duration: formatDuration(duration)),
      CertStatus.canRenewIn => WaitToCertWidget(messageKey: 'canRenewCertInX', duration: formatDuration(duration)),
      CertStatus.mustWaitBeforeCert => WaitToCertWidget(messageKey: 'mustWaitXBeforeCertify', duration: formatDuration(duration)),
      _ => const SizedBox.shrink(),
    };
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
}

enum CertStatus {
  canCert,
  mustConfirmIdentity,
  canRenewIn,
  mustWaitBeforeCert,
  none,
}

class CertState {
  final CertStatus status;
  final Duration? duration;

  CertState({required this.status, this.duration});
}
