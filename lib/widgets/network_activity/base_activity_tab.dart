import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/widgets/history_end_indicator.dart';
import 'package:durt2/durt2.dart' as d;

const double filterPadding = 8;

/// Base widget for activity tabs that handles common functionality like
/// loading states, error states, empty states, and filter positioning
class BaseActivityTab<T> extends ConsumerStatefulWidget {
  const BaseActivityTab({
    super.key,
    required this.scrollController,
    required this.filterTranslationY,
    this.onNewActivityDetected,
    required this.activityProvider,
    required this.filtersProvider,
    required this.filterPanelExpandedProvider,
    required this.filterWidget,
    required this.itemBuilder,
    required this.refreshCallback,
    required this.loadMoreCallback,
    required this.emptyStateIcon,
    required this.emptyStateMessage,
    required this.getItems,
    required this.getLatestTimestamp,
    required this.getDateDelimiter,
    required this.hasActiveFilters,
    this.useRefreshIndicator = true,
    this.usePagination = true,
  });

  final ScrollController scrollController;
  final double filterTranslationY;
  final VoidCallback? onNewActivityDetected;
  final ProviderListenable<T> activityProvider;
  final ProviderListenable<dynamic> filtersProvider;
  final ProviderListenable<bool> filterPanelExpandedProvider;
  final Widget filterWidget;
  final Widget Function(dynamic item, int keyID) itemBuilder;
  final Future<void> Function(WidgetRef ref) refreshCallback;
  final Future<void> Function(WidgetRef ref)? loadMoreCallback;
  final IconData emptyStateIcon;
  final String emptyStateMessage;
  final List<dynamic> Function(T state) getItems;
  final DateTime? Function(T state) getLatestTimestamp;
  final String Function(dynamic item) getDateDelimiter;
  final bool Function(dynamic filters) hasActiveFilters;
  final bool useRefreshIndicator;
  final bool usePagination;

  @override
  ConsumerState<BaseActivityTab<T>> createState() => _BaseActivityTabState<T>();
}

