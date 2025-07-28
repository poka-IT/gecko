import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers_deprecated/wallet_options.dart';
import 'package:gecko/screens/myWallets/manage_membership.dart';
import 'package:provider/provider.dart' as old_provider;

class ManageMembershipButton extends StatelessWidget {
  const ManageMembershipButton({super.key});

  @override
  Widget build(BuildContext context) {
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManageMembership(address: walletOptions.address.text)),
        );
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
