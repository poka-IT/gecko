import 'package:durt2/durt2.dart' show IdtyStatus, WalletEntity, Durt;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class IdentityStatus extends ConsumerWidget {
  const IdentityStatus({super.key, required this.address, required this.color});
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletService = ref.watch(walletServiceProvider);

    final walletData =
        walletService.walletBox.query(WalletEntity_.address.equals(address)).build().findFirst() ??
        WalletEntity.create(address: address, keyPairType: Durt.defaultKeyPairType, identityStatus: IdtyStatus.unknown);

    // Use the smart identity status provider instead of FutureBuilder
    final idtyStatusStream = ref.watch(smartIdtyStatusStreamProvider(address));

    return idtyStatusStream.when(
      data: (idtyStatus) {
        // Update wallet data with new status
        walletData.identityStatus = idtyStatus;
        return _buildStatusWidget(context, walletData, idtyStatus);
      },
      loading: () {
        // Show current status while loading
        return _buildStatusWidget(context, walletData, walletData.identityStatus);
      },
      error: (error, stack) {
        log.e('❌ Identity status widget error for $address: $error');
        // Show current status on error
        return _buildStatusWidget(context, walletData, walletData.identityStatus);
      },
    );
  }

  Widget _buildStatusWidget(BuildContext context, WalletEntity walletData, IdtyStatus resStatus) {
    final nameByAddress = resStatus == IdtyStatus.validated
        ? NameByAddress(
            wallet: walletData,
            size: 18,
            color: homeContext.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
          )
        : NameByAddress(
            wallet: walletData,
            size: 16,
            color: homeContext.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          );

    final Map<IdtyStatus, String> statusText = {
      IdtyStatus.none: '',
      IdtyStatus.created: 'identityCreated'.tr(),
      IdtyStatus.confirmed: 'identityConfirmed'.tr(),
      IdtyStatus.validated: 'memberValidated'.tr(),
      IdtyStatus.expired: 'identityExpired'.tr(),
      IdtyStatus.revoked: 'identityRevoked'.tr(),
      IdtyStatus.unknown: '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FittedBox only for the name to scale down when too long
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: nameByAddress),
        showText(context, statusText[resStatus]!, bold: resStatus == IdtyStatus.validated, size: scaleSize(15)),
      ],
    );
  }

  AnimatedFadeOutIn showText(BuildContext context, String text, {double size = 18, bool bold = false}) {
    return AnimatedFadeOutIn<String>(
      data: text,
      duration: const Duration(milliseconds: 150),
      builder: (value) => Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size, color: color, fontWeight: bold ? FontWeight.w500 : FontWeight.w400),
      ),
    );
  }
}
