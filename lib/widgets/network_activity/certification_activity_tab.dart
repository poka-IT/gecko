import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/providers/base_paginated_provider.dart';
import 'package:gecko/providers/network_certifications_provider.dart';
import 'package:gecko/providers/certification_filters_provider.dart';
import 'package:gecko/widgets/network_activity/base_activity_tab.dart';
import 'package:gecko/widgets/network_activity/certification_filters.dart';
import 'package:gecko/widgets/network_activity/certification_tile.dart';

class CertificationActivityTab extends ConsumerWidget {
  const CertificationActivityTab({
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
    return BaseActivityTab<PaginatedState<CertificationDisplayItem>>(
      scrollController: scrollController,
      filterTranslationY: filterTranslationY,
      onNewActivityDetected: onNewActivityDetected,
      activityProvider: adaptiveFilteredNetworkCertificationsProvider,
      filtersProvider: certificationFiltersProvider,
      filterPanelExpandedProvider: certificationFilterPanelExpandedProvider,
      filterWidget: const CertificationFilters(),
      itemBuilder: (certification, keyID) =>
          CertificationTile(key: Key("certification$keyID"), certification: certification),
      refreshCallback: refreshNetworkCertifications,
      loadMoreCallback: loadMoreNetworkCertifications,
      emptyStateIcon: Icons.verified_outlined,
      emptyStateMessage: 'noCertificationActivity',
      getItems: (state) => state.items,
      getLatestTimestamp: (state) => state.items.isNotEmpty ? state.items.first.timestamp : null,
      getDateDelimiter: (certification) => certification.dateDelimiter,
      hasActiveFilters: (filters) => filters.hasActiveFilters,
      useRefreshIndicator: true,
      usePagination: false,
    );
  }
}
