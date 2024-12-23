import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.keyID,
    required this.avatarSize,
    required this.repository,
    required this.dateForm,
    required this.finalAmount,
    required this.duniterIndexer,
    required this.context,
  });

  final int keyID;
  final double avatarSize;
  final List repository;
  final String dateForm;
  final String finalAmount;
  final DuniterIndexer duniterIndexer;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final newKey = keyID + 1;
    final String? username = repository[2] == '' ? null : repository[2];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: scaleSize(16),
        vertical: scaleSize(4),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DatapodAvatar(
            address: repository[1],
            size: avatarSize,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getShortPubkey(repository[1]),
              style: scaledTextStyle(
                fontSize: 15,
                fontFamily: 'Monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
            ScaledSizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: scaledTextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
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
          ],
        ),
        trailing: Text(
          finalAmount,
          style: scaledTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: repository[4] == 'RECEIVED' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            PageNoTransit(
              builder: (context) => WalletViewScreen(
                address: repository[1],
                username: username,
              ),
            ),
          );
        },
      ),
    );
  }
}
