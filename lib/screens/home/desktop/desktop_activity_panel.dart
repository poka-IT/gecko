import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/models/transaction_filters.dart';
import 'package:gecko/providers/certification_filters_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/providers/identity_filters_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/screens/home/desktop/desktop_activity_tabs.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';
import 'package:gecko/widgets/network_activity/certification_filters.dart';
import 'package:gecko/widgets/network_activity/identity_filters.dart';
import 'package:gecko/widgets/transaction_filters.dart';

/// Record type for tile builder callbacks
typedef TileBuilders = ({
  Widget Function(BuildContext, TransactionDisplayItem) tx,
  Widget Function(BuildContext, IdentityDisplayItem) identity,
  Widget Function(BuildContext, CertificationDisplayItem) cert,
});

// ─── Isolated activity feed widget (prevents cascading rebuilds to parent) ───

class DesktopNetworkActivityFeed extends ConsumerWidget {
  final TabController tabController;
  final int activeTabIndex;
  final List<ScrollController> scrollControllers;
  final TileBuilders tileBuilders;

  const DesktopNetworkActivityFeed({
    super.key,
    required this.tabController,
    required this.activeTabIndex,
    required this.scrollControllers,
    required this.tileBuilders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(networkProvider);
    final networkLabel = network.name.toUpperCase();
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == d.ConnectionStatus.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopNetworkActivityControlsBar(
          tabController: tabController,
          networkLabel: networkLabel,
          isConnected: isConnected,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: buildDesktopGlassCard(
            context,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                DesktopFilterBar(activeTabIndex: activeTabIndex),
                const SizedBox(height: 6),
                Expanded(
                  child: IndexedStack(
                    index: activeTabIndex.clamp(0, 2),
                    children: [
                      DesktopTransactionsTab(scrollController: scrollControllers[0], tileBuilder: tileBuilders.tx),
                      DesktopIdentitiesTab(scrollController: scrollControllers[1], tileBuilder: tileBuilders.identity),
                      DesktopCertificationsTab(scrollController: scrollControllers[2], tileBuilder: tileBuilders.cert),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Isolated controls bar -- only rebuilds when totals or connection changes,
/// NOT when transaction/identity/certification lists change.
class DesktopNetworkActivityControlsBar extends ConsumerWidget {
  final TabController tabController;
  final String networkLabel;
  final bool isConnected;

  const DesktopNetworkActivityControlsBar({
    super.key,
    required this.tabController,
    required this.networkLabel,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(networkTotalsProvider);
    // Use .value to keep last known totals during AsyncLoading (avoids flicker to "-")
    final totals = totalsAsync.value;

    String resolveCount(String Function(NetworkTotals) fromTotals) {
      if (totals != null) return fromTotals(totals);
      return '\u2013';
    }

    String formatExactMetric(int totalCount) {
      if (totalCount <= 0) return '\u2013';
      return '$totalCount';
    }

    final txCount = resolveCount((t) => formatExactMetric(t.transactions));
    final identityCount = resolveCount((t) => formatExactMetric(t.identities));
    final certCount = resolveCount((t) => formatExactMetric(t.certifications));

    List<ActivityMetricDetail> identityDetails = [
      ActivityMetricDetail(
        label: 'member'.tr(),
        value: totals != null && totals.memberIdentities > 0 ? '${totals.memberIdentities}' : '\u2013',
      ),
      ActivityMetricDetail(
        label: 'unconfirmed'.tr(),
        value: totals != null && totals.unconfirmedIdentities > 0 ? '${totals.unconfirmedIdentities}' : '\u2013',
      ),
      ActivityMetricDetail(
        label: 'unvalidated'.tr(),
        value: totals != null && totals.unvalidatedIdentities > 0 ? '${totals.unvalidatedIdentities}' : '\u2013',
      ),
      ActivityMetricDetail(
        label: 'identityExpired'.tr(),
        value: totals != null && totals.expiredIdentities > 0 ? '${totals.expiredIdentities}' : '\u2013',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colorScheme.surface.withValues(alpha: 0.96),
            context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'networkActivity'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      networkLabel,
                      style: scaledTextStyle(
                        fontSize: 10.5,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? context.geckoColors.connectionOk.withValues(alpha: 0.10)
                      : context.geckoColors.connectionWarn.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? context.geckoColors.connectionOk : context.geckoColors.connectionWarn,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isConnected ? 'connectedToNode'.tr(args: [networkLabel]) : 'connecting'.tr(),
                      style: scaledTextStyle(
                        fontSize: 10,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final useCompactTabs = screenWidth < 1100;

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: tabController,
                  tabAlignment: TabAlignment.fill,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorAnimation: TabIndicatorAnimation.elastic,
                  dividerColor: Colors.transparent,
                  indicator: UnderlineTabIndicator(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: context.colorScheme.primary.withValues(alpha: 0.95), width: 3),
                    insets: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                  ),
                  indicatorPadding: EdgeInsets.zero,
                  labelColor: context.colorScheme.onSurface,
                  unselectedLabelColor: context.colorScheme.onSurface.withValues(alpha: 0.55),
                  labelStyle: scaledTextStyle(fontSize: useCompactTabs ? 10.5 : 11.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: scaledTextStyle(
                    fontSize: useCompactTabs ? 10.5 : 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  splashBorderRadius: BorderRadius.circular(16),
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                      return context.colorScheme.primary.withValues(alpha: 0.05);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return context.colorScheme.primary.withValues(alpha: 0.08);
                    }
                    return Colors.transparent;
                  }),
                  tabs: [
                    _buildActivityTab(
                      context,
                      Icons.swap_horiz_rounded,
                      'transactions'.tr(),
                      count: txCount,
                      compact: useCompactTabs,
                    ),
                    _buildActivityTab(
                      context,
                      Icons.person_rounded,
                      'identities'.tr(),
                      count: identityCount,
                      compact: useCompactTabs,
                    ),
                    _buildActivityTab(
                      context,
                      Icons.verified_rounded,
                      'certifications'.tr(),
                      count: certCount,
                      compact: useCompactTabs,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: identityDetails
                .map(
                  (detail) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${detail.label}: ',
                          style: scaledTextStyle(
                            fontSize: 10,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          detail.value,
                          style: scaledTextStyle(
                            fontSize: 10,
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(
    BuildContext context,
    IconData icon,
    String label, {
    required String count,
    required bool compact,
  }) {
    final tabChild = SizedBox.expand(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (compact)
                Icon(icon, size: 18)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              const SizedBox(height: 2),
              Text(
                count,
                overflow: TextOverflow.ellipsis,
                style: scaledTextStyle(
                  fontSize: 10,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.46),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Tab(
      height: 58,
      child: compact
          ? Tooltip(
              message: label,
              waitDuration: const Duration(milliseconds: 80),
              preferBelow: true,
              verticalOffset: 24,
              child: tabChild,
            )
          : tabChild,
    );
  }
}

/// Filter bar for desktop activity tabs -- compact inline filter button with badge
class DesktopFilterBar extends ConsumerWidget {
  final int activeTabIndex;

  const DesktopFilterBar({super.key, required this.activeTabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the appropriate filter provider based on active tab
    final activeFilterCount = switch (activeTabIndex) {
      0 => ref.watch(networkFiltersProvider).activeFilterCount,
      1 => ref.watch(identityFiltersProvider).activeFilterCount,
      2 => ref.watch(certificationFiltersProvider).activeFilterCount,
      _ => 0,
    };
    final hasFilters = activeFilterCount > 0;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openFilterModal(context, ref),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: hasFilters
                      ? context.colorScheme.primary.withValues(alpha: 0.08)
                      : context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasFilters
                        ? context.colorScheme.primary.withValues(alpha: 0.2)
                        : context.colorScheme.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: hasFilters
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'filters'.tr(),
                      style: scaledTextStyle(
                        fontSize: 12,
                        color: hasFilters
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: hasFilters ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (hasFilters) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: scaledTextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: hasFilters
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasFilters) ...[
          const SizedBox(width: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _clearFilters(ref),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: context.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colorScheme.error.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  Icons.filter_list_off_rounded,
                  size: 16,
                  color: context.colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openFilterModal(BuildContext context, WidgetRef ref) {
    switch (activeTabIndex) {
      case 0:
        showTransactionFilterSheet(context, FilterMode.network);
        break;
      case 1:
        showIdentityFilterSheet(context);
        break;
      case 2:
        showCertificationFilterSheet(context);
        break;
    }
  }

  void _clearFilters(WidgetRef ref) {
    switch (activeTabIndex) {
      case 0:
        ref.read(networkFiltersProvider.notifier).reset();
        break;
      case 1:
        ref.read(identityFiltersProvider.notifier).reset();
        break;
      case 2:
        ref.read(certificationFiltersProvider.notifier).reset();
        break;
    }
  }
}
