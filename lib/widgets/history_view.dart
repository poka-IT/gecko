import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/migration_data.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/transaction_tile.dart';
import 'package:gecko/widgets/history_end_indicator.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    super.key,
    required this.transactions,
    required this.address,
    required this.migrationFromData,
    required this.migrationToData,
    required this.hasNextPage,
    required this.isLoadingMore,
    this.isFiltered = false,
  });

  final List<TransactionDisplayItem> transactions;
  final String address;
  final MigrationData? migrationFromData;
  final MigrationData? migrationToData;
  final bool hasNextPage;
  final bool isLoadingMore;
  final bool isFiltered;

  /// Merges transactions with migration events at correct chronological positions
  List<TransactionDisplayItem> _getMergedTransactionList() {
    final mergedList = <TransactionDisplayItem>[...transactions];

    // Add migration FROM event (this identity migrated FROM another address to this one)
    if (migrationToData != null) {
      final migrationEvent = TransactionDisplayItem.fromMigrationFromEvent(migrationToData!);
      _insertEventChronologically(mergedList, migrationEvent);
    }

    // Add migration TO event (this identity migrated FROM this address to another one)
    if (migrationFromData != null) {
      final migrationToEvent = TransactionDisplayItem.fromMigrationToEvent(migrationFromData!);
      _insertEventChronologically(mergedList, migrationToEvent);
    }

    return mergedList;
  }

  /// Insert an event at the correct chronological position in the list
  void _insertEventChronologically(List<TransactionDisplayItem> list, TransactionDisplayItem event) {
    int insertIndex = 0;
    for (int i = 0; i < list.length; i++) {
      if (list[i].timestamp.isBefore(event.timestamp)) {
        insertIndex = i;
        break;
      }
      insertIndex = i + 1;
    }
    list.insert(insertIndex, event);
  }

  /// Builds a flat list of widgets (separators, migration markers, transaction tiles)
  /// for use with SliverList.builder in the parent.
  List<Widget> buildItems(BuildContext context) {
    final mergedTransactions = compactConsecutiveUds(_getMergedTransactionList());

    if (mergedTransactions.isEmpty) {
      return [
        Column(
          children: <Widget>[
            ScaledSizedBox(height: 50),
            Text("noTransactionToDisplay".tr(), style: scaledTextStyle(fontSize: 16)),
          ],
        ),
      ];
    }

    final items = <Widget>[];
    int keyID = 0;
    const double avatarSize = 50;
    bool isMigrationPassed = false;
    List<String> pastDelimiters = [];

    for (final transaction in mergedTransactions) {
      keyID++;
      pastDelimiters.add(transaction.dateDelimiter);

      bool isMigrationTime = false;
      if (transaction.isMigrationTime && !isMigrationPassed) {
        isMigrationPassed = true;
        isMigrationTime = true;
      }

      if (isMigrationTime) {
        items.add(
          Padding(
            padding: EdgeInsets.only(top: scaleSize(25), bottom: scaleSize(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image(image: const AssetImage('assets/party.png'), height: scaleSize(31)),
                Text(
                  'blockchainStart'.tr(),
                  style: scaledTextStyle(fontSize: 19, color: context.geckoColors.info, fontWeight: FontWeight.w400),
                ),
                Image(image: const AssetImage('assets/party.png'), height: scaleSize(31)),
              ],
            ),
          ),
        );
      }

      if (pastDelimiters.length == 1 ||
          pastDelimiters.length >= 2 && !(pastDelimiters[pastDelimiters.length - 2] == transaction.dateDelimiter)) {
        items.add(
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                transaction.dateDelimiter,
                style: scaledTextStyle(fontSize: 19, color: context.colorScheme.primary, fontWeight: FontWeight.w300),
              ),
            ),
          ),
        );
      }

      items.add(
        TransactionTile(
          keyID: keyID,
          avatarSize: avatarSize,
          transaction: transaction,
          context: context,
          viewingAddress: address,
        ),
      );
    }

    // Append loading indicator or end indicator
    if (isLoadingMore && hasNextPage) {
      items.add(
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[Loading(size: 30, stroke: 3)]),
      );
    }
    if (!hasNextPage) {
      items.add(HistoryEndIndicator(isFiltered: isFiltered));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    // Fallback: wraps buildItems in a Column for backward compatibility
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(children: buildItems(context)),
      ),
    );
  }
}
