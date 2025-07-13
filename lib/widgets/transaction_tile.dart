import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.keyID,
    required this.avatarSize,
    required this.transaction,
    required this.context,
  });

  final int keyID;
  final double avatarSize;
  final TransactionDisplayItem transaction;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final newKey = keyID + 1;
    final String? username = transaction.username == '' ? null : transaction.username;
    final BigInt finalAmount = transaction.isReceived ? transaction.amount : transaction.amount * BigInt.from(-1);
    final String dateString = DateFormat.yMd(
      Localizations.localeOf(context).languageCode,
    ).add_Hm().format(transaction.transactionTime);

    // Different UI for Universal Dividends
    if (transaction.type == TransactionType.universalDividend) {
      return _buildUniversalDividendTile(context, newKey, finalAmount, dateString);
    }

    // Standard transaction tile
    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(
        //   color: Colors.grey.withValues(alpha: 0.2),
        //   width: 1,
        // ),
      ),
      child: ListTile(
        key: keyTransaction(newKey),
        contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(8)),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.colorScheme.onSecondaryContainer, width: 1),
          ),
          child: DatapodAvatar(address: transaction.address, size: avatarSize),
        ),
        title: Padding(
          padding: EdgeInsets.only(bottom: scaleSize(5)),
          child: Text(
            getShortPubkey(transaction.address),
            style: scaledTextStyle(fontSize: 16, fontFamily: 'Monospace'),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (username != null) ...[
              Text(
                username,
                style: scaledTextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              ScaledSizedBox(height: 4),
            ],
            if (transaction.comment != null && transaction.comment!.isNotEmpty) ...[
              Text(
                transaction.comment!,
                style: scaledTextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ScaledSizedBox(height: 4),
            ],
            Text(dateString, style: scaledTextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        trailing: SizedBox(
          width: scaleSize(120), // Constrain the width to prevent overflow
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              BalanceDisplay(
                value: finalAmount,
                size: 16,
                color: transaction.isReceived ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
              ),
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            PageNoTransit(
              builder: (context) => WalletViewScreen(address: transaction.address, username: username),
            ),
          );
        },
      ),
    );
  }

  /// Build a specialized tile for Universal Dividends
  Widget _buildUniversalDividendTile(BuildContext context, int newKey, BigInt finalAmount, String dateString) {
    // Adaptive colors based on theme
    final bool isDark = context.isDarkTheme;

    final Color tileBackgroundColor = isDark ? Colors.teal.shade900.withValues(alpha: 0.15) : Colors.cyan.shade50;

    final Color tileBorderColor = isDark ? Colors.teal.shade700.withValues(alpha: 0.4) : Colors.cyan.shade200;

    final Color iconBackgroundColor = isDark ? Colors.teal.shade800.withValues(alpha: 0.3) : Colors.teal.shade100;

    final Color iconBorderColor = isDark ? Colors.teal.shade600.withValues(alpha: 0.6) : Colors.teal.shade300;

    final Color iconColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;

    final Color titleColor = isDark ? Colors.teal.shade200 : Colors.teal.shade800;

    final Color dateColor = isDark ? Colors.teal.shade300 : Colors.teal.shade600;

    final Color balanceColor = isDark ? Colors.cyan.shade300 : Colors.cyan.shade700;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(4)),
      decoration: BoxDecoration(
        color: tileBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tileBorderColor, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(12)),
        child: Row(
          children: [
            // Icon container - much smaller
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor,
                border: Border.all(color: iconBorderColor, width: 1),
              ),
              child: Center(child: Icon(Icons.water_drop, size: 16, color: iconColor)),
            ),

            ScaledSizedBox(width: 10),

            // Content - title and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'universalDividend'.tr(),
                    style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  ScaledSizedBox(height: 1),
                  Text(dateString, style: scaledTextStyle(fontSize: 10, color: dateColor)),
                ],
              ),
            ),

            // Balance - right aligned
            BalanceDisplay(value: finalAmount, size: 13, color: balanceColor),
          ],
        ),
      ),
    );
  }
}
