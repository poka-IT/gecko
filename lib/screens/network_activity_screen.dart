import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/transaction_tile.dart';

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
    final networkActivity = ref.watch(networkActivityProvider);

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
            networkActivity.isLoading && networkActivity.transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => refreshNetworkActivity(ref),
                    child: networkActivity.error != null && networkActivity.transactions.isEmpty
                        ? Center(
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
                          )
                        : networkActivity.transactions.isEmpty
                        ? Center(
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
                          )
                        : _buildTransactionsList(networkActivity),
                  ),
            // New activity indicator
            if (_showNewActivityIndicator)
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
    if (networkActivity.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: scaleSize(48), color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
            ScaledSizedBox(height: 16),
            Text(
              'noNetworkActivity'.tr(),
              style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    int keyID = 0;
    const double avatarSize = 50;
    bool isMigrationPassed = false;
    List<String> pastDelimiters = [];

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
      itemCount: networkActivity.transactions.length + (networkActivity.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == networkActivity.transactions.length) {
          // Loading indicator at the bottom
          return Padding(
            padding: EdgeInsets.all(scaleSize(16)),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = networkActivity.transactions[index];
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
      },
    );
  }
}
