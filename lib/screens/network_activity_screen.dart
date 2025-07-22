import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/transaction_filters.dart';
import 'package:gecko/widgets/transaction_tile.dart';
import 'package:gecko/widgets/history_end_indicator.dart';

class NetworkActivityScreen extends ConsumerStatefulWidget {
  const NetworkActivityScreen({super.key});

  @override
  ConsumerState<NetworkActivityScreen> createState() => _NetworkActivityScreenState();
}

class _NetworkActivityScreenState extends ConsumerState<NetworkActivityScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _newActivityController;
  late Animation<double> _fadeInAnimation;
  bool _showNewActivityIndicator = false;
  bool _isInitialLoad = true;
  DateTime? _lastActivityTimestamp;
  bool _isDisposed = false;
  Timer? _hideIndicatorTimer;
  double _lastScrollOffset = 0.0;
  double _filterTranslationY = 0.0;

  bool get _isAtTop => _scrollController.hasClients && _scrollController.position.pixels <= 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Animation for new activity indicator
    _newActivityController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _newActivityController, curve: Curves.easeInOut));

    // Clear network filters when opening network activity screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              ref.read(networkFiltersProvider.notifier).reset();
            }
          });
        } catch (e) {
          // Silently handle any errors during filter reset
          debugPrint('Network filter reset error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideIndicatorTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Stop any ongoing animation before disposing
    if (_newActivityController.isAnimating) {
      _newActivityController.stop();
    }
    _newActivityController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
      loadMoreNetworkTransactions(ref);
    }

    // Handle filter visibility similar to account activity
    final hasAdvancedFilters = ref.read(networkFiltersProvider).hasActiveFilters;
    final isFilterPanelExpanded = ref.read(networkFilterPanelExpandedProvider);

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

  void _onNewNetworkActivityReceived() {
    if (mounted && !_isDisposed) {
      setState(() {
        _showNewActivityIndicator = true;
      });

      // Only call forward if not disposed
      if (!_isDisposed) {
        _newActivityController.forward();
      }

      // Cancel previous timer if exists
      _hideIndicatorTimer?.cancel();

      // Hide the indicator after 3 seconds
      _hideIndicatorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isDisposed) {
          _hideNewActivityIndicator();
        }
      });
    }
  }

  void _hideNewActivityIndicator() {
    // Cancel the timer since we're hiding manually
    _hideIndicatorTimer?.cancel();

    // Only proceed if not disposed and widget is still mounted
    if (mounted && !_isDisposed) {
      // Check if animation controller is still valid
      if (_newActivityController.isAnimating || _newActivityController.status == AnimationStatus.completed) {
        _newActivityController
            .reverse()
            .then((_) {
              if (mounted && !_isDisposed) {
                setState(() {
                  _showNewActivityIndicator = false;
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
            _showNewActivityIndicator = false;
          });
        }
      }
    }
  }

  void _onIndicatorTapped() {
    // Scroll to top of the list
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);

    // Hide the indicator immediately
    _hideNewActivityIndicator();
  }

  @override
  Widget build(BuildContext context) {
    final networkActivity = ref.watch(adaptiveFilteredNetworkActivityProvider);

    // Check for new network activity using timestamp comparison
    if (!_isInitialLoad && !networkActivity.isLoading && networkActivity.transactions.isNotEmpty) {
      final currentLatestTimestamp = networkActivity.transactions.first.timestamp;

      // Only show notification if NOT initial load AND we have a newer transaction than before
      if (_lastActivityTimestamp != null && currentLatestTimestamp.isAfter(_lastActivityTimestamp!)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            _onNewNetworkActivityReceived();
          }
        });
      }

      // Always update the latest timestamp
      _lastActivityTimestamp = currentLatestTimestamp;
    }

    // Set initial timestamp after first load
    if (_isInitialLoad && !networkActivity.isLoading && networkActivity.transactions.isNotEmpty) {
      _lastActivityTimestamp = networkActivity.transactions.first.timestamp;
      _isInitialLoad = false;
    }

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('networkActivity'.tr()),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with conditional filter handling
            Consumer(
              builder: (context, ref, child) {
                final hasAdvancedFilters = ref.watch(networkFiltersProvider).hasActiveFilters;
                final isFilterPanelExpanded = ref.watch(networkFilterPanelExpandedProvider);
                final keepFiltersVisible = hasAdvancedFilters || isFilterPanelExpanded;

                if (networkActivity.isLoading && networkActivity.transactions.isEmpty) {
                  return Column(
                    children: [
                      // Always show filter in loading state with consistent padding
                      Padding(
                        padding: EdgeInsets.only(top: scaleSize(8)),
                        child: TransactionFilters(mode: FilterMode.network),
                      ),
                      const Expanded(child: Center(child: CircularProgressIndicator())),
                    ],
                  );
                }

                if (networkActivity.error != null && networkActivity.transactions.isEmpty) {
                  return Column(
                    children: [
                      // Always show filter in error state with consistent padding
                      Padding(
                        padding: EdgeInsets.only(top: scaleSize(8)),
                        child: TransactionFilters(mode: FilterMode.network),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: scaleSize(48), color: context.colorScheme.error),
                              ScaledSizedBox(height: 16),
                              Text(
                                networkActivity.error!,
                                style: scaledTextStyle(fontSize: 16, color: context.colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
                              ScaledSizedBox(height: 16),
                              ElevatedButton(onPressed: () => refreshNetworkActivity(ref), child: Text('retry'.tr())),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (networkActivity.transactions.isEmpty) {
                  return Column(
                    children: [
                      // Always show filter in empty state with consistent padding
                      Padding(
                        padding: EdgeInsets.only(top: scaleSize(8)),
                        child: TransactionFilters(mode: FilterMode.network),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: scaleSize(48),
                                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              ScaledSizedBox(height: 16),
                              Text(
                                'noNetworkActivity'.tr(),
                                style: scaledTextStyle(
                                  fontSize: 16,
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Main transaction list with filters
                return Stack(
                  children: [
                    // Transaction list with conditional padding
                    RefreshIndicator(
                      onRefresh: () => refreshNetworkActivity(ref),
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.only(
                          top: keepFiltersVisible
                              ? scaleSize(47) // Less space below filter, compensated by filter top position
                              : scaleSize(47) *
                                    (1.0 + _filterTranslationY).clamp(0.2, 1.0), // Animated when scrolling with minimum
                        ),
                        child: _buildTransactionsList(networkActivity),
                      ),
                    ),

                    // Filter overlay with conditional visibility
                    Positioned(
                      top: scaleSize(8), // More space from appbar
                      left: 0,
                      right: 0,
                      child: Transform.translate(
                        offset: Offset(0, keepFiltersVisible ? 0.0 : _filterTranslationY * 47.0),
                        child: Opacity(
                          opacity: keepFiltersVisible
                              ? 1.0 // Always visible when filtering
                              : (1.0 + _filterTranslationY).clamp(0.0, 1.0), // Animated when not filtering
                          child: TransactionFilters(mode: FilterMode.network),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // New activity indicator
            if (_showNewActivityIndicator)
              Positioned(
                top: 80, // Position below the filter
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
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "newNetworkActivity".tr(),
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
        ),
      ),
    );
  }

  Widget _buildTransactionsList(NetworkActivityState networkActivity) {
    int keyID = 0;
    const double avatarSize = 50;
    bool isMigrationPassed = false;
    List<String> pastDelimiters = [];

    // Check if filters are active to determine history end text
    final hasActiveFilters = ref.read(networkFiltersProvider).hasActiveFilters;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
      children: [
        // Transaction list
        ...networkActivity.transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          keyID++;
          pastDelimiters.add(transaction.dateDelimiter);

          // Check if we need to show date delimiter
          final showDateDelimiter =
              index == 0 ||
              (index > 0 && networkActivity.transactions[index - 1].dateDelimiter != transaction.dateDelimiter);

          // Check if this is migration time and we haven't passed it yet
          if (transaction.isMigrationTime && !isMigrationPassed) {
            isMigrationPassed = true;
          }

          return Column(
            children: [
              if (showDateDelimiter) ...[
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
                  padding: EdgeInsets.symmetric(vertical: scaleSize(6), horizontal: scaleSize(12)),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(scaleSize(8)),
                  ),
                  child: Text(
                    transaction.dateDelimiter,
                    style: scaledTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              TransactionTile(
                key: Key("transaction$keyID"),
                keyID: keyID,
                context: context,
                transaction: transaction,
                avatarSize: avatarSize,
              ),
            ],
          );
        }),

        // Loading indicator or end of history indicator
        if (networkActivity.isLoading && networkActivity.hasNextPage)
          Padding(
            padding: EdgeInsets.all(scaleSize(16)),
            child: const Center(child: CircularProgressIndicator()),
          ),
        if (!networkActivity.hasNextPage) HistoryEndIndicator(isFiltered: hasActiveFilters),
      ],
    );
  }
}
