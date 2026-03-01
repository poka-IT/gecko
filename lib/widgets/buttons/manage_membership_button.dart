import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/membership_renewal.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/membership_providers.dart';
import 'package:gecko/screens/myWallets/manage_membership.dart';

class ManageMembershipButton extends ConsumerWidget {
  const ManageMembershipButton({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipStatusProvider(address));
    final showBadge =
        membershipAsync.whenOrNull(
          data: (status) {
            final info = MembershipRenewal.calculateRenewalInfo(status);
            return info.canRenew || info.isExpired || info.hasPendingRenewal;
          },
        ) ??
        false;

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ManageMembership(address: address)));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: scaleSize(24),
                  color: const Color(0xFFFF9800).withValues(alpha: 0.8),
                ),
                if (showBadge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: scaleSize(8),
                      height: scaleSize(8),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            ScaledSizedBox(width: 16),
            Expanded(
              child: Text(
                'manageMembership'.tr(),
                style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
