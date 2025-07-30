import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/contacts_list.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String searchQuery = '';
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the contacts provider for reactive updates
    final allContacts = ref.watch(allContactsProvider);
    final squidService = ref.watch(squidServiceProvider);

    // Filter contacts based on search query and ensure we have a mutable list
    final filteredContacts = searchQuery.isEmpty
        ? List<G1WalletsList>.from(allContacts) // Create a copy to allow sorting
        : allContacts.where((contact) {
            // Use resolved name from squid service for search
            final resolvedName = squidService.walletNameIndexer[contact.address];
            final displayName = resolvedName ?? contact.username ?? '';
            final username = displayName.toLowerCase();
            final address = contact.address.toLowerCase();
            final query = searchQuery.toLowerCase();
            return username.contains(query) || address.contains(query);
          }).toList();

    // Order contacts by resolved display name (same as what's shown in UI)
    // Contacts with names first, then contacts without names at the end
    filteredContacts.sort((p1, p2) {
      final resolvedName1 = squidService.walletNameIndexer[p1.address] ?? p1.username;
      final resolvedName2 = squidService.walletNameIndexer[p2.address] ?? p2.username;

      final hasName1 = resolvedName1 != null && resolvedName1.isNotEmpty;
      final hasName2 = resolvedName2 != null && resolvedName2.isNotEmpty;

      // If both have names, sort alphabetically
      if (hasName1 && hasName2) {
        return resolvedName1.toLowerCase().compareTo(resolvedName2.toLowerCase());
      }
      // If only p1 has a name, p1 comes first
      else if (hasName1 && !hasName2) {
        return -1;
      }
      // If only p2 has a name, p2 comes first
      else if (!hasName1 && hasName2) {
        return 1;
      }
      // If neither has a name, sort by address
      else {
        return p1.address.compareTo(p2.address);
      }
    });

    return GestureDetector(
      onTap: () {
        // Défocuser le champ de recherche quand on clique en dehors
        if (_searchFocus.hasFocus) {
          _searchFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('contactsManagementWithNbr'.tr(args: ['${allContacts.length}'])),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  focusNode: _searchFocus,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'searchContacts'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.colorScheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              Expanded(child: ContactsList(myContacts: filteredContacts)),
            ],
          ),
        ),
      ),
    );
  }
}
