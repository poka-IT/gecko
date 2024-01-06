import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    Key? key,
    required this.keyID,
    required this.avatarSize,
    required this.repository,
    required this.dateForm,
    required this.finalAmount,
    required this.duniterIndexer,
    required this.context,
  }) : super(key: key);

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

    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: ListTile(
          key: keyTransaction(newKey),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          leading: DatapodAvatar(address: repository[1], size: avatarSize),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(getShortPubkey(repository[1]),
                style: scaledTextStyle(fontSize: 17, fontFamily: 'Monospace')),
          ),
          subtitle: RichText(
            text: TextSpan(
              style: scaledTextStyle(
                fontSize: 17,
                color: Colors.grey[700],
              ),
              children: <TextSpan>[
                TextSpan(text: dateForm, style: scaledTextStyle(fontSize: 16)),
                if (username != null)
                  TextSpan(
                    text: '  ·  ',
                    style: scaledTextStyle(
                      fontSize: 21,
                      color: Colors.grey[550],
                    ),
                  ),
                TextSpan(
                  text: username,
                  style: scaledTextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                      fontSize: 16),
                ),
              ],
            ),
          ),
          trailing: Text(finalAmount,
              style: scaledTextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: repository[4] == 'RECEIVED'
                      ? Colors.green[700]
                      : Colors.blue[700]),
              textAlign: TextAlign.justify),
          dense: !isTall,
          isThreeLine: false,
          onTap: () {
            Navigator.push(
              context,
              PageNoTransit(builder: (context) {
                return WalletViewScreen(
                  address: repository[1],
                  username: username,
                );
              }),
            );
          }),
    );
  }
}
