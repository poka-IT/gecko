import 'dart:async';

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
import 'package:visibility_detector/visibility_detector.dart';

class HistoryQuery extends ConsumerStatefulWidget {
  const HistoryQuery({super.key, required this.address, this.transactionData});
  final String address;
  final TransactionInProgressData? transactionData;

  @override
  ConsumerState<HistoryQuery> createState() => _HistoryQueryState();
}

class _HistoryQueryState extends ConsumerState<HistoryQuery> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _newTransactionController;
  late Animation<double> _fadeInAnimation;
  bool _showNewTransactionIndicator = false;
  bool _isInitialLoad = true;
  DateTime? _lastTransactionTimestamp;
  bool _isTransactionInProgressVisible = false;
  bool _isDisposed = false;
  Timer? _hideIndicatorTimer;

  bool get _isAtTop => _scrollController.hasClients && _scrollController.position.pixels <= 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Animation for new transaction indicator
    _newTransactionController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _newTransactionController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideIndicatorTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Stop any ongoing animation before disposing
    if (_newTransactionController.isAnimating) {
      _newTransactionController.stop();
    }
    _newTransactionController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      loadMoreTransactions(ref, widget.address);
    }
  }

  void _onNewTransactionReceived() {
    // Don't show indicator if transaction in progress tile is visible
    if (mounted && !_isDisposed && !_isTransactionInProgressVisible) {
      setState(() {
        _showNewTransactionIndicator = true;
      });

      // Only call forward if not disposed
      if (!_isDisposed) {
        _newTransactionController.forward();
      }

      // Cancel previous timer if exists
      _hideIndicatorTimer?.cancel();

      // Hide the indicator after 3 seconds
      _hideIndicatorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isDisposed) {
          _hideNewTransactionIndicator();
        }
      });
    }
  }

  void _hideNewTransactionIndicator() {
    // Cancel the timer since we're hiding manually
    _hideIndicatorTimer?.cancel();

    // Only proceed if not disposed and widget is still mounted
    if (mounted && !_isDisposed) {
      // Check if animation controller is still valid
      if (_newTransactionController.isAnimating || _newTransactionController.status == AnimationStatus.completed) {
        _newTransactionController
            .reverse()
            .then((_) {
              if (mounted && !_isDisposed) {
                setState(() {
                  _showNewTransactionIndicator = false;
                });
              }
            })
            .catchError((error) {
              // Ignore errors from disposed animation controller
            });
      } else {
        // If animation is not running, just hide immediately
        if (mounted && !_isDisposed) {
          setState(() {
            _showNewTransactionIndicator = false;
          });
        }
      }
    }
  }

  void _onIndicatorTapped() {
    // Scroll to top of the list
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);

    // Hide the indicator immediately
    _hideNewTransactionIndicator();
  }

  void _onTransactionInProgressVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.1; // Consider visible if more than 10% is visible

    if (_isTransactionInProgressVisible != isVisible) {
      // Only call setState if widget is still mounted and not disposed
      if (mounted && !_isDisposed) {
        setState(() {
          _isTransactionInProgressVisible = isVisible;
        });
      }

      // If transaction in progress becomes visible and we're showing the indicator, hide it
      if (isVisible && _showNewTransactionIndicator) {
        _hideNewTransactionIndicator();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for scroll to top events
    ref.listen<int>(scrollToTopProvider, (previous, next) {
      if (previous != next && _scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });

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

    // Use filtered state for display
    final historyState = ref.watch(transactionHistoryProvider(widget.address));
    final previousAddressAsync = ref.watch(previousAddressProvider(widget.address));

    // Use COMBINED state for new transaction detection (always includes all data, not affected by toggle)
    final rawHistoryState = ref.watch(combinedHistoryProvider(widget.address));

    // Always initialize/update timestamp with RAW data (including UDs) to prevent false notifications
    if (!rawHistoryState.isLoading && rawHistoryState.transactions.isNotEmpty) {
      final currentLatestTimestamp = rawHistoryState.transactions.first.timestamp;

      // Only show notification if NOT initial load AND we have a newer transaction than before
      if (!_isInitialLoad &&
          _lastTransactionTimestamp != null &&
          currentLatestTimestamp.isAfter(_lastTransactionTimestamp!)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            _onNewTransactionReceived();
          }
        });
      }

      // Always update the latest timestamp (including on initial load)
      _lastTransactionTimestamp = currentLatestTimestamp;
    }

    // Mark initial load as complete when RAW data is loaded (prevents logic conflicts)
    if (_isInitialLoad && !rawHistoryState.isLoading) {
      _isInitialLoad = false;
    }

    // Initialize transaction in progress visibility based on whether we have transaction data
    // If no transaction data, then the tile doesn't exist, so it's not visible
    if (widget.transactionData == null && _isTransactionInProgressVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isTransactionInProgressVisible = false;
          });
        }
      });
    }

    return Stack(
      children: [
        Column(
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
                  if (widget.transactionData != null)
                    TransactionInProgressTule(transactionData: widget.transactionData!),
                  ScaledSizedBox(height: 50),
                  Text("noNetworkNoHistory".tr(), textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 17)),
                ],
              ),

            // Handle empty state
            if (!historyState.isLoading && historyState.transactions.isEmpty && historyState.error == null)
              Column(
                children: <Widget>[
                  if (widget.transactionData != null)
                    TransactionInProgressTule(transactionData: widget.transactionData!),
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
                    await refreshTransactionHistory(ref, widget.address);
                  },
                  child: ListView(
                    key: keyListTransactions,
                    controller: _scrollController,
                    children: <Widget>[
                      if (widget.transactionData != null)
                        VisibilityDetector(
                          key: const Key('transaction-in-progress-tile'),
                          onVisibilityChanged: _onTransactionInProgressVisibilityChanged,
                          child: TransactionInProgressTule(transactionData: widget.transactionData!),
                        ),

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
        ),

        // New transaction indicator
        if (_showNewTransactionIndicator)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: GestureDetector(
                onTap: _onIndicatorTapped,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "newTransactionReceived".tr(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      if (!_isAtTop) Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
