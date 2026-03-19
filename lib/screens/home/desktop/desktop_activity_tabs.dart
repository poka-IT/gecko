import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/certification_display_item.dart';
import 'package:gecko/models/identity_display_item.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_display_item.dart';
import 'package:gecko/providers/certification_filters_provider.dart';
import 'package:gecko/providers/identity_filters_provider.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/network_certifications_provider.dart';
import 'package:gecko/providers/network_identities_provider.dart';
import 'package:gecko/providers/transaction_filters_provider.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';

// ─── Isolated Tab Widgets (rebuild only when their own provider changes) ───

class DesktopTransactionsTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Widget Function(BuildContext, TransactionDisplayItem) tileBuilder;

  const DesktopTransactionsTab({super.key, required this.scrollController, required this.tileBuilder});

  @override
  ConsumerState<DesktopTransactionsTab> createState() => _DesktopTransactionsTabState();
}

class _DesktopTransactionsTabState extends ConsumerState<DesktopTransactionsTab> {
  Set<String> _knownIds = {};
  Set<String> _newIds = {};
  int _newCount = 0;
  DateTime? _newestKnownTimestamp;

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(adaptiveFilteredNetworkActivityProvider);
    final items = activityState.items;

    if (items.isEmpty) {
      final hasFilters = ref.watch(networkFiltersProvider).hasActiveFilters;
      return buildEmptyTabState(
        context,
        Icons.swap_horiz,
        hasFilters ? 'noResultsForFilter'.tr() : 'noNetworkActivity'.tr(),
      );
    }

    final currentIds = items.map((tx) => tx.squidId ?? '${tx.timestamp.millisecondsSinceEpoch}').toSet();
    if (_knownIds.isNotEmpty) {
      // Only count items newer than the previously newest known item (not pagination)
      final newItems = currentIds.difference(_knownIds);
      _newIds = {};
      if (newItems.isNotEmpty && _newestKnownTimestamp != null) {
        for (final tx in items) {
          final txId = tx.squidId ?? '${tx.timestamp.millisecondsSinceEpoch}';
          if (newItems.contains(txId) && tx.timestamp.isAfter(_newestKnownTimestamp!)) {
            _newIds.add(txId);
          }
        }
      }
      _newCount = _newIds.length;
    }
    if (items.isNotEmpty) {
      _newestKnownTimestamp = items.first.timestamp;
    }
    _knownIds = currentIds;

    return ActivityListWithToast(
      newCount: _newCount,
      icon: Icons.swap_horiz_rounded,
      labelKey: 'transactions',
      child: ListView.separated(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
        itemBuilder: (context, index) {
          final tx = items[index];
          final txId = tx.squidId ?? '${tx.timestamp.millisecondsSinceEpoch}';
          final isNew = _newIds.contains(txId);
          final child = widget.tileBuilder(context, tx);
          return isNew ? NewItemHighlight(child: child) : child;
        },
      ),
    );
  }
}

class DesktopIdentitiesTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Widget Function(BuildContext, IdentityDisplayItem) tileBuilder;

  const DesktopIdentitiesTab({super.key, required this.scrollController, required this.tileBuilder});

  @override
  ConsumerState<DesktopIdentitiesTab> createState() => _DesktopIdentitiesTabState();
}

class _DesktopIdentitiesTabState extends ConsumerState<DesktopIdentitiesTab> {
  Set<String> _knownIds = {};
  Set<String> _newIds = {};
  int _newCount = 0;
  DateTime? _newestKnownTimestamp;

  @override
  Widget build(BuildContext context) {
    final identitiesState = ref.watch(adaptiveFilteredNetworkIdentitiesProvider);
    final items = identitiesState.items;

    if (items.isEmpty) {
      final hasFilters = ref.watch(identityFiltersProvider).hasActiveFilters;
      return buildEmptyTabState(
        context,
        Icons.person_outline,
        hasFilters ? 'noResultsForFilter'.tr() : 'noIdentityActivity'.tr(),
      );
    }

    final currentIds = items.map((i) => '${i.accountId ?? i.name}_${i.timestamp.millisecondsSinceEpoch}').toSet();
    if (_knownIds.isNotEmpty) {
      final newItems = currentIds.difference(_knownIds);
      _newIds = {};
      if (newItems.isNotEmpty && _newestKnownTimestamp != null) {
        for (final identity in items) {
          final identityId = '${identity.accountId ?? identity.name}_${identity.timestamp.millisecondsSinceEpoch}';
          if (newItems.contains(identityId) && identity.timestamp.isAfter(_newestKnownTimestamp!)) {
            _newIds.add(identityId);
          }
        }
      }
      _newCount = _newIds.length;
    }
    if (items.isNotEmpty) {
      _newestKnownTimestamp = items.first.timestamp;
    }
    _knownIds = currentIds;

    return ActivityListWithToast(
      newCount: _newCount,
      icon: Icons.person_rounded,
      labelKey: 'identities',
      child: ListView.separated(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
        itemBuilder: (context, index) {
          final identity = items[index];
          final identityId = '${identity.accountId ?? identity.name}_${identity.timestamp.millisecondsSinceEpoch}';
          final isNew = _newIds.contains(identityId);
          final child = widget.tileBuilder(context, identity);
          return isNew ? NewItemHighlight(child: child) : child;
        },
      ),
    );
  }
}

class DesktopCertificationsTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Widget Function(BuildContext, CertificationDisplayItem) tileBuilder;

  const DesktopCertificationsTab({super.key, required this.scrollController, required this.tileBuilder});

  @override
  ConsumerState<DesktopCertificationsTab> createState() => _DesktopCertificationsTabState();
}

class _DesktopCertificationsTabState extends ConsumerState<DesktopCertificationsTab> {
  Set<String> _knownIds = {};
  Set<String> _newIds = {};
  int _newCount = 0;
  DateTime? _newestKnownTimestamp;

  @override
  Widget build(BuildContext context) {
    final certsState = ref.watch(adaptiveFilteredNetworkCertificationsProvider);
    final items = certsState.items;

    if (items.isEmpty) {
      final hasFilters = ref.watch(certificationFiltersProvider).hasActiveFilters;
      return buildEmptyTabState(
        context,
        Icons.verified_outlined,
        hasFilters ? 'noResultsForFilter'.tr() : 'noCertificationActivity'.tr(),
      );
    }

    final currentIds = items.map((c) => c.id).toSet();
    if (_knownIds.isNotEmpty) {
      final newItems = currentIds.difference(_knownIds);
      _newIds = {};
      if (newItems.isNotEmpty && _newestKnownTimestamp != null) {
        for (final cert in items) {
          if (newItems.contains(cert.id) && cert.timestamp.isAfter(_newestKnownTimestamp!)) {
            _newIds.add(cert.id);
          }
        }
      }
      _newCount = _newIds.length;
    }
    if (items.isNotEmpty) {
      _newestKnownTimestamp = items.first.timestamp;
    }
    _knownIds = currentIds;

    return ActivityListWithToast(
      newCount: _newCount,
      icon: Icons.verified_rounded,
      labelKey: 'certifications',
      child: ListView.separated(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: context.colorScheme.outline.withValues(alpha: 0.06)),
        itemBuilder: (context, index) {
          final cert = items[index];
          final isNew = _newIds.contains(cert.id);
          final child = widget.tileBuilder(context, cert);
          return isNew ? NewItemHighlight(child: child) : child;
        },
      ),
    );
  }
}

// ─── Shared animation widgets ───

/// Wraps a list with a slide-up toast notification when new items arrive.
class ActivityListWithToast extends StatefulWidget {
  final int newCount;
  final IconData icon;
  final String labelKey;
  final Widget child;

  const ActivityListWithToast({
    super.key,
    required this.newCount,
    required this.icon,
    required this.labelKey,
    required this.child,
  });

  @override
  State<ActivityListWithToast> createState() => _ActivityListWithToastState();
}

class _ActivityListWithToastState extends State<ActivityListWithToast> with SingleTickerProviderStateMixin {
  late AnimationController _toastController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _displayedCount = 0;

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _toastController, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _toastController, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(ActivityListWithToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.newCount > 0 && widget.newCount != oldWidget.newCount) {
      _displayedCount = widget.newCount;
      _toastController.forward(from: 0);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _toastController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _toastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Toast notification -- anchored at bottom center
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.inverseSurface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 14, color: context.colorScheme.inversePrimary),
                      const SizedBox(width: 6),
                      Text(
                        '+$_displayedCount',
                        style: scaledTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.colorScheme.onInverseSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.labelKey.tr(),
                        style: scaledTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.colorScheme.onInverseSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Subtle highlight animation for newly arrived items -- fades from accent background to transparent.
class NewItemHighlight extends StatefulWidget {
  final Widget child;
  const NewItemHighlight({super.key, required this.child});

  @override
  State<NewItemHighlight> createState() => _NewItemHighlightState();
}

class _NewItemHighlightState extends State<NewItemHighlight> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _highlightAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: _highlightAnimation.value * 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
