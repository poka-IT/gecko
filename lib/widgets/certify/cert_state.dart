import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/widgets/certify/certify_button.dart';
import 'package:gecko/widgets/certify/wait_to_cert.dart';

class CertStateWidget extends StatelessWidget {
  const CertStateWidget(
      {Key? key, required this.certState, required this.address})
      : super(key: key);

  final CertState certState;
  final String address;

  @override
  Widget build(BuildContext context) {
    switch (certState.status) {
      case CertStatus.canCert:
        return CertifyButton(address);
      case CertStatus.mustConfirmIdentity:
        return WaitToCertWidget(
            messageKey: 'mustConfirmHisIdentity',
            duration: formatDuration(certState.duration!));
      case CertStatus.canRenewIn:
        return WaitToCertWidget(
            messageKey: 'canRenewCertInX',
            duration: formatDuration(certState.duration!));
      case CertStatus.mustWaitBeforeCert:
        return WaitToCertWidget(
            messageKey: 'mustWaitXBeforeCertify',
            duration: formatDuration(certState.duration!));
      default:
        return const SizedBox.shrink();
    }
  }

  String formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = duration.inMinutes;

    if (seconds <= 0) {
      return 'seconds'.tr(args: ['0']);
    } else if (seconds <= 60) {
      return 'seconds'.tr(args: [seconds.toString()]);
    } else if (seconds <= 3600) {
      return 'minutes'.tr(args: [minutes.toString()]);
    } else if (seconds <= 86400) {
      final hours = duration.inHours;
      final minutesLeft = minutes - hours * 60;
      String showMinutes =
          minutesLeft < 60 ? '' : 'minutes'.tr(args: [minutesLeft.toString()]);
      return 'hours'.tr(args: [hours.toString(), showMinutes]);
    } else if (seconds <= 2592000) {
      final days = duration.inDays;
      return 'days'.tr(args: [days.toString()]);
    } else {
      final months = (duration.inDays / 30).round();
      return 'months'.tr(args: [months.toString()]);
    }
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
