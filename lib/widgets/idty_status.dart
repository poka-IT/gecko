import 'package:durt2/durt2.dart' show IdtyStatus, WalletEntity, Durt;
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
    // Use the smart identity status provider to get real-time status
    final idtyStatusStream = ref.watch(smartIdtyStatusStreamProvider(address));

    return idtyStatusStream.when(
      data: (idtyStatus) {
        return _buildStatusWidget(context, idtyStatus);
      },
      loading: () {
        // Show a loading indicator while status is being fetched
        return _buildLoadingWidget();
      },
      error: (error, stack) {
        log.e('❌ Identity status widget error for $address: $error');
        // Show unknown status on error
        return _buildStatusWidget(context, IdtyStatus.unknown);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 16,
      width: 60,
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildStatusWidget(BuildContext context, IdtyStatus idtyStatus) {
    // Create a minimal wallet entity for display purposes only
    final displayWallet = WalletEntity.create(address: address, keyPairType: Durt.defaultKeyPairType);

    final nameByAddress = idtyStatus == IdtyStatus.validated
        ? NameByAddress(
            wallet: displayWallet,
            size: 18,
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
          )
        : NameByAddress(
            wallet: displayWallet,
            size: 16,
            color: context.colorScheme.onSurfaceVariant,
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
        AnimatedFadeOutIn<String>(
          data: statusText[idtyStatus]!,
          duration: const Duration(milliseconds: 150),
          builder: (value) => Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: scaleSize(15),
              color: color,
              fontWeight: idtyStatus == IdtyStatus.validated ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
