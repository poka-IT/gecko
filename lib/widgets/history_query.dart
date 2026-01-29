import 'dart:async';

import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/widgets/history_filters.dart';
import 'package:gecko/widgets/history_view.dart';
import 'package:gecko/widgets/transaction_in_progress_tile.dart';
import 'package:gecko/models/transaction_in_progress_data.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:visibility_detector/visibility_detector.dart';

const double _filterPadding = 32;

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

  /// Whether the in-progress tile has completed its fade-out animation.
  /// When false and transactionData is present, the matching squid transaction is hidden.
  bool _inProgressTileGone = false;

  /// Timestamp when this screen was created with an in-progress transaction.
  /// Used to anchor the filter so only squid transactions created around this
  /// time are hidden (avoids hiding older transactions to the same address).
  DateTime? _inProgressCreatedAt;

  /// Once the matching squid transaction is identified, its squidId is stored
  /// here so subsequent rebuilds use exact id-based filtering.
  String? _hiddenSquidId;

  // Filter visibility management (only when no filters are active)
  double _filterTranslationY = 0.0; // 0.0 = visible, -1.0 = hidden
  double _lastScrollOffset = 0.0;

  bool get _isAtTop => _scrollController.hasClients && _scrollController.position.pixels <= 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // If no in-progress transaction or it's already complete (cached), skip filtering
    _inProgressTileGone =
        widget.transactionData == null || TransactionStatusCache.isTransactionComplete(widget.transactionData!);

    // Record when this screen was created with an in-progress transaction
    if (!_inProgressTileGone) {
      _inProgressCreatedAt = DateTime.now();
    }

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

    // Only handle filter visibility when:
    // 1. No advanced filters are active
    // 2. Filter panel is not expanded/open
    final hasAdvancedFilters = ref.read(transactionFiltersProvider).hasActiveFilters;
    final isFilterPanelExpanded = ref.read(filterPanelExpandedProvider);

    if (!hasAdvancedFilters && !isFilterPanelExpanded) {
      _handleFilterVisibility();
    }
  }

  void _handleFilterVisibility() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.position.pixels;
    final scrollDelta = currentOffset - _lastScrollOffset;

    // Always show filter when at the top
    if (currentOffset <= 50) {
      if (_filterTranslationY != 0.0) {
        setState(() {
          _filterTranslationY = 0.0;
        });
      }
    } else if (scrollDelta.abs() > 2.0) {
      // Threshold to avoid jitter
      // Sensitivity: how much scroll needed to fully hide/show the filter
      const sensitivity = 0.02;

      // Update translation based on scroll direction
      double newTranslation = _filterTranslationY - (scrollDelta * sensitivity);
      newTranslation = newTranslation.clamp(-1.0, 0.0);

      if ((newTranslation - _filterTranslationY).abs() > 0.01) {
        setState(() {
          _filterTranslationY = newTranslation;
        });
      }
    }

    _lastScrollOffset = currentOffset;
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

  void _onInProgressTileAnimationComplete() {
    if (mounted && !_isDisposed) {
      setState(() {
        _inProgressTileGone = true;
      });
    }
  }

  /// Checks if a squid transaction matches the in-progress transaction.
  bool _isMatchingInProgressTransaction(TransactionDisplayItem tx) {
    if (widget.transactionData == null || _inProgressCreatedAt == null) return false;
    final inProgress = widget.transactionData!;

    // Only match outgoing transfers
    if (tx.isReceived || tx.type != TransactionType.transfer) return false;

    // Match by recipient address
    if (tx.address != inProgress.toAddress) return false;

    // Match by comment
    final txComment = tx.comment ?? '';
    if (txComment != inProgress.comment) return false;

    // Only match squid transactions whose block timestamp is close to when
    // this in-progress tile was created. The block timestamp is typically
    // 6-30s after tx submission. This prevents hiding older transactions
    // to the same address/comment from a previous payment.
    final diff = tx.timestamp.difference(_inProgressCreatedAt!);
    if (diff.inSeconds < -5 || diff.inMinutes > 3) return false;

    return true;
  }

  /// Filters out the squid transaction that matches the in-progress tile,
  /// so they are never shown simultaneously.
  ///
  /// Uses a 2-step approach:
  /// 1. First match: heuristic (address + comment + time window) to identify
  ///    the squid transaction, then memorize its squidId.
  /// 2. Subsequent rebuilds: filter by exact squidId for reliable deduplication.
  List<TransactionDisplayItem> _filterInProgressDuplicate(List<TransactionDisplayItem> transactions) {
    if (_inProgressTileGone || widget.transactionData == null) {
      _hiddenSquidId = null;
      return transactions;
    }

    // If we already identified the squidId, filter by exact match
    if (_hiddenSquidId != null) {
      return transactions.where((tx) => tx.squidId != _hiddenSquidId).toList();
    }

    // First identification: heuristic match + memorize squidId
    bool found = false;
    return transactions.where((tx) {
      if (found) return true;
      if (_isMatchingInProgressTransaction(tx)) {
        _hiddenSquidId = tx.squidId;
        found = true;
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEmptyStateView(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: scaleSize(80)),
            // Large image representing empty wallet
            Container(
              padding: EdgeInsets.all(scaleSize(16)),
              child: Image.asset(
                context.isDarkTheme ? 'assets/empty_wallet_dark.png' : 'assets/empty_wallet_light.png',
                width: 260,
                fit: BoxFit.contain,
              ),
            ),
            ScaledSizedBox(height: 4),
            // Main message
            Text(
              "noDataToDisplay".tr(),
              style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: context.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: scaleSize(120)),
          ],
        ),
      ),
    );
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

    // Use the existing filtered state that applies filters client-side (preserves pagination)
    final historyState = ref.watch(filteredTransactionHistoryProvider(widget.address));
    final migrationFromDataAsync = ref.watch(migrationFromDataProvider(widget.address));
    final migrationToDataAsync = ref.watch(migrationToDataProvider(widget.address));

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
                    TransactionInProgressTule(
                      transactionData: widget.transactionData!,
                      viewingAddress: widget.address,
                      onAnimationComplete: _onInProgressTileAnimationComplete,
                    ),
                  ScaledSizedBox(height: 50),
                  Center(
                    child: Text(
                      "noNetworkNoHistory".tr(),
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),

            // Handle empty state
            if (!historyState.isLoading && historyState.transactions.isEmpty && historyState.error == null)
              Consumer(
                builder: (context, ref, child) {
                  final hasAdvancedFilters = ref.watch(transactionFiltersProvider).hasActiveFilters;
                  final isFilterPanelExpanded = ref.watch(filterPanelExpandedProvider);
                  final keepFiltersVisible = hasAdvancedFilters || isFilterPanelExpanded;

                  if (keepFiltersVisible) {
                    // Show filters + empty message when filtering
                    return Expanded(
                      child: Stack(
                        children: [
                          // Empty state content with padding for filters
                          Padding(
                            padding: EdgeInsets.only(top: scaleSize(_filterPadding)),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  if (widget.transactionData != null)
                                    TransactionInProgressTule(
                                      transactionData: widget.transactionData!,
                                      viewingAddress: widget.address,
                                      onAnimationComplete: _onInProgressTileAnimationComplete,
                                    ),
                                  ScaledSizedBox(height: 40),
                                  _buildEmptyStateView(context),
                                ],
                              ),
                            ),
                          ),

                          // Filter overlay - always visible when filtering
                          Positioned(
                            top: scaleSize(8),
                            left: 0,
                            right: 0,
                            child: TransactionFilter(
                              key: ValueKey('filter_${widget.address}'),
                              address: widget.address,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show only empty message when no filters (hide filters)
                  return Column(
                    children: <Widget>[
                      if (widget.transactionData != null)
                        TransactionInProgressTule(
                          transactionData: widget.transactionData!,
                          viewingAddress: widget.address,
                          onAnimationComplete: _onInProgressTileAnimationComplete,
                        ),
                      ScaledSizedBox(height: 40),
                      _buildEmptyStateView(context),
                    ],
                  );
                },
              ),

            // Handle success state with transactions
            if (historyState.transactions.isNotEmpty)
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final hasAdvancedFilters = ref.watch(transactionFiltersProvider).hasActiveFilters;
                    final isFilterPanelExpanded = ref.watch(filterPanelExpandedProvider);

                    // Keep filters visible if advanced filters are active OR panel is expanded
                    final keepFiltersVisible = hasAdvancedFilters || isFilterPanelExpanded;

                    return Stack(
                      children: [
                        // Main transaction list with conditional padding
                        RefreshIndicator(
                          color: context.colorScheme.primary,
                          onRefresh: () async {
                            await refreshTransactionHistory(ref, widget.address);
                          },
                          child: AnimatedPadding(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.only(
                              top: keepFiltersVisible
                                  ? scaleSize(_filterPadding) // Reduced padding between filter and list
                                  : scaleSize(_filterPadding) *
                                        (1.0 + _filterTranslationY).clamp(0.0, 1.0), // Animated when not filtering
                            ),
                            child: ListView(
                              key: keyListTransactions,
                              controller: _scrollController,
                              children: <Widget>[
                                if (widget.transactionData != null)
                                  VisibilityDetector(
                                    key: const Key('transaction-in-progress-tile'),
                                    onVisibilityChanged: _onTransactionInProgressVisibilityChanged,
                                    child: TransactionInProgressTule(
                                      transactionData: widget.transactionData!,
                                      viewingAddress: widget.address,
                                      onAnimationComplete: _onInProgressTileAnimationComplete,
                                    ),
                                  ),

                                HistoryView(
                                  transactions: _filterInProgressDuplicate(historyState.transactions),
                                  address: widget.address,
                                  migrationFromData: migrationFromDataAsync.when(
                                    data: (migrationData) => migrationData,
                                    loading: () => null,
                                    error: (error, stackTrace) => null,
                                  ),
                                  migrationToData: migrationToDataAsync.when(
                                    data: (migrationData) => migrationData,
                                    loading: () => null,
                                    error: (error, stackTrace) => null,
                                  ),
                                  hasNextPage: historyState.hasNextPage,
                                  isLoadingMore: historyState.isLoading,
                                  isFiltered: hasAdvancedFilters,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Filter overlay with conditional visibility
                        Positioned(
                          top: scaleSize(8),
                          left: 0,
                          right: 0,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              keepFiltersVisible ? 0.0 : _filterTranslationY * 18.0, // Match the reduced padding
                            ),
                            child: Opacity(
                              opacity: keepFiltersVisible
                                  ? 1.0 // Always visible when filtering
                                  : (1.0 + _filterTranslationY).clamp(0.0, 1.0), // Animated when not filtering
                              child: TransactionFilter(
                                key: ValueKey('filter_${widget.address}'),
                                address: widget.address,
                              ), // Remove the wrapper container
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
