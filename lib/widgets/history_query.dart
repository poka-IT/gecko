import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/widgets/history_view.dart';
import 'package:gecko/widgets/transaction_in_progress_tile.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';

class HistoryQuery extends ConsumerStatefulWidget {
  const HistoryQuery({super.key, required this.address, this.transactionData});
  final String address;
  final TransactionInProgressData? transactionData;

  @override
  ConsumerState<HistoryQuery> createState() => _HistoryQueryState();
}

class _HistoryQueryState extends ConsumerState<HistoryQuery> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      final historyNotifier = ref.read(transactionHistoryProvider(widget.address).notifier);
      historyNotifier.loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have network connection
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isNetworkAvailable = connectionStatus == d.ConnectionStatus.connected;

    if (!isNetworkAvailable) {
      return Column(
        children: <Widget>[
          ScaledSizedBox(height: 50),
          Text("noNetworkNoHistory".tr(), textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 17)),
        ],
      );
    }

    final historyState = ref.watch(transactionHistoryProvider(widget.address));
    final previousAddressAsync = ref.watch(previousAddressProvider(widget.address));

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        // Handle loading state
        if (historyState.isLoading && historyState.transactions.isEmpty)
          Center(child: CircularProgressIndicator(color: context.colorScheme.primary)),

        // Handle error state
        if (historyState.error != null)
          Column(
            children: <Widget>[
              if (widget.transactionData != null) TransactionInProgressTule(transactionData: widget.transactionData!),
              ScaledSizedBox(height: 50),
              Text("noNetworkNoHistory".tr(), textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 17)),
            ],
          ),

        // Handle empty state
        if (!historyState.isLoading && historyState.transactions.isEmpty && historyState.error == null)
          Column(
            children: <Widget>[
              if (widget.transactionData != null) TransactionInProgressTule(transactionData: widget.transactionData!),
              ScaledSizedBox(height: 50),
              Text("noDataToDisplay".tr(), style: scaledTextStyle(fontSize: 17)),
            ],
          ),

        // Handle success state with transactions
        if (historyState.transactions.isNotEmpty)
          Expanded(
            child: RefreshIndicator(
              color: context.colorScheme.primary,
              onRefresh: () async {
                await ref.read(transactionHistoryProvider(widget.address).notifier).refresh();
              },
              child: ListView(
                key: keyListTransactions,
                controller: _scrollController,
                children: <Widget>[
                  if (widget.transactionData != null)
                    TransactionInProgressTule(transactionData: widget.transactionData!),
                  HistoryView(
                    transactions: historyState.transactions,
                    address: widget.address,
                    previousAddress: previousAddressAsync.when(
                      data: (address) => address,
                      loading: () => null,
                      error: (error, stackTrace) => null,
                    ),
                    hasNextPage: historyState.hasNextPage,
                    isLoadingMore: historyState.isLoading,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
