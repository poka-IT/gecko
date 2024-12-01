import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/manage_membership.dart';
import 'package:provider/provider.dart';

class ManageMembershipButton extends StatelessWidget {
  const ManageMembershipButton({super.key});

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManageMembership(address: walletOptions.address.text)),
        );
      },
      child: Container(
        height: scaleSize(48),
        padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: scaleSize(24),
              color: const Color(0xFFFF9800).withOpacity(0.8),
            ),
            ScaledSizedBox(width: 16),
            Text(
              'manageMembership'.tr(),
              style: scaledTextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
