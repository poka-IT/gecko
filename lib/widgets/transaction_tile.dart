import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
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
    required this.dateForm,
    required this.finalAmount,
    required this.duniterIndexer,
    required this.context,
  });

  final int keyID;
  final double avatarSize;
  final Transaction transaction;
  final String dateForm;
  final int finalAmount;
  final DuniterIndexer duniterIndexer;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final newKey = keyID + 1;
    final String? username = transaction.username == '' ? null : transaction.username;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: scaleSize(16),
        vertical: scaleSize(4),
      ),
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: scaleSize(16),
          vertical: scaleSize(8),
        ),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: context.colorScheme.onSecondaryContainer,
              width: 1,
            ),
          ),
          child: DatapodAvatar(
            address: transaction.address,
            size: avatarSize,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getShortPubkey(transaction.address),
              style: scaledTextStyle(
                fontSize: 15,
                fontFamily: 'Monospace',
                fontWeight: FontWeight.w500,
                color: context.colorScheme.onSecondaryContainer,
              ),
            ),
            ScaledSizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: scaledTextStyle(
                  fontSize: 13,
                  color: homeContext.colorScheme.onSurfaceVariant,
                ),
                children: <TextSpan>[
                  TextSpan(text: dateForm),
                  if (username != null) ...[
                    TextSpan(
                      text: '  ·  ',
                      style: scaledTextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    TextSpan(
                      text: username,
                      style: scaledTextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (transaction.comment.isNotEmpty) ...[
              ScaledSizedBox(height: 4),
              Text(
                transaction.comment,
                style: scaledTextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: BalanceDisplay(
          value: finalAmount,
          size: scaleSize(13),
          color: transaction.isReceived ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
          fontWeight: FontWeight.w500,
        ),
        onTap: () {
          Navigator.push(
            context,
            PageNoTransit(
              builder: (context) => WalletViewScreen(
                address: transaction.address,
                username: username,
              ),
            ),
          );
        },
      ),
    );
  }
}
