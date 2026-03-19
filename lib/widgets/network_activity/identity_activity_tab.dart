import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/providers/base_paginated_provider.dart';
import 'package:gecko/providers/network_identities_provider.dart';
import 'package:gecko/providers/identity_filters_provider.dart';
import 'package:gecko/widgets/network_activity/base_activity_tab.dart';
import 'package:gecko/widgets/network_activity/identity_filters.dart';
import 'package:gecko/widgets/network_activity/identity_tile.dart';

class IdentityActivityTab extends ConsumerWidget {
  const IdentityActivityTab({
    super.key,
    required this.scrollController,
    required this.filterTranslationY,
    this.onNewActivityDetected,
  });

  final ScrollController scrollController;
  final double filterTranslationY;
  final VoidCallback? onNewActivityDetected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseActivityTab<PaginatedState<IdentityDisplayItem>>(
      scrollController: scrollController,
      filterTranslationY: filterTranslationY,
      onNewActivityDetected: onNewActivityDetected,
      activityProvider: adaptiveFilteredNetworkIdentitiesProvider,
      filtersProvider: identityFiltersProvider,
      filterPanelExpandedProvider: identityFilterPanelExpandedProvider,
      filterWidget: const IdentityFilters(),
      itemBuilder: (identity, keyID) => IdentityTile(key: Key("identity$keyID"), identity: identity),
      refreshCallback: refreshNetworkIdentities,
      loadMoreCallback: loadMoreNetworkIdentities,
      emptyStateIcon: Icons.person_outline,
      emptyStateMessage: 'noIdentityActivity',
      getItems: (state) => state.items,
      getLatestTimestamp: (state) => state.items.isNotEmpty ? state.items.first.timestamp : null,
      getDateDelimiter: (identity) => identity.dateDelimiter,
      hasActiveFilters: (filters) => filters.hasActiveFilters,
      useRefreshIndicator: true,
      usePagination: false,
    );
  }
}