class _BaseActivityTabState<T> extends ConsumerState<BaseActivityTab<T>> {
  bool _isInitialLoad = true;
  DateTime? _lastActivityTimestamp;
  d.ConnectionStatus? _lastConnectionStatus;

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(widget.activityProvider);
    final filters = ref.watch(widget.filtersProvider);
    final isFilterPanelExpanded = ref.watch(widget.filterPanelExpandedProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    final items = widget.getItems(activityState);
    final isLoading = _getIsLoading(activityState);
    final error = _getError(activityState);
    final hasNextPage = _getHasNextPage(activityState);

    // Watch for connection status changes and auto-refresh when connected
    if (_lastConnectionStatus != null &&
        _lastConnectionStatus != d.ConnectionStatus.connected &&
        connectionStatus == d.ConnectionStatus.connected) {
      // Connection restored, trigger refresh
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.refreshCallback(ref);
        }
      });
    }
    _lastConnectionStatus = connectionStatus;

    // Check for new activity using timestamp comparison
    if (!_isInitialLoad && !isLoading && items.isNotEmpty) {
      final currentLatestTimestamp = widget.getLatestTimestamp(activityState);

      // Only show notification if NOT initial load AND we have newer activity than before
      if (_lastActivityTimestamp != null &&
          currentLatestTimestamp != null &&
          currentLatestTimestamp.isAfter(_lastActivityTimestamp!)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onNewActivityDetected?.call();
          }
        });
      }

      // Always update the latest timestamp
      if (currentLatestTimestamp != null) {
        _lastActivityTimestamp = currentLatestTimestamp;
      }
    }

    // Set initial timestamp after first load
    if (_isInitialLoad && !isLoading && items.isNotEmpty) {
      final currentLatestTimestamp = widget.getLatestTimestamp(activityState);
      if (currentLatestTimestamp != null) {
        _lastActivityTimestamp = currentLatestTimestamp;
      }
      _isInitialLoad = false;
    }

    // Determine if filters should stay visible
    final bool keepFiltersVisible = isFilterPanelExpanded || widget.hasActiveFilters(filters);

    // Handle loading state
    if (isLoading && items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: scaleSize(filterPadding)),
            child: widget.filterWidget,
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    // Handle error state
    if (error != null && items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: scaleSize(filterPadding)),
            child: widget.filterWidget,
          ),
          Expanded(child: Center(child: _buildErrorState(context, connectionStatus, error))),
        ],
      );
    }

    // Handle empty state
    if (items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: scaleSize(filterPadding)),
            child: widget.filterWidget,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.emptyStateIcon,
                    size: scaleSize(48),
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  ScaledSizedBox(height: 16),
                  Text(
                    widget.emptyStateMessage.tr(),
                    style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Main content with items
    return SafeArea(
      child: Stack(
        children: [
          // Items list with conditional padding
          widget.useRefreshIndicator
              ? RefreshIndicator(
                  onRefresh: () => widget.refreshCallback(ref),
                  child: _buildItemsList(
                    context,
                    ref,
                    activityState,
                    items,
                    keepFiltersVisible,
                    isLoading,
                    hasNextPage,
                  ),
                )
              : _buildItemsList(context, ref, activityState, items, keepFiltersVisible, isLoading, hasNextPage),

          // Filter overlay with conditional visibility
          Positioned(
            top: scaleSize(filterPadding),
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: Offset(0, keepFiltersVisible ? 0.0 : widget.filterTranslationY * 47.0),
              child: Opacity(
                opacity: keepFiltersVisible ? 1.0 : (1.0 + widget.filterTranslationY).clamp(0.0, 1.0),
                child: widget.filterWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    WidgetRef ref,
    T activityState,
    List<dynamic> items,
    bool keepFiltersVisible,
    bool isLoading,
    bool hasNextPage,
  ) {
    int keyID = 0;

    if (widget.usePagination && widget.loadMoreCallback != null) {
      // Use ListView.builder for pagination
      return ListView.builder(
        controller: widget.scrollController,
        padding: EdgeInsets.only(
          top: keepFiltersVisible ? scaleSize(70) : scaleSize(70) * (1.0 + widget.filterTranslationY).clamp(0.2, 1.0),
        ),
        itemCount: items.length + (hasNextPage ? 1 : 1),
        itemBuilder: (context, index) {
          keyID++;

          if (index == items.length) {
            // Show loading indicator or end indicator
            if (hasNextPage) {
              if (!isLoading) {
                // Trigger loading more when reaching the end
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.loadMoreCallback!(ref);
                });
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              // End of list indicator
              return const HistoryEndIndicator();
            }
          }

          final item = items[index];
          final showDateDelimiter =
              index == 0 || (index > 0 && widget.getDateDelimiter(items[index - 1]) != widget.getDateDelimiter(item));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateDelimiter)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(8)),
                  child: Text(
                    widget.getDateDelimiter(item),
                    style: scaledTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              widget.itemBuilder(item, keyID),
            ],
          );
        },
      );
    } else {
      // Use regular ListView for non-paginated content
      return AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.only(
          top: keepFiltersVisible ? scaleSize(70) : scaleSize(70) * (1.0 + widget.filterTranslationY).clamp(0.2, 1.0),
        ),
        child: ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
          children: [
            // Items list
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              keyID++;

              // Check if we need to show date delimiter
              final showDateDelimiter =
                  index == 0 ||
                  (index > 0 && widget.getDateDelimiter(items[index - 1]) != widget.getDateDelimiter(item));

              return Column(
                children: [
                  if (showDateDelimiter)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(8)),
                      child: Text(
                        widget.getDateDelimiter(item),
                        style: scaledTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  widget.itemBuilder(item, keyID),
                ],
              );
            }),

            // Loading indicator or end of history indicator
            if (isLoading && hasNextPage)
              Padding(
                padding: EdgeInsets.all(scaleSize(16)),
                child: const Center(child: CircularProgressIndicator()),
              ),
            if (!hasNextPage)
              HistoryEndIndicator(isFiltered: widget.hasActiveFilters(ref.read(widget.filtersProvider))),
          ],
        ),
      );
    }
  }

  Widget _buildErrorState(BuildContext context, d.ConnectionStatus connectionStatus, String? error) {
    IconData errorIcon;
    String errorMessage;
    String? statusMessage;
    bool showRetryButton = true;

    // Determine error type based on connection status and error message
    if (connectionStatus == d.ConnectionStatus.disconnected ||
        connectionStatus == d.ConnectionStatus.error ||
        (error != null &&
            (error.contains('No network connection') ||
                error.contains('NetworkError') ||
                error.contains('Connection failed')))) {
      errorIcon = Icons.signal_wifi_off;
      errorMessage = 'youAreOffline'.tr();
      statusMessage = connectionStatus == d.ConnectionStatus.connecting
          ? 'connecting'.tr()
          : 'networkConnectionError'.tr();
    } else if (connectionStatus == d.ConnectionStatus.connecting) {
      errorIcon = Icons.wifi_find;
      errorMessage = 'connecting'.tr();
      statusMessage = null;
      showRetryButton = false;
    } else {
      errorIcon = Icons.error_outline;
      errorMessage = error ?? 'anErrorOccurred'.tr();
      statusMessage = null;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error icon
          Icon(
            errorIcon,
            size: scaleSize(64),
            color: connectionStatus == d.ConnectionStatus.connecting
                ? context.colorScheme.primary.withValues(alpha: 0.7)
                : context.colorScheme.error.withValues(alpha: 0.8),
          ),
          ScaledSizedBox(height: 24),

          // Main error message
          Text(
            errorMessage,
            style: scaledTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: connectionStatus == d.ConnectionStatus.connecting
                  ? context.colorScheme.onSurface.withValues(alpha: 0.8)
                  : context.colorScheme.error.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),

          // Optional status message
          if (statusMessage != null) ...[
            ScaledSizedBox(height: 8),
            Text(
              statusMessage,
              style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],

          // Retry button (only if not connecting)
          if (showRetryButton) ...[
            ScaledSizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => widget.refreshCallback(ref),
              icon: Icon(Icons.refresh, size: scaleSize(18)),
              label: Text('retry'.tr()),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(24), vertical: scaleSize(12)),
              ),
            ),
          ],

          // Show connecting indicator
          if (connectionStatus == d.ConnectionStatus.connecting) ...[
            ScaledSizedBox(height: 24),
            SizedBox(
              width: scaleSize(24),
              height: scaleSize(24),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods to extract common properties from different state types
  bool _getIsLoading(T state) {
    if (state is Map && state.containsKey('isLoading')) {
      return state['isLoading'] as bool;
    }
    // Try to access isLoading property via reflection/duck typing
    try {
      return (state as dynamic).isLoading as bool;
    } catch (e) {
      return false;
    }
  }

  String? _getError(T state) {
    if (state is Map && state.containsKey('error')) {
      return state['error'] as String?;
    }
    try {
      return (state as dynamic).error as String?;
    } catch (e) {
      return null;
    }
  }

  bool _getHasNextPage(T state) {
    if (state is Map && state.containsKey('hasNextPage')) {
      return state['hasNextPage'] as bool;
    }
    try {
      return (state as dynamic).hasNextPage as bool;
    } catch (e) {
      return false;
    }
  }
}
