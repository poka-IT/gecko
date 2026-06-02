import 'package:durt2/durt2.dart' show Durt, WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/providers/cert_alert_provider.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';

/// Desktop contacts panel for the left column of the home layout.
/// Shows all contacts with search, sorted by custom order or resolved name.
class DesktopContactsPanel extends ConsumerStatefulWidget {
  final void Function(String address, String? username) onContactTap;

  const DesktopContactsPanel({super.key, required this.onContactTap});

  @override
  ConsumerState<DesktopContactsPanel> createState() => _DesktopContactsPanelState();
}

class _DesktopContactsPanelState extends ConsumerState<DesktopContactsPanel> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<String> _getSavedOrder() {
    return ref.read(configServiceProvider).contactOrder;
  }

  void _saveOrder(List<String> order) {
    ref.read(configServiceProvider).contactOrder = order;
  }

  List<G1WalletsList> _getOrderedContacts(List<G1WalletsList> allContacts) {
    final squidService = ref.watch(squidServiceProvider);
    final savedOrder = _getSavedOrder();

    // Sort: saved order first, then alphabetically by name for new contacts
    final ordered = List<G1WalletsList>.from(allContacts);
    ordered.sort((a, b) {
      final indexA = savedOrder.indexOf(a.address);
      final indexB = savedOrder.indexOf(b.address);
      // Both have saved positions
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      // Only one has saved position - it comes first
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      // Neither has saved position - sort by name
      final name1 = squidService.walletNameIndexer[a.address] ?? a.username;
      final name2 = squidService.walletNameIndexer[b.address] ?? b.username;
      final has1 = name1 != null && name1.isNotEmpty;
      final has2 = name2 != null && name2.isNotEmpty;
      if (has1 && has2) return name1.toLowerCase().compareTo(name2.toLowerCase());
      if (has1) return -1;
      if (has2) return 1;
      return a.address.compareTo(b.address);
    });

    return ordered;
  }

  List<G1WalletsList> _filterContacts(List<G1WalletsList> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    final squidService = ref.watch(squidServiceProvider);
    final query = _searchQuery.toLowerCase();
    return contacts.where((contact) {
      final resolvedName = squidService.walletNameIndexer[contact.address];
      final displayName = resolvedName ?? contact.username ?? '';
      return displayName.toLowerCase().contains(query) || contact.address.toLowerCase().contains(query);
    }).toList();
  }

  void _onReorder(int oldIndex, int newIndex, List<G1WalletsList> orderedContacts) {
    // `newIndex` already accounts for the removed item (onReorderItem semantics).
    final item = orderedContacts.removeAt(oldIndex);
    orderedContacts.insert(newIndex, item);
    _saveOrder(orderedContacts.map((c) => c.address).toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // contactsBox may not be initialized yet during app startup
    final List<G1WalletsList> allContacts;
    try {
      allContacts = ref.watch(allContactsProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final orderedContacts = _getOrderedContacts(allContacts);
    final contacts = _filterContacts(orderedContacts);
    final allCount = allContacts.length;
    final isSearching = _searchQuery.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
          child: Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: scaleSize(16),
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'contactsManagement'.tr(),
                style: scaledTextStyle(
                  fontSize: 14,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (allCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$allCount',
                    style: scaledTextStyle(
                      fontSize: 11,
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Search field
        if (allCount > 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'searchContacts'.tr(),
                hintStyle: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search, size: 18, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
                filled: true,
                fillColor: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
        // Contacts list
        Expanded(
          child: contacts.isEmpty
              ? _buildEmptyState(context, allCount == 0)
              : isSearching
              // When searching, use simple list (reorder doesn't make sense during search)
              ? ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildContactTile(context, contacts[index], showDragHandle: false),
                  ),
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Material(
                        color: Colors.transparent,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(14),
                        child: child,
                      ),
                      child: child,
                    );
                  },
                  itemCount: contacts.length,
                  onReorderItem: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, contacts),
                  itemBuilder: (context, index) => Padding(
                    key: ValueKey(contacts[index].address),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildContactTile(context, contacts[index], reorderIndex: index),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool noContactsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: scaleSize(36),
              color: context.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              noContactsAtAll ? 'noContacts'.tr() : 'noSearchResults'.tr(),
              textAlign: TextAlign.center,
              style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    G1WalletsList contact, {
    int? reorderIndex,
    bool showDragHandle = true,
  }) {
    final wallet = WalletEntity.create(
      address: contact.address,
      name: contact.username,
      keyPairType: Durt.defaultKeyPairType,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onContactTap(contact.address, contact.username),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: scaleSize(32),
                height: scaleSize(32),
                child: ClipOval(
                  child: DatapodAvatar(address: contact.address, size: 32, name: contact.username),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NameByAddress(
                      wallet: wallet,
                      size: 12,
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      showCesiumPlusName: true,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      getShortPubkey(contact.address),
                      style: scaledTextStyle(
                        fontSize: 9.5,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontFamily: 'Monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Builder(
                builder: (context) {
                  final alertStatus = ref.watch(contactCertAlertProvider(contact.address));
                  if (alertStatus == CertAlertStatus.none) return const SizedBox.shrink();
                  final color = alertStatus == CertAlertStatus.expired
                      ? context.geckoColors.danger
                      : context.geckoColors.warning;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: scaleSize(7),
                      height: scaleSize(7),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                  );
                },
              ),
              Balance(address: contact.address, size: 11, color: context.colorScheme.onSurface),
              if (showDragHandle && reorderIndex != null) ...[
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: reorderIndex,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 18,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.24),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
