import 'dart:async';

import 'package:durt2/durt2.dart' hide Provider;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:gecko/widgets/transaction_state_icon.dart';
import 'package:gecko/widgets/ud_unit_display.dart';
import 'package:provider/provider.dart';
import 'package:fade_and_translate/fade_and_translate.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';

class TransactionInProgressTule extends StatefulWidget {
  const TransactionInProgressTule({super.key, required this.transactionData});

  final TransactionInProgressData transactionData;

  @override
  State<TransactionInProgressTule> createState() => _TransactionInProgressTuleState();
}

class _TransactionInProgressTuleState extends State<TransactionInProgressTule> {
  late StreamSubscription<TransactionStatus> _subscription;
  TransactionStatus? _status;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _subscription = widget.transactionData.status.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
        if (status.state == TransactionState.finalized ||
            status.state == TransactionState.error ||
            status.state == TransactionState.timeout) {
          setState(() {
            _isVisible = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const SizedBox.shrink();
    }

    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    String humanStatus = '';
    final finalAmount = widget.transactionData.amount * -1;

    if (_status!.state == TransactionState.finalized) {
      // This part is for the text, but the tile will start disappearing.
      humanStatus = 'extrinsicValidated'.tr(args: [actionMap['pay']!]);
    } else if (_status!.state == TransactionState.error) {
      humanStatus = errorTransactionMap[_status!.errorMessage] ?? _status!.errorMessage!;
    } else {
      humanStatus = statusStatusMap[_status!.state] ?? 'Unknown status: ${_status!.state}';
    }

    final statusIcon = TransactionStateIcon(_status!.state, size: 21, stroke: 2);

    return FadeAndTranslate(
      visible: _isVisible,
      translate: const Offset(0, -40),
      delay: const Duration(seconds: 2),
      duration: const Duration(milliseconds: 700),
      onCompleted: () async => duniterIndexer.refetch?.call(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colorScheme.primary, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                'Transaction en cours',
                style: scaledTextStyle(fontSize: 19, color: Colors.blueAccent, fontWeight: FontWeight.w400),
              ),
              ListTile(
                key: const Key('transactionInProgress'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                leading: DatapodAvatar(address: widget.transactionData.toAddress, size: 50),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    getShortPubkey(widget.transactionData.toAddress),
                    style: scaledTextStyle(fontSize: 16, fontFamily: 'Monospace'),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        statusIcon,
                        ScaledSizedBox(width: 10),
                        Expanded(
                          child: Text(
                            humanStatus,
                            style: scaledTextStyle(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).textTheme.titleLarge!.color,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    if (widget.transactionData.comment != null && widget.transactionData.comment!.isNotEmpty) ...[
                      ScaledSizedBox(height: 4),
                      Text(
                        widget.transactionData.comment!,
                        style: scaledTextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      finalAmount.toString(),
                      style: scaledTextStyle(fontSize: 15, color: Colors.blue[700], fontWeight: FontWeight.w500),
                    ),
                    ScaledSizedBox(width: 5),
                    UdUnitDisplay(size: scaleSize(15), color: Colors.blue[700]!, fontWeight: FontWeight.w500),
                  ],
                ),
                dense: !isTall,
                isThreeLine: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
