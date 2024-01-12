import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_content.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:gecko/widgets/transaction_status_icon.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fade_and_translate/fade_and_translate.dart';

class TransactionInProgressTule extends StatefulWidget {
  const TransactionInProgressTule(
      {Key? key, required this.address, this.transactionId})
      : super(key: key);

  final String address;
  final String? transactionId;

  @override
  State<TransactionInProgressTule> createState() =>
      _TransactionInProgressTuleState();
}

class _TransactionInProgressTuleState extends State<TransactionInProgressTule> {
  late bool isVisible;
  late TransactionContent txContent;
  @override
  void initState() {
    isVisible = true;
    StreamSubscription<QueryResult>? subscription;
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final stream = duniterIndexer.subscribeHistoryIssued(widget.address);
    txContent = sub.transactionStatus[widget.transactionId]!;

    subscription = stream.listen((result) {
      if (result.data?['account_by_pk'] == null) return;
      if (result.hasException) {
        log.e(result.exception);
        isVisible = true;
      } else {
        final Map transData =
            result.data?['account_by_pk']['transactions_issued'].first;
        final String receiver = transData['receiver_pubkey'];
        final double amount = transData['amount'] / 100;
        final createdAt = DateTime.parse(transData['created_at']);
        final difference = createdAt.difference(DateTime.now());

        if (receiver == txContent.to &&
            amount == txContent.amount &&
            difference.inSeconds.abs() < 30) {
          isVisible = false;
          txContent.status = TransactionStatus.finalized;
          sub.reload();
          subscription?.cancel();
        } else {
          isVisible = true;
        }
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      final statusIcon =
          TransactionStatusIcon(txContent.status, size: 21, stroke: 2);
      String humanStatus = '';
      final finalAmount = txContent.amount * -1;

      if (txContent.status == TransactionStatus.success) {
        humanStatus = 'extrinsicValidated'.tr(args: [actionMap['pay']!]);
      } else if (txContent.status == TransactionStatus.failed) {
        humanStatus = errorTransactionMap[txContent.error] ?? txContent.error!;
      } else {
        humanStatus = statusStatusMap[txContent.status] ??
            'Unknown status: ${txContent.status}';
      }

      return FadeAndTranslate(
        visible: isVisible,
        translate: const Offset(0, -40),
        delay: const Duration(seconds: 2),
        duration: const Duration(milliseconds: 700),
        onCompleted: () async => duniterIndexer.refetch?.call(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: orangeC,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Transaction en cours',
                  style: scaledTextStyle(
                      fontSize: 20,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w400),
                ),
                ListTile(
                    key: const Key('transactionInProgress'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                    leading: DatapodAvatar(address: txContent.to, size: 50),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(getShortPubkey(txContent.to),
                          style: scaledTextStyle(
                              fontSize: 17, fontFamily: 'Monospace')),
                    ),
                    subtitle: Row(
                      children: [
                        statusIcon,
                        ScaledSizedBox(width: 10),
                        ScaledSizedBox(
                          width: 170,
                          child: Text(
                            humanStatus,
                            style: scaledTextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .color,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text("$finalAmount $currencyName",
                        style: scaledTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700]),
                        textAlign: TextAlign.justify),
                    dense: !isTall,
                    isThreeLine: false),
              ],
            ),
          ),
        ),
      );
    });
  }
}
