import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

import 'package:gecko/screens/myWallets/manage_membership.dart';

class ManageMembershipButton extends StatelessWidget {
  const ManageMembershipButton({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ManageMembership(address: address)));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: scaleSize(24),
              color: const Color(0xFFFF9800).withValues(alpha: 0.8),
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
